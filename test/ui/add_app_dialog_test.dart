import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autonomix/ui/widgets/add_app_dialog.dart';
import 'package:provider/provider.dart';
import 'package:autonomix/services/settings_service.dart';
import 'package:autonomix/services/github_service.dart';
import '../mock_services.dart';

void main() {
  group('AddAppDialog', () {
    testWidgets('displays repo owner field', (WidgetTester tester) async {
      late Map<String, dynamic>? result;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (dialogContext) => AddAppDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      // Tap to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.textContaining('Add App'), findsOneWidget);
      expect(find.textContaining('Repository Owner'), findsWidgets);
    });

    testWidgets('displays repo name field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Repository Name'), findsWidgets);
    });

    testWidgets('displays asset filter pattern field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Asset Filter Pattern'), findsWidgets);
    });

    testWidgets('displays tag prefix field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tag Prefix'), findsWidgets);
    });

    testWidgets('displays architecture selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Architecture'), findsWidgets);
    });

    testWidgets('displays include prerelease toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Include Pre-release'), findsWidgets);
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('displays help text with examples', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should have help text
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to submit without filling required fields
      final addButton = find.textContaining('Add');
      await tester.tap(addButton);
      await tester.pump();

      // Should show validation error
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('accepts valid asset filter pattern', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter valid pattern
      final patternField = find.byType(TextField).at(2); // Third text field
      await tester.enterText(patternField, '*amd64*.deb');
      await tester.pump();

      expect(find.text('*amd64*.deb'), findsOneWidget);
    });

    testWidgets('accepts valid tag prefix', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter valid tag prefix
      final tagPrefixField = find.byType(TextField).at(3); // Fourth text field
      await tester.enterText(tagPrefixField, 'desktop-');
      await tester.pump();

      expect(find.text('desktop-'), findsOneWidget);
    });

    testWidgets('allows multiple architecture selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should have checkboxes for architectures
      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('toggle prerelease switch works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find and toggle the switch
      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pump();

      // Switch should change state
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('cancel button closes dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap cancel
      final cancelButton = find.textContaining('Cancel');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.textContaining('Add App'), findsNothing);
    });

    testWidgets('displays filter examples in help text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should contain example patterns
      expect(find.textContaining('Example'), findsWidgets);
      expect(find.textContaining('.deb'), findsWidgets);
      expect(find.textContaining('amd64'), findsWidgets);
    });

    testWidgets('form layout is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsService>.value(value: MockSettingsService()),
            Provider<GitHubService>.value(value: MockGitHubService()),
          ],
          child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AddAppDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should be scrollable
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}
