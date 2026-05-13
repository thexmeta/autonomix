import 'package:autonomix/services/settings_service.dart';
import 'package:autonomix/services/theme_service.dart';
import 'package:autonomix/models/tracked_app.dart';
import 'package:autonomix/services/database_service.dart';
import 'package:autonomix/services/github_service.dart';
import 'package:autonomix/models/tracked_deb_package.dart';

class MockSettingsService extends SettingsService {
  @override
  Future<String?> getGithubToken() async => null;
  
  @override
  Future<int> getEffectiveReleasesPerPage() async => 100;

  @override
  Future<String?> getTheme() async => 'system';

  @override
  Future<void> setTheme(String? theme) async {}
  
  @override
  Future<bool> isDebugLoggingEnabled() async => false;

  @override
  Future<String?> getDefaultArchitecture() async => 'amd64';

  @override
  Future<void> setDefaultArchitecture(String? arch) async {}

  @override
  Future<String> getEffectiveDefaultArchitecture() async => 'amd64';

  @override
  Future<Map<String, dynamic>> _loadSettings() async => {};

  @override
  Future<void> _saveSettings(Map<String, dynamic> settings) async {}
}

class MockDatabaseService extends DatabaseService {
  @override
  Future<List<TrackedApp>> getAllApps() async => [];

  @override
  Future<List<TrackedDebPackage>> getAllDebPackages() async => [];

  @override
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
  }) async => 1;

  @override
  Future<void> updateApp(TrackedApp app) async {}

  @override
  Future<void> deleteApp(int id) async {}

  @override
  Future<Map<String, String>> checkDebPackageUpdates() async => {};
}

class MockGitHubService extends GitHubService {
  @override
  Future<Map<String, dynamic>> getRepository(String owner, String repo) async {
    return {
      'name': repo,
      'owner': {'login': owner},
      'description': 'Mock Description',
    };
  }

  @override
  Future<Map<String, dynamic>?> getLatestReleaseWithPackageInfo(
    String owner,
    String repo, {
    String? assetFilterPattern,
    String? tagPrefix,
    List<String>? architectures = const [],
    bool includePrerelease = false,
  }) async => null;
}
