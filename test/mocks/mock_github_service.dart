import 'package:autonomix/services/github_service.dart';
import 'package:autonomix/services/settings_service.dart';
import 'package:autonomix/models/release.dart';

class MockGitHubService extends GitHubService {
  List<Release> _releases = [];
  bool shouldFail = false;
  String? failureMessage;

  MockGitHubService() : super(settingsService: SettingsService());

  void setReleases(List<Release> releases) {
    _releases = releases;
  }

  void setShouldFail(bool fail, {String? message}) {
    shouldFail = fail;
    failureMessage = message;
  }

  @override
  Future<Release?> getLatestRelease(
    String owner,
    String repo, {
    String? assetFilterPattern,
    String? tagPrefix,
    List<String>? architectures,
    bool includePrerelease = false,
  }) async {
    if (shouldFail) {
      throw Exception(failureMessage ?? 'Simulated GitHub error');
    }

    if (_releases.isEmpty) {
      return null;
    }

    // Apply filtering logic similar to real implementation
    final filteredReleases = _releases.where((release) {
      if (!includePrerelease && release.prerelease) {
        return false;
      }
      if (tagPrefix != null && tagPrefix.isNotEmpty) {
        if (!release.tagName.startsWith(tagPrefix)) {
          return false;
        }
      }
      return true;
    }).toList();

    for (var release in filteredReleases) {
      final filteredAssets = filterAssets(
        release,
        assetFilterPattern: assetFilterPattern,
        architectures: architectures,
      );

      if (filteredAssets.isNotEmpty) {
        return release.copyWith(assets: filteredAssets);
      }
    }

    return null;
  }

  @override
  Future<List<Release>> getReleases(String owner, String repo) async {
    if (shouldFail) {
      throw Exception(failureMessage ?? 'Simulated GitHub error');
    }
    return _releases;
  }
}
