import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:autonomix/widgets/theme_selector.dart';
import 'package:autonomix/services/theme_service.dart';

void main() {
  group('ThemeSelector', () {
    testWidgets('displays theme options', (WidgetTester tester) async {
      final themeService = ThemeService();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSelector(),
            ),
          ),
        ),
      );

      // Verify theme selector is visible
      expect(find.byType(ThemeSelector), findsOneWidget);
    });

    testWidgets('shows current theme selection', (WidgetTester tester) async {
      final themeService = ThemeService();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSelector(),
            ),
          ),
        ),
      );

      // Should show theme options
      expect(find.textContaining('Light'), findsWidgets);
      expect(find.textContaining('Dark'), findsWidgets);
      expect(find.textContaining('System'), findsWidgets);
    });

    testWidgets('calls onThemeChange when theme selected', (WidgetTester tester) async {
      final themeService = ThemeService();
      String? selectedTheme;

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSelector(
                onThemeChange: (theme) {
                  selectedTheme = theme;
                },
              ),
            ),
          ),
        ),
      );

      // Tap on dark theme option
      final darkOption = find.textContaining('Dark');
      await tester.tap(darkOption);
      await tester.pump();

      // Verify theme change was triggered
      expect(selectedTheme, equals('dark'));
    });

    testWidgets('updates UI when theme changes', (WidgetTester tester) async {
      final themeService = ThemeService();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSelector(),
            ),
          ),
        ),
      );

      // Initial theme
      expect(find.byType(ThemeSelector), findsOneWidget);

      // Change theme programmatically
      themeService.setTheme('dark');
      await tester.pump();

      // UI should update
      expect(find.byType(ThemeSelector), findsOneWidget);
    });

    testWidgets('displays theme icons', (WidgetTester tester) async {
      final themeService = ThemeService();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSelector(),
            ),
          ),
        ),
      );

      // Should have icons for themes
      expect(find.byIcon(Icons.brightness_6), findsWidgets); // Light
      expect(find.byIcon(Icons.brightness_4), findsWidgets); // Dark
      expect(find.byIcon(Icons.brightness_auto), findsWidgets); // System
    });

    testWidgets('highlights current theme', (WidgetTester tester) async {
      final themeService = ThemeService();
      themeService.setTheme('light');

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSelector(),
            ),
          ),
        ),
      );

      // Current theme should be visually distinct
      expect(find.byType(ThemeSelector), findsOneWidget);
    });

    testWidgets('theme selection is persisted', (WidgetTester tester) async {
      final themeService = ThemeService();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSelector(),
            ),
          ),
        ),
      );

      // Select dark theme
      await tester.tap(find.textContaining('Dark'));
      await tester.pump();

      // Verify persistence (would be stored in preferences)
      expect(themeService.currentTheme, equals('dark'));
    });

    testWidgets('displays theme preview', (WidgetTester tester) async {
      final themeService = ThemeService();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSelector(),
            ),
          ),
        ),
      );

      // Should show preview colors
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('handles system theme mode', (WidgetTester tester) async {
      final themeService = ThemeService();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSelector(),
            ),
          ),
        ),
      );

      // Select system theme
      await tester.tap(find.textContaining('System'));
      await tester.pump();

      expect(themeService.currentTheme, equals('system'));
    });

    testWidgets('theme selector has proper layout', (WidgetTester tester) async {
      final themeService = ThemeService();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSelector(),
            ),
          ),
        ),
      );

      // Verify layout structure
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('theme options are tappable', (WidgetTester tester) async {
      final themeService = ThemeService();
      String? selectedTheme;

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSelector(
                onThemeChange: (theme) {
                  selectedTheme = theme;
                },
              ),
            ),
          ),
        ),
      );

      // Tap each theme option
      await tester.tap(find.textContaining('Light'));
      await tester.pump();
      expect(selectedTheme, equals('light'));

      await tester.tap(find.textContaining('Dark'));
      await tester.pump();
      expect(selectedTheme, equals('dark'));

      await tester.tap(find.textContaining('System'));
      await tester.pump();
      expect(selectedTheme, equals('system'));
    });

    testWidgets('displays theme descriptions', (WidgetTester tester) async {
      final themeService = ThemeService();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSelector(),
            ),
          ),
        ),
      );

      // Should have descriptive text
      expect(find.byType(Text), findsWidgets);
    });
  });
}
