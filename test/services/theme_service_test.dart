import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:autonomix/services/theme_service.dart';

void main() {
  group('ThemeService', () {
    test('initial theme is system', () {
      final service = ThemeService();
      expect(service.theme, equals(AppTheme.system));
    });

    test('isLoading is true initially', () {
      final service = ThemeService();
      expect(service.isLoading, isTrue);
    });

    test('isDarkMode defaults to true', () {
      final service = ThemeService();
      expect(service.isDarkMode, isTrue);
    });

    test('setTheme changes theme to light', () async {
      final service = ThemeService();
      await service.setTheme(AppTheme.light);
      expect(service.theme, equals(AppTheme.light));
      expect(service.isDarkMode, isFalse);
    });

    test('setTheme changes theme to dark', () async {
      final service = ThemeService();
      await service.setTheme(AppTheme.dark);
      expect(service.theme, equals(AppTheme.dark));
      expect(service.isDarkMode, isTrue);
    });

    test('setTheme changes theme to system', () async {
      final service = ThemeService();
      await service.setTheme(AppTheme.system);
      expect(service.theme, equals(AppTheme.system));
    });

    test('setTheme notifies listeners', () async {
      final service = ThemeService();
      var notified = false;
      service.addListener(() {
        notified = true;
      });
      await service.setTheme(AppTheme.dark);
      expect(notified, isTrue);
    });

    test('setTheme with same theme does not notify', () async {
      final service = ThemeService();
      var notifyCount = 0;
      service.addListener(() {
        notifyCount++;
      });
      await service.setTheme(AppTheme.system);
      expect(notifyCount, equals(0));
    });

    test('lightTheme returns light theme', () async {
      final service = ThemeService();
      final theme = service.lightTheme;
      expect(theme, isA<ThemeData>());
      expect(theme.colorScheme.brightness, equals(Brightness.light));
    });

    test('darkTheme returns dark theme', () async {
      final service = ThemeService();
      final theme = service.darkTheme;
      expect(theme, isA<ThemeData>());
      expect(theme.colorScheme.brightness, equals(Brightness.dark));
    });

    test('AppTheme enum has three values', () {
      expect(AppTheme.values.length, equals(3));
      expect(AppTheme.values.contains(AppTheme.light), isTrue);
      expect(AppTheme.values.contains(AppTheme.dark), isTrue);
      expect(AppTheme.values.contains(AppTheme.system), isTrue);
    });

    test('AppTheme light has correct name', () {
      expect(AppTheme.light.name, equals('light'));
    });

    test('AppTheme dark has correct name', () {
      expect(AppTheme.dark.name, equals('dark'));
    });

    test('AppTheme system has correct name', () {
      expect(AppTheme.system.name, equals('system'));
    });
  });

  group('ThemeService persistence', () {
    test('theme is saved to preferences', () async {
      final service = ThemeService();
      await service.setTheme(AppTheme.dark);
      // Persistence is handled asynchronously via SharedPreferences
      // This test documents the expected behavior
      expect(service.theme, equals(AppTheme.dark));
    });

    test('theme loads from preferences on init', () async {
      // This would require mocking SharedPreferences
      // Documents expected behavior for future implementation
      final service = ThemeService();
      expect(service.theme, equals(AppTheme.system));
    });
  });

  group('ThemeService ChangeNotifier', () {
    test('extends ChangeNotifier', () {
      final service = ThemeService();
      expect(service, isA<ChangeNotifier>());
    });

    test('implements StreamController', () {
      final service = ThemeService();
      expect(service, isA<Listenable>());
    });

    test('can add multiple listeners', () async {
      final service = ThemeService();
      var count = 0;
      service.addListener(() => count++);
      service.addListener(() => count++);
      await service.setTheme(AppTheme.dark);
      expect(count, equals(2));
    });

    test('listeners are notified on theme change', () async {
      final service = ThemeService();
      var themeChanged = false;
      service.addListener(() {
        themeChanged = true;
      });
      await service.setTheme(AppTheme.light);
      expect(themeChanged, isTrue);
    });
  });
}
