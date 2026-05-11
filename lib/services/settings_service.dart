import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'debug_logger.dart';

class SettingsService {
  final DebugLogger _logger = DebugLogger();
  static const String _settingsFileName = 'settings.json';
  File? _settingsFile;

  Future<File> get _file async {
    if (_settingsFile != null) return _settingsFile!;
    final configDir = await getApplicationSupportDirectory();
    await Directory(configDir.path).create(recursive: true);
    _settingsFile = File(join(configDir.path, _settingsFileName));
    return _settingsFile!;
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    final stopwatch = Stopwatch()..start();
    await _logger.log('SettingsService', '=== START _loadSettings ===');
    try {
      final file = await _file;
      final exists = await file.exists();
      await _logger.log('SettingsService', 'File exists: $exists', data: {'path': file.path});
      
      if (!exists) {
        await _logger.log('SettingsService', 'File does not exist, returning empty');
        return {};
      }
      
      final content = await file.readAsString();
      await _logger.log('SettingsService', 'File content length: ${content.length}', data: {'length': content.length.toString()});
      
      if (content.isEmpty) {
        await _logger.log('SettingsService', 'File content is empty');
        return {};
      }
      
      final result = jsonDecode(content) as Map<String, dynamic>;
      await _logger.log('SettingsService', 'Decoded JSON', data: {
        'keys': result.keys.join(', '),
        'theme': result['theme']?.toString() ?? 'null',
        'github_token': result['github_token'] != null ? '***' : 'null',
      });
      
      stopwatch.stop();
      await _logger.log('SettingsService', '=== END _loadSettings (${stopwatch.elapsedMilliseconds}ms) ===');
      return result;
    } catch (e) {
      await _logger.log('SettingsService', 'ERROR in _loadSettings: $e');
      stopwatch.stop();
      await _logger.log('SettingsService', '=== END _loadSettings with ERROR (${stopwatch.elapsedMilliseconds}ms) ===');
      return {};
    }
  }

  Future<void> _saveSettings(Map<String, dynamic> settings) async {
    final stopwatch = Stopwatch()..start();
    await _logger.log('SettingsService', '=== START _saveSettings ===', data: {
      'keys': settings.keys.join(', '),
      'theme': settings['theme']?.toString() ?? 'null',
    });
    try {
      final file = await _file;
      await _logger.log('SettingsService', 'Writing to file', data: {'path': file.path});
      
      final encoded = jsonEncode(settings);
      await _logger.log('SettingsService', 'Encoded JSON', data: {'length': encoded.length.toString()});
      
      await file.writeAsString(encoded);
      await _logger.log('SettingsService', 'File written successfully');
      
      // Verify by reading back
      final verifyContent = await file.readAsString();
      await _logger.log('SettingsService', 'Verification read', data: {'content': verifyContent});
      
      stopwatch.stop();
      await _logger.log('SettingsService', '=== END _saveSettings (${stopwatch.elapsedMilliseconds}ms) ===');
    } catch (e) {
      await _logger.log('SettingsService', 'ERROR in _saveSettings: $e');
      stopwatch.stop();
      await _logger.log('SettingsService', '=== END _saveSettings with ERROR (${stopwatch.elapsedMilliseconds}ms) ===');
      rethrow;
    }
  }

  Future<String?> getGithubToken() async {
    final settings = await _loadSettings();
    return settings['github_token'] as String?;
  }

  Future<void> setGithubToken(String? token) async {
    final settings = await _loadSettings();
    if (token == null || token.isEmpty) {
      settings.remove('github_token');
    } else {
      settings['github_token'] = token;
    }
    await _saveSettings(settings);
  }

  Future<void> clearGithubToken() async {
    await setGithubToken(null);
  }

  Future<bool> hasGithubToken() async {
    final token = await getGithubToken();
    return token != null && token.isNotEmpty;
  }

  Future<int?> getReleasesPerPage() async {
    final settings = await _loadSettings();
    return settings['github_releases_per_page'] as int?;
  }

  Future<void> setReleasesPerPage(int? count) async {
    final settings = await _loadSettings();
    if (count == null || count <= 0) {
      settings.remove('github_releases_per_page');
    } else {
      settings['github_releases_per_page'] = count;
    }
    await _saveSettings(settings);
  }

  Future<int> getEffectiveReleasesPerPage() async {
    final count = await getReleasesPerPage();
    return count ?? 100; // Default to 100 if not set
  }

  Future<String?> getDefaultArchitecture() async {
    final settings = await _loadSettings();
    return settings['default_architecture'] as String?;
  }

  Future<void> setDefaultArchitecture(String? arch) async {
    final settings = await _loadSettings();
    if (arch == null || arch.isEmpty) {
      settings.remove('default_architecture');
    } else {
      settings['default_architecture'] = arch;
    }
    await _saveSettings(settings);
  }

  Future<String> getEffectiveDefaultArchitecture() async {
    final arch = await getDefaultArchitecture();
    return arch ?? 'amd64'; // Default to amd64 if not set
  }

  Future<String?> getTheme() async {
    final settings = await _loadSettings();
    return settings['theme'] as String?;
  }

  Future<void> setTheme(String? theme) async {
    final settings = await _loadSettings();
    if (theme == null || theme.isEmpty) {
      settings.remove('theme');
    } else {
      settings['theme'] = theme;
    }
    await _saveSettings(settings);
  }

  Future<bool> hasTheme() async {
    final theme = await getTheme();
    return theme != null && theme.isNotEmpty;
  }

  // Debug logging settings
  Future<bool> isDebugLoggingEnabled() async {
    final settings = await _loadSettings();
    return settings['enable_debug_logging'] as bool? ?? false;
  }

  Future<void> setDebugLoggingEnabled(bool enabled) async {
    final settings = await _loadSettings();
    settings['enable_debug_logging'] = enabled;
    await _saveSettings(settings);
  }
}
