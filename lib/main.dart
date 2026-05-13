import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/home_screen.dart';
import 'services/database_service.dart';
import 'services/github_service.dart';
import 'services/installer_service.dart';
import 'services/theme_service.dart';
import 'services/settings_service.dart';

void main(List<String> args) {
  if (args.contains('--version') || args.contains('-v')) {
    // Basic CLI support to prevent GUI launch on version check
    print('Autonomix 0.3.7-b5');
    return;
  }
  runApp(const AutonomixApp());
}

class AutonomixApp extends StatelessWidget {
  const AutonomixApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();
    return MultiProvider(
      providers: [
        Provider(create: (_) => DatabaseService()),
        Provider(create: (_) => settingsService),
        Provider(
          create: (context) => GitHubService(
            settingsService: settingsService,
          ),
        ),
        Provider(create: (_) => InstallerService()),
        ChangeNotifierProvider(
          create: (_) => ThemeService(
            settingsService: settingsService,
          ),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          // Debug logging
          final ts = DateTime.now().toString().substring(11, 19);
          final themeModeValue = themeService.isDarkMode ? 'dark' : 'light';
          print('[$ts] Consumer<ThemeService> builder: theme=${themeService.theme.name}, isDarkMode=${themeService.isDarkMode}, isLoading=${themeService.isLoading}, themeMode=$themeModeValue');
          
          return MaterialApp(
            title: 'Autonomix',
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
