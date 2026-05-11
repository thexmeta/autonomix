import 'package:flutter_test/flutter_test.dart';
import 'package:autonomix/models/tracked_app.dart';

void main() {
  group('TrackedApp version comparison', () {
    test('hasUpdate returns true when latest is newer', () {
      final app = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: '1.0.0',
        latestVersion: '1.0.1',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app.hasUpdate, isTrue);
    });

    test('hasUpdate returns false when versions are equal', () {
      final app = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: '1.0.0',
        latestVersion: '1.0.0',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app.hasUpdate, isFalse);
    });

    test('hasUpdate returns false when installed is newer', () {
      final app = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: '1.0.1',
        latestVersion: '1.0.0',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app.hasUpdate, isFalse);
    });

    test('handles v-prefix in versions', () {
      final app = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: 'v1.0.0',
        latestVersion: 'v1.0.1',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app.hasUpdate, isTrue);
    });

    test('handles mixed v-prefix', () {
      final app1 = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: 'v1.0.0',
        latestVersion: '1.0.1',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app1.hasUpdate, isTrue);

      final app2 = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: '1.0.0',
        latestVersion: 'v1.0.1',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app2.hasUpdate, isTrue);
    });

    test('hasUpdate returns false if installedVersion is null', () {
      final app = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: null,
        latestVersion: '1.0.0',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app.hasUpdate, isFalse);
    });

    test('hasUpdate returns false if latestVersion is null', () {
      final app = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: '1.0.0',
        latestVersion: null,
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app.hasUpdate, isFalse);
    });

    test('major version comparison', () {
      final app = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: '1.0.0',
        latestVersion: '2.0.0',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app.hasUpdate, isTrue);
    });

    test('minor version comparison', () {
      final app = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: '1.0.0',
        latestVersion: '1.1.0',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app.hasUpdate, isTrue);
    });

    test('patch version comparison', () {
      final app = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: '1.0.0',
        latestVersion: '1.0.1',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app.hasUpdate, isTrue);
    });

    test('handles V-prefix uppercase', () {
      final app = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: 'V1.0.0',
        latestVersion: 'V1.0.1',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app.hasUpdate, isTrue);
    });

    test('handles prerelease versions', () {
      final app = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: '1.0.0-alpha',
        latestVersion: '1.0.0',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      // Note: Current implementation uses string comparison
      // This test documents current behavior
      expect(app.hasUpdate, isTrue);
    });
  });

  group('TrackedApp isInstalled', () {
    test('returns true when installedVersion is not null', () {
      final app = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: '1.0.0',
        latestVersion: '1.0.0',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app.isInstalled, isTrue);
    });

    test('returns false when installedVersion is null', () {
      final app = TrackedApp(
        repoOwner: 'owner',
        repoName: 'repo',
        displayName: 'Test App',
        installedVersion: null,
        latestVersion: '1.0.0',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      expect(app.isInstalled, isFalse);
    });
  });
}
