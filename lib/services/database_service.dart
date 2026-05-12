import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/tracked_app.dart';
import '../models/app_config.dart';
import '../models/tracked_deb_package.dart';

class DatabaseService {
  File? _file;
  File? _debFile;

  DatabaseService();

  Future<File> get _dbFile async {
    if (_file != null) return _file!;
    final configDir = await getApplicationSupportDirectory();
    await Directory(configDir.path).create(recursive: true);
    _file = File(join(configDir.path, 'apps.json'));
    return _file!;
  }

  Future<File> get _debDbFile async {
    if (_debFile != null) return _debFile!;
    final configDir = await getApplicationSupportDirectory();
    await Directory(configDir.path).create(recursive: true);
    _debFile = File(join(configDir.path, 'deb_packages.json'));
    return _debFile!;
  }

  Future<List<TrackedApp>> getAllApps() async {
    final file = await _dbFile;
    if (!await file.exists()) return [];

    try {
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((e) => TrackedApp.fromMap(e)).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
    } catch (e) {
      print('Error reading DB: $e');
      return [];
    }
  }

  Future<void> _saveApps(List<TrackedApp> apps) async {
    final file = await _dbFile;
    final jsonList = apps.map((e) => e.toMap()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  Future<int> addApp(
    String repoOwner,
    String repoName,
    String displayName, {
    String? assetFilterPattern,
    String? tagPrefix,
    List<String> architectures = const [],
    bool includePrerelease = false,
    String? launchCommand,
    String? packageName,
  }) async {
    final apps = await getAllApps();

    if (apps.any((a) => a.repoOwner == repoOwner && a.repoName == repoName)) {
      throw Exception('App already exists');
    }

    final id = (apps.isEmpty ? 0 : apps.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b)) + 1;

    final newApp = TrackedApp(
      id: id,
      repoOwner: repoOwner,
      repoName: repoName,
      displayName: displayName,
      createdAt: DateTime.now(),
      assetFilterPattern: assetFilterPattern,
      tagPrefix: tagPrefix,
      architectures: architectures,
      includePrerelease: includePrerelease,
      launchCommand: launchCommand,
      packageName: packageName,
    );

    apps.add(newApp);
    await _saveApps(apps);
    return id;
  }

Future<void> updateApp(TrackedApp app) async {
  final apps = await getAllApps();
  final index = apps.indexWhere((a) => a.id == app.id);

  if (index == -1) {
    throw Exception('App with id ${app.id} not found in database');
  }

  apps[index] = app;
  await _saveApps(apps);
}

  Future<void> deleteApp(int id) async {
    final apps = await getAllApps();
    apps.removeWhere((a) => a.id == id);
    await _saveApps(apps);
  }

  Future<String> exportConfig() async {
    try {
      final apps = await getAllApps();
      final appData = apps.map((app) => TrackedAppData(
        repoOwner: app.repoOwner,
        repoName: app.repoName,
        displayName: app.displayName,
        assetFilterPattern: app.assetFilterPattern,
        tagPrefix: app.tagPrefix,
        architectures: app.architectures,
        includePrerelease: app.includePrerelease,
      )).toList();

      final config = AppConfig(
        schemaVersion: '1.0',
        exportedAt: DateTime.now(),
        appName: 'Autonomix',
        appVersion: '0.3.4',
        apps: appData,
      );

      final configDir = await getApplicationSupportDirectory();
      final exportFile = File('${configDir.path}/autonomix-export-${DateTime.now().toIso8601String().split('T').first}.json');
      await exportFile.writeAsString(jsonEncode(config.toJson()));
      
      return exportFile.path;
    } catch (e) {
      throw Exception('Failed to export config: $e');
    }
  }

  Future<int> importConfig(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final content = await file.readAsString();
      final config = AppConfig.fromJson(jsonDecode(content) as Map<String, dynamic>);

      final existingApps = await getAllApps();
      int importCount = 0;

      for (final appData in config.apps) {
        if (!existingApps.any((a) =>
            a.repoOwner == appData.repoOwner && a.repoName == appData.repoName)) {
          final newApp = appData.toTrackedApp(
            (existingApps.isEmpty ? 0 : existingApps.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b)) + 1 + importCount,
          );
          existingApps.add(newApp);
          importCount++;
        }
      }

      if (importCount > 0) {
        await _saveApps(existingApps);
      }

      return importCount;
    } catch (e) {
      throw Exception('Failed to import config: $e');
    }
  }

  // Deb Package Methods
  Future<List<TrackedDebPackage>> getAllDebPackages() async {
    final file = await _debDbFile;
    if (!await file.exists()) return [];

    try {
      final content = await file.readAsString();
      if (content.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((e) => TrackedDebPackage.fromMap(e)).toList();
    } catch (e) {
      print('Error reading deb packages DB: $e');
      return [];
    }
  }

  Future<void> _saveDebPackages(List<TrackedDebPackage> packages) async {
    final file = await _debDbFile;
    final jsonList = packages.map((e) => e.toMap()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  Future<int> addDebPackage({
    required String name,
    required String packageUrl,
    String? displayName,
    bool autoUpdate = false,
  }) async {
    final packages = await getAllDebPackages();

    if (packages.any((p) => p.packageUrl == packageUrl)) {
      throw Exception('Package URL already exists');
    }

    final id = (packages.isEmpty ? 0 : packages.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b)) + 1;

    final newPackage = TrackedDebPackage(
      id: id,
      name: name,
      packageUrl: packageUrl,
      displayName: displayName ?? name,
      createdAt: DateTime.now(),
      autoUpdate: autoUpdate,
    );

    packages.add(newPackage);
    await _saveDebPackages(packages);
    return id;
  }

  Future<void> updateDebPackage(TrackedDebPackage pkg) async {
    final packages = await getAllDebPackages();
    final index = packages.indexWhere((p) => p.id == pkg.id);

    if (index == -1) {
      throw Exception('Package with id ${pkg.id} not found');
    }

    packages[index] = pkg;
    await _saveDebPackages(packages);
  }

  Future<void> deleteDebPackage(int id) async {
    final packages = await getAllDebPackages();
    packages.removeWhere((p) => p.id == id);
    await _saveDebPackages(packages);
  }

  /// Check for updates on all tracked deb packages
  Future<Map<String, String>> checkDebPackageUpdates() async {
    final packages = await getAllDebPackages();
    final updates = <String, String>{};

    for (final pkg in packages) {
      try {
        final latestVersion = await _fetchDebVersion(pkg.packageUrl);
        if (latestVersion != null) {
          await updateDebPackage(pkg.copyWith(
            latestVersion: latestVersion,
            lastChecked: DateTime.now(),
          ));
          if (pkg.installedVersion != null && pkg.installedVersion != latestVersion) {
            updates[pkg.name] = latestVersion;
          }
        }
      } catch (e) {
        print('Error checking updates for ${pkg.name}: $e');
      }
    }

    return updates;
  }

  /// Fetch version from deb package URL (HEAD request to get file info)
  Future<String?> _fetchDebVersion(String url) async {
    try {
      final uri = Uri.parse(url);
      final filename = uri.path.split('/').last;
      return TrackedDebPackage.extractVersionFromFilename(filename);
    } catch (e) {
      return null;
    }
  }
}
