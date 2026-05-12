import 'package:flutter_test/flutter_test.dart';
import 'package:autonomix/utils/glob_pattern.dart';

void main() {
  group('matchesGlobPattern', () {
    test('exact match', () {
      expect(matchesGlobPattern('app.deb', 'app.deb'), isTrue);
      expect(matchesGlobPattern('MyApp.tar.gz', 'MyApp.tar.gz'), isTrue);
    });

    test('wildcard at end', () {
      expect(matchesGlobPattern('app.deb', 'app*'), isTrue);
      expect(matchesGlobPattern('application.deb', 'app*'), isTrue);
      expect(matchesGlobPattern('app', 'app*'), isTrue);
    });

    test('wildcard at start', () {
      expect(matchesGlobPattern('app.deb', '*.deb'), isTrue);
      expect(matchesGlobPattern('MyApp.deb', '*.deb'), isTrue);
      expect(matchesGlobPattern('app.tar.gz', '*.tar.gz'), isTrue);
    });

    test('wildcard in middle', () {
      expect(matchesGlobPattern('app.deb', 'app*.deb'), isTrue);
      expect(matchesGlobPattern('application.deb', 'app*.deb'), isTrue);
      expect(matchesGlobPattern('app.deb', 'app.*'), isTrue);
    });

    test('multiple wildcards', () {
      expect(matchesGlobPattern('app.deb', '*.*'), isTrue);
      expect(matchesGlobPattern('MyApp.tar.gz', '*.*.*'), isTrue);
      expect(matchesGlobPattern('anything', '*'), isTrue);
    });

    test('question mark single char', () {
      expect(matchesGlobPattern('app1.deb', 'app?.deb'), isTrue);
      expect(matchesGlobPattern('appA.deb', 'app?.deb'), isTrue);
      expect(matchesGlobPattern('app.deb', 'app?.deb'), isFalse);
    });

    test('question mark multiple', () {
      expect(matchesGlobPattern('app12.deb', 'app??.deb'), isTrue);
      expect(matchesGlobPattern('app1.deb', 'app??.deb'), isFalse);
    });

    test('case insensitive', () {
      expect(matchesGlobPattern('APP.DEB', 'app.deb'), isTrue);
      expect(matchesGlobPattern('app.deb', 'APP.DEB'), isTrue);
      expect(matchesGlobPattern('App.Deb', 'app.deb'), isTrue);
    });

    test('empty pattern matches everything', () {
      expect(matchesGlobPattern('anything', ''), isTrue);
      expect(matchesGlobPattern('app.deb', ''), isTrue);
    });

    test('empty input handling', () {
      expect(matchesGlobPattern('', ''), isTrue);
      expect(matchesGlobPattern('', '*'), isTrue);
      expect(matchesGlobPattern('', 'app'), isFalse);
    });

    test('special characters in filename', () {
      expect(matchesGlobPattern('my-app_v1.0.deb', 'my-app_v*.deb'), isTrue);
      expect(matchesGlobPattern('app-name.deb', 'app-*.deb'), isTrue);
    });

    test('no match cases', () {
      expect(matchesGlobPattern('app.deb', 'other.deb'), isFalse);
      expect(matchesGlobPattern('app.deb', '*.rpm'), isFalse);
      expect(matchesGlobPattern('app.deb', 'app*.rpm'), isFalse);
    });
  });

  group('matchesArchitecture', () {
    test('amd64 detection', () {
      expect(matchesArchitecture('app-amd64.deb', 'amd64'), isTrue);
      expect(matchesArchitecture('app-x86_64.deb', 'x86_64'), isTrue);
      expect(matchesArchitecture('app-x64.deb', 'x64'), isTrue);
      expect(matchesArchitecture('app-64-bit.deb', '64-bit'), isTrue);
    });

    test('amd64 cross detection', () {
      expect(matchesArchitecture('app-x86_64.deb', 'amd64'), isTrue);
      expect(matchesArchitecture('app-amd64.deb', 'x86_64'), isTrue);
      expect(matchesArchitecture('app-x64.deb', 'amd64'), isTrue);
      expect(matchesArchitecture('app-64-bit.deb', 'amd64'), isTrue);
    });

    test('arm64 detection', () {
      expect(matchesArchitecture('app-arm64.deb', 'arm64'), isTrue);
      expect(matchesArchitecture('app-aarch64.deb', 'aarch64'), isTrue);
      expect(matchesArchitecture('app-armv8.deb', 'armv8'), isTrue);
    });

    test('arm64 cross detection', () {
      expect(matchesArchitecture('app-arm64.deb', 'aarch64'), isTrue);
      expect(matchesArchitecture('app-aarch64.deb', 'arm64'), isTrue);
    });

    test('arm detection', () {
      expect(matchesArchitecture('app-armhf.deb', 'armhf'), isTrue);
      expect(matchesArchitecture('app-armv7.deb', 'armv7'), isTrue);
      expect(matchesArchitecture('app-arm-.deb', 'arm'), isTrue);
    });

    test('i386 detection', () {
      expect(matchesArchitecture('app-i386.deb', 'i386'), isTrue);
      expect(matchesArchitecture('app-x86.deb', 'x86'), isTrue);
      expect(matchesArchitecture('app-32-bit.deb', '32-bit'), isTrue);
    });

    test('i386 cross detection', () {
      expect(matchesArchitecture('app-i386.deb', 'x86'), isTrue);
      expect(matchesArchitecture('app-x86.deb', 'i386'), isTrue);
    });

    test('case insensitive', () {
      expect(matchesArchitecture('app-AMD64.deb', 'amd64'), isTrue);
      expect(matchesArchitecture('app-ARM64.deb', 'arm64'), isTrue);
      expect(matchesArchitecture('app-Amd64.deb', 'amd64'), isTrue);
    });

    test('custom architecture string', () {
      expect(matchesArchitecture('app-linux-musl-x64.deb', 'musl'), isTrue);
      expect(matchesArchitecture('app-freebsd.deb', 'freebsd'), isTrue);
    });

    test('no match', () {
      expect(matchesArchitecture('app-amd64.deb', 'arm64'), isFalse);
      expect(matchesArchitecture('app-arm64.deb', 'amd64'), isFalse);
      expect(matchesArchitecture('app.deb', 'amd64'), isFalse);
    });
  });

  group('findMatchingArchitectures', () {
    test('finds matching architectures', () {
      final result = findMatchingArchitectures(
        'app-amd64-arm64.deb',
        ['amd64', 'arm64', 'armhf'],
      );
      expect(result, contains('amd64'));
      expect(result, contains('arm64'));
      expect(result.length, equals(2));
    });

    test('returns empty for no matches', () {
      final result = findMatchingArchitectures(
        'app.deb',
        ['amd64', 'arm64'],
      );
      expect(result, isEmpty);
    });

    test('returns all matching', () {
      final result = findMatchingArchitectures(
        'app-amd64-x86_64.deb',
        ['amd64', 'x86_64', 'arm64'],
      );
      expect(result, contains('amd64'));
      expect(result, contains('x86_64'));
      expect(result.length, equals(2));
    });
  });

  group('Release Filtering logic', () {
    test('tag prefix filtering', () {
      // Logic from GitHubService: lowerTag.contains(searchPrefix)
      bool matchesTag(String tagName, String prefix) {
        if (prefix.trim().isEmpty) return true;
        return tagName.toLowerCase().contains(prefix.trim().toLowerCase());
      }

      expect(matchesTag('v1.0.0', 'v'), isTrue);
      expect(matchesTag('v1.0.0', '1.0'), isTrue);
      expect(matchesTag('v1.0.0', 'V'), isTrue);
      expect(matchesTag('v1.0.0', '2.0'), isFalse);
      expect(matchesTag('app-v1.0.0', 'v1'), isTrue);
    });

    test('prerelease filtering', () {
      bool shouldInclude(bool isPrerelease, bool includePrerelease) {
        if (!includePrerelease && isPrerelease) return false;
        return true;
      }

      expect(shouldInclude(true, false), isFalse);
      expect(shouldInclude(true, true), isTrue);
      expect(shouldInclude(false, false), isTrue);
      expect(shouldInclude(false, true), isTrue);
    });
  });
}
