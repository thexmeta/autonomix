import 'package:flutter_test/flutter_test.dart';
import 'package:autonomix/services/github_service.dart';
import 'package:autonomix/models/release.dart';

void main() {
  group('GitHubService filterAssets', () {
    late GitHubService service;

    setUp(() {
      service = GitHubService();
    });

    Release createRelease({
      String tagName = 'v1.0.0',
      List<ReleaseAsset>? assets,
      bool prerelease = false,
    }) {
      return Release(
        tagName: tagName,
        name: 'Test Release',
        body: null,
        publishedAt: DateTime.now(),
        prerelease: prerelease,
        draft: false,
        assets: assets ?? [],
      );
    }

    ReleaseAsset createAsset({
      required String name,
      String contentType = 'application/octet-stream',
      int size = 1000,
    }) {
      return ReleaseAsset(
        name: name,
        browserDownloadUrl: 'https://example.com/$name',
        contentType: contentType,
        size: size,
      );
    }

    test('returns all assets when no filters', () {
      final assets = [
        createAsset(name: 'app-amd64.deb'),
        createAsset(name: 'app-arm64.deb'),
        createAsset(name: 'app.tar.gz'),
      ];
      final release = createRelease(assets: assets);

      final result = service.filterAssets(release);

      expect(result.length, equals(3));
    });

    test('filters by asset pattern', () {
      final assets = [
        createAsset(name: 'app-amd64.deb'),
        createAsset(name: 'app-arm64.deb'),
        createAsset(name: 'app.tar.gz'),
      ];
      final release = createRelease(assets: assets);

      final result = service.filterAssets(release, assetFilterPattern: '*.deb');

      expect(result.length, equals(2));
      expect(result.every((a) => a.name.endsWith('.deb')), isTrue);
    });

    test('filters by architecture', () {
      final assets = [
        createAsset(name: 'app-amd64.deb'),
        createAsset(name: 'app-arm64.deb'),
        createAsset(name: 'app-armhf.deb'),
      ];
      final release = createRelease(assets: assets);

      final result = service.filterAssets(release, architectures: ['amd64']);

      expect(result.length, equals(1));
      expect(result.first.name, contains('amd64'));
    });

    test('filters by multiple architectures', () {
      final assets = [
        createAsset(name: 'app-amd64.deb'),
        createAsset(name: 'app-arm64.deb'),
        createAsset(name: 'app-armhf.deb'),
      ];
      final release = createRelease(assets: assets);

      final result = service.filterAssets(
        release,
        architectures: ['amd64', 'arm64'],
      );

      expect(result.length, equals(2));
    });

    test('filters by both pattern and architecture', () {
      final assets = [
        createAsset(name: 'app-amd64.deb'),
        createAsset(name: 'app-amd64.tar.gz'),
        createAsset(name: 'app-arm64.deb'),
      ];
      final release = createRelease(assets: assets);

      final result = service.filterAssets(
        release,
        assetFilterPattern: '*.deb',
        architectures: ['amd64'],
      );

      expect(result.length, equals(1));
      expect(result.first.name, equals('app-amd64.deb'));
    });

    test('returns empty list when no matches', () {
      final assets = [
        createAsset(name: 'app-amd64.deb'),
        createAsset(name: 'app-arm64.deb'),
      ];
      final release = createRelease(assets: assets);

      final result = service.filterAssets(
        release,
        assetFilterPattern: '*.rpm',
      );

      expect(result, isEmpty);
    });

    test('handles cross-architecture detection', () {
      final assets = [
        createAsset(name: 'app-x86_64.deb'),
        createAsset(name: 'app-x64.deb'),
        createAsset(name: 'app-64-bit.deb'),
      ];
      final release = createRelease(assets: assets);

      final result = service.filterAssets(
        release,
        architectures: ['amd64'],
      );

      expect(result.length, equals(3));
    });

    test('handles empty asset list', () {
      final release = createRelease(assets: []);

      final result = service.filterAssets(release);

      expect(result, isEmpty);
    });
  });

  group('GitHubService getLatestRelease with filters', () {
    test('filters releases by tag prefix', () {
      final service = GitHubService();
      // This would require mocking the HTTP calls
      // Marked for future implementation with mock setup
    });

    test('handles prerelease filtering', () {
      final service = GitHubService();
      // This would require mocking the HTTP calls
      // Marked for future implementation with mock setup
    });
  });
}
