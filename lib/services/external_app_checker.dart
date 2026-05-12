import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../models/tracked_app.dart';
import 'debug_logger.dart';

class ExternalAppChecker {
  static final RegExp _versionRegExp = RegExp(
    r'(?:v|version\s+)?(\d+\.\d+(?:\.\d+)?(?:-[a-zA-Z0-9\.\-]+)?)',
    caseSensitive: false,
  );

  /// Checks if the application is installed externally and attempts to find its version.
  static Future<String?> getExternalVersion(TrackedApp app) async {
    final guesses = _generateNameGuesses(app);
    dlog('ExternalAppChecker', 'Checking ${app.repoName} (id: ${app.id}) with guesses: $guesses');

    for (final name in guesses) {
      // 1. Try dpkg-query first (useful for deb packages)
      try {
        final dpkgRes = await Process.run('/usr/bin/dpkg-query', ['-W', r"--showformat=${Version}", name])
            .timeout(const Duration(seconds: 2));
        if (dpkgRes.exitCode == 0) {
          final out = dpkgRes.stdout.toString().trim();
          dlog('ExternalAppChecker', 'dpkg-query found match for $name: $out');
          if (out.isNotEmpty) {
            final ver = extractVersion(out);
            if (ver != null) {
              dlog('ExternalAppChecker', 'Extracted version from dpkg for $name: $ver');
              return ver;
            }
          }
        } else {
          // If exact match fails, try wildcard (but only for names that look like they could be partial)
          if (name.length >= 4) {
            final dpkgWildRes = await Process.run('/usr/bin/dpkg-query', ['-W', r"--showformat=${Package}|${Version}\n", '*$name*'])
                .timeout(const Duration(seconds: 2));
            if (dpkgWildRes.exitCode == 0) {
              final lines = dpkgWildRes.stdout.toString().trim().split('\n');
              for (final line in lines) {
                final parts = line.split('|');
                if (parts.length == 2) {
                  dlog('ExternalAppChecker', 'dpkg wildcard match: ${parts[0]} -> ${parts[1]}');
                  // If we find multiple, we just take the first one that looks reasonable
                  final ver = extractVersion(parts[1]);
                  if (ver != null) {
                    dlog('ExternalAppChecker', 'Extracted version from dpkg wildcard for $name: $ver');
                    return ver;
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        dlog('ExternalAppChecker', 'Error in dpkg-query for $name: $e');
      }

      // 2. Try which (useful for binaries in PATH)
      try {
        final whichRes = await Process.run('/usr/bin/which', [name])
            .timeout(const Duration(seconds: 1));
        if (whichRes.exitCode == 0) {
          final path = whichRes.stdout.toString().trim();
          dlog('ExternalAppChecker', 'which found binary for $name at $path');
          if (path.isNotEmpty) {
            final ver = await _runWithTimeout(path, ['--version']);
            if (ver != null) {
              dlog('ExternalAppChecker', 'Extracted version via --version for $name: $ver');
              return ver;
            }
            
            // Try -v if --version failed
            final verShort = await _runWithTimeout(path, ['-v']);
            if (verShort != null) {
              dlog('ExternalAppChecker', 'Extracted version via -v for $name: $verShort');
              return verShort;
            }
          }
        }
      } catch (e) {
        dlog('ExternalAppChecker', 'Error in which/run for $name: $e');
      }
    }
    
    dlog('ExternalAppChecker', 'No version found for ${app.repoName}');
    return null;
  }

  static List<String> _generateNameGuesses(TrackedApp app) {
    final guesses = <String>{};

    // 1. Explicit package name or launch command
    if (app.packageName != null && app.packageName!.isNotEmpty) {
      guesses.add(app.packageName!);
    }
    if (app.launchCommand != null && app.launchCommand!.isNotEmpty) {
      // If it's a full path, get the basename
      guesses.add(app.launchCommand!.split('/').last);
      // Also try the whole command if it's just a name
      if (!app.launchCommand!.contains('/')) {
        guesses.add(app.launchCommand!);
      }
    }

    // 2. Repo name and variations
    final repoLower = app.repoName.toLowerCase();
    guesses.add(repoLower);
    
    // 3. Repo owner (often the package name for multi-repo projects)
    final ownerLower = app.repoOwner.toLowerCase();
    guesses.add(ownerLower);
    guesses.add('$ownerLower.io');

    // Strip common suffixes like -go, -rust, -desktop
    final cleanRepo = repoLower
        .replaceAll(RegExp(r'-(?:go|rust|desktop|linux|app|cli|gui|client|server|bin|bundle)$'), '')
        .replaceAll(RegExp(r'\.(?:go|rust|desktop|linux|app|cli|gui|client|server|bin|bundle)$'), '');
    if (cleanRepo != repoLower) {
      guesses.add(cleanRepo);
    }
    
    // Also try adding .io (common for modern apps)
    guesses.add('$cleanRepo.io');

    // 4. Extract name from fetched package filename
    if (app.fetchedPackage != null && app.fetchedPackage!.isNotEmpty) {
      final fileName = app.fetchedPackage!.split('/').last;
      // Extract everything before first version-like part or first -/_
      final namePart = fileName.split(RegExp(r'[-_1-9]'))[0].toLowerCase();
      if (namePart.length > 1) {
        guesses.add(namePart);
        guesses.add('$namePart.io');
      }
      
      final firstSegment = fileName.split(RegExp(r'[-_]'))[0].toLowerCase();
      if (firstSegment.length > 1) {
        guesses.add(firstSegment);
      }
    }

    // 5. Display name variations (first word)
    final displayFirst = app.displayName
        .split(' ')[0]
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (displayFirst.length > 2) {
      guesses.add(displayFirst);
      guesses.add('$displayFirst.io');
    }

    return guesses.toList();
  }

  static Future<String?> _runWithTimeout(String cmd, List<String> args) async {
    try {
      final process = await Process.start(cmd, args);
      final output = StringBuffer();
      
      // Safety timer to kill process if it hangs (e.g. GUI launches)
      final timer = Timer(const Duration(seconds: 2), () {
        process.kill();
      });

      // Collect stdout
      final stdoutFuture = process.stdout.transform(utf8.decoder).listen((data) {
        output.write(data);
      }).asFuture();
      
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 5), // Increased timeout for slow Electron apps
        onTimeout: () {
          process.kill();
          return -1;
        },
      );
      
      timer.cancel();
      // Ensure we don't leak resources
      await stdoutFuture.catchError((_) => null);

      if (exitCode == 0) {
        return extractVersion(output.toString());
      }
    } catch (_) {}
    return null;
  }

  static String? extractVersion(String output) {
    final trimmed = output.trim();
    if (trimmed.isEmpty) return null;
    
    // Use regex to find the version string
    final match = _versionRegExp.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      final ver = match.group(1);
      if (ver != null && ver.isNotEmpty) return ver;
    }
    
    // Fallback 1: If output is very short and looks like a version (digits and dots)
    if (trimmed.length < 30) {
      // Remove 'v' or 'V' prefix
      var v = trimmed;
      if (v.toLowerCase().startsWith('v')) {
        v = v.substring(1).trim();
      }
      
      // If it looks like a version (starts with digit, contains dots or hyphens)
      if (RegExp(r'^[0-9]').hasMatch(v) && 
          (v.contains('.') || v.contains('-') || v.length < 10)) {
        return v;
      }
    }
    
    return null;
  }
}
