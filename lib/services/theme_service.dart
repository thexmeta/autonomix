import 'package:flutter/material.dart';
import 'settings_service.dart';
import 'debug_logger.dart';

enum AppTheme {
  light,
  dark,
  system,
}

class ThemeService extends ChangeNotifier {
  AppTheme _theme = AppTheme.system;
  bool _isDarkMode = false;
  bool _isLoading = true;
  final SettingsService _settingsService;
  final DebugLogger _logger = DebugLogger();

  AppTheme get theme => _theme;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;

  ThemeService({required SettingsService settingsService})
      : _settingsService = settingsService {
    _logger.log('ThemeService', 'ThemeService created, starting _loadTheme');
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final stopwatch = Stopwatch()..start();
    await _logger.log('ThemeService', '=== START _loadTheme ===');
    try {
      await _logger.log('ThemeService', 'Calling _settingsService.getTheme()');
      final savedTheme = await _settingsService.getTheme();
      await _logger.log('ThemeService', 'getTheme() returned', data: {'value': savedTheme ?? 'null'});
      
      final themeStr = savedTheme ?? 'system';
      await _logger.log('ThemeService', 'Resolving theme string', data: {'themeStr': themeStr});
      
      _theme = AppTheme.values.firstWhere(
        (e) => e.name == themeStr,
        orElse: () => AppTheme.system,
      );
      await _logger.log('ThemeService', 'Theme resolved', data: {'theme': _theme.name});
      
      _updateSystemTheme();
      await _logger.log('ThemeService', 'After _updateSystemTheme', data: {'isDarkMode': _isDarkMode.toString()});
      
      _isLoading = false;
      await _logger.log('ThemeService', 'About to notifyListeners, theme=$_theme, isDarkMode=$_isDarkMode');
      notifyListeners();
      await _logger.log('ThemeService', 'notifyListeners completed');
      
      stopwatch.stop();
      await _logger.log('ThemeService', '=== END _loadTheme (${stopwatch.elapsedMilliseconds}ms) ===');
    } catch (e) {
      await _logger.log('ThemeService', 'ERROR in _loadTheme: $e');
      _theme = AppTheme.system;
      _updateSystemTheme();
      _isLoading = false;
      notifyListeners();
      stopwatch.stop();
      await _logger.log('ThemeService', '=== END _loadTheme with ERROR (${stopwatch.elapsedMilliseconds}ms) ===');
    }
  }

  @override
  void notifyListeners() {
    _logger.log('ThemeService', 'notifyListeners called', data: {
      'theme': _theme.name,
      'isDarkMode': _isDarkMode.toString(),
      'isLoading': _isLoading.toString(),
      'listenerCount': 'unknown',
    });
    super.notifyListeners();
  }

  Future<void> _saveTheme() async {
    final stopwatch = Stopwatch()..start();
    await _logger.log('ThemeService', '=== START _saveTheme ===', data: {'theme': _theme.name});
    try {
      await _logger.log('ThemeService', 'Calling _settingsService.setTheme', data: {'theme': _theme.name});
      await _settingsService.setTheme(_theme.name);
      await _logger.log('ThemeService', 'setTheme completed successfully');
      stopwatch.stop();
      await _logger.log('ThemeService', '=== END _saveTheme (${stopwatch.elapsedMilliseconds}ms) ===');
    } catch (e) {
      await _logger.log('ThemeService', 'ERROR in _saveTheme: $e');
      stopwatch.stop();
      await _logger.log('ThemeService', '=== END _saveTheme with ERROR (${stopwatch.elapsedMilliseconds}ms) ===');
    }
  }

  void _updateSystemTheme() {
    // Update isDarkMode based on current theme
    if (_theme == AppTheme.system) {
      // For now, system theme defaults to dark mode
      // Will be updated to check system preferences in Task 4.2
      _isDarkMode = true;
    } else {
      _isDarkMode = _theme == AppTheme.dark;
    }
  }

  Future<void> setTheme(AppTheme newTheme) async {
    if (_theme != newTheme) {
      _theme = newTheme;
      if (newTheme == AppTheme.system) {
        _updateSystemTheme();
      } else {
        _isDarkMode = newTheme == AppTheme.dark;
      }
      await _saveTheme();
      notifyListeners();
    }
  }

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
  );
}
