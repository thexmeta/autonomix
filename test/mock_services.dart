import 'package:autonomix/services/settings_service.dart';
import 'package:autonomix/services/theme_service.dart';
import 'package:autonomix/models/tracked_app.dart';
import 'package:autonomix/services/database_service.dart';
import 'package:autonomix/services/github_service.dart';

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
}

class MockDatabaseService extends DatabaseService {
  @override
  Future<List<TrackedApp>> getAllApps() async => [];

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
}
