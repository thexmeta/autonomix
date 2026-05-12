import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import '../services/github_service.dart';
import '../services/installer_service.dart';
import '../services/settings_service.dart';
import '../services/debug_logger.dart';
import '../models/tracked_app.dart';
import '../models/tracked_deb_package.dart';
import '../models/install_type.dart';
import '../models/release.dart';
import '../models/batch_operation_result.dart';
import '../services/external_app_checker.dart';
import 'widgets/add_app_dialog.dart';
import 'widgets/app_list_item.dart';
import 'widgets/deb_package_list_item.dart';
import 'widgets/deb_package_details_sheet.dart';
import '../widgets/theme_selector.dart';
import '../widgets/batch_action_bar.dart';
import 'widgets/edit_app_dialog.dart';
import 'widgets/edit_deb_package_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TrackedApp> _apps = [];
  List<TrackedDebPackage> _debPackages = [];
  bool _isLoading = true;
  bool _isMultiSelectMode = false;
  Set<int> _selectedIndices = {}; // Indices for _apps
  Set<int> _selectedDebIndices = {}; // Indices for _debPackages
  bool _startupUpdateChecked = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadApps();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
      if (packageInfo.buildNumber.isNotEmpty) {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      }
    });
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<DatabaseService>();
      final apps = await db.getAllApps();
      final debPackages = await db.getAllDebPackages();
      setState(() {
        _apps = apps;
        _debPackages = debPackages;
        _isLoading = false;
      });
      // Auto-check for updates on startup (once per session)
      if (!_startupUpdateChecked && (apps.isNotEmpty || debPackages.isNotEmpty)) {
        _startupUpdateChecked = true;
        _checkAllUpdatesOnStartup();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading apps: $e')),
        );
      }
    }
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedIndices.clear();
        _selectedDebIndices.clear();
      }
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _toggleDebSelection(int index) {
    setState(() {
      if (_selectedDebIndices.contains(index)) {
        _selectedDebIndices.remove(index);
      } else {
        _selectedDebIndices.add(index);
      }
    });
  }

  Future<void> _openGitHubRepo() async {
    const url = 'https://github.com/thexmeta/autonomix';
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open URL: $e')),
        );
      }
    }
  }

  Future<void> _showDebugLog() async {
    final logPath = await dlogPath();
    String logContent = 'Log file not available';
    if (logPath != null) {
      try {
        logContent = await File(logPath).readAsString();
      } catch (e) {
        logContent = 'Error reading log: $e';
      }
    }
    
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Log'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: SelectableText(logContent, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await dlogClear();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Clear Log'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

Future<void> _deleteApp(int index) async {
    await dlog('DELETE', '=== START _deleteApp ===', data: {
      'index': index.toString(),
      'apps_length': _apps.length.toString(),
      'context_mounted': mounted.toString(),
    });

    try {
      if (index >= _apps.length || index < 0) {
        await dlog('DELETE', 'Invalid index', data: {
          'index': index.toString(),
          'apps_length': _apps.length.toString(),
        });
        return;
      }
      
      final app = _apps[index];
      await dlog('DELETE', 'App selected for deletion', data: {
        'id': app.id?.toString() ?? 'null',
        'displayName': app.displayName,
        'repoOwner': app.repoOwner,
        'repoName': app.repoName,
      });

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove from List'),
          content: Text(
            'Remove "${app.displayName}" from your tracked apps? This will not uninstall the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      await dlog('DELETE', 'Dialog result', data: {'confirmed': (confirmed == true).toString()});

      if (confirmed == true) {
        try {
          final db = context.read<DatabaseService>();
          await dlog('DELETE', 'Calling db.deleteApp', data: {'appId': app.id?.toString() ?? 'null'});
          await db.deleteApp(app.id!);
          
          await dlog('DELETE', 'App deleted from DB, reloading list');
          await _loadApps();
          
          if (mounted) {
            await dlog('DELETE', 'Showing success snackbar');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${app.displayName} removed from list')),
            );
          } else {
            await dlog('DELETE', 'Widget not mounted, skipped snackbar');
          }
        } catch (e, stackTrace) {
          await dlog('DELETE', 'ERROR during deletion', data: {
            'error': e.toString(),
            'stack': stackTrace.toString(),
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error removing app: $e')),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      await dlog('DELETE', 'FATAL ERROR', data: {
        'error': e.toString(),
        'stack': stackTrace.toString(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fatal error: $e')),
        );
      }
    }
    
    await dlog('DELETE', '=== END _deleteApp ===');
  }

Future<void> _batchDelete() async {
    if (_selectedIndices.isEmpty && _selectedDebIndices.isEmpty) return;
    
    final totalCount = _selectedIndices.length + _selectedDebIndices.length;
    
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Batch Delete'),
          content: Text('Remove $totalCount items from your tracked list?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final db = context.read<DatabaseService>();
      int successCount = 0;
      int failCount = 0;

      // Apps to delete
      final appsToDelete = <TrackedApp>[];
      for (var index in _selectedIndices) {
        if (index >= 0 && index < _apps.length) {
          appsToDelete.add(_apps[index]);
        }
      }

      // Deb packages to delete
      final debsToDelete = <TrackedDebPackage>[];
      for (var index in _selectedDebIndices) {
        if (index >= 0 && index < _debPackages.length) {
          debsToDelete.add(_debPackages[index]);
        }
      }

      // Execute deletions
      for (var app in appsToDelete) {
        try {
          await db.deleteApp(app.id!);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      for (var pkg in debsToDelete) {
        try {
          await db.deleteDebPackage(pkg.id!);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      await _loadApps();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Batch delete: $successCount succeeded, $failCount failed'),
          ),
        );
      }
    } catch (e) {
      print('Error in batch delete: $e');
    }
  }

Future<void> _editApp(int index) async {
  if (index >= _apps.length) return;
  final app = _apps[index];

  final updatedApp = await showDialog<TrackedApp>(
    context: context,
    builder: (context) => EditAppDialog(app: app),
  );

  if (updatedApp != null) {
    try {
      final db = context.read<DatabaseService>();
      await db.updateApp(updatedApp);
      await _loadApps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('App updated: ${updatedApp.displayName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }
}

  void _selectAll() {
    setState(() {
      _selectedIndices = Set.from(Iterable.generate(_apps.length));
      _selectedDebIndices = Set.from(Iterable.generate(_debPackages.length));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIndices.clear();
      _selectedDebIndices.clear();
    });
  }

  /// Check all apps for updates on startup (silent, no UI feedback)
  Future<void> _checkAllUpdatesOnStartup() async {
    if (_apps.isEmpty) return;

    final gh = context.read<GitHubService>();
    final db = context.read<DatabaseService>();

    for (var app in _apps) {
      try {
        final packageInfo = await gh.getLatestReleaseWithPackageInfo(
          app.repoOwner,
          app.repoName,
          assetFilterPattern: app.assetFilterPattern,
          tagPrefix: app.tagPrefix,
          architectures: app.architectures,
          includePrerelease: app.includePrerelease,
        );
        
        String? extVersion = await ExternalAppChecker.getExternalVersion(app);
        
        if (packageInfo != null) {
          final release = packageInfo['release'] as Release;
          final updatedApp = app.copyWith(
            latestVersion: release.tagName,
            installedVersion: extVersion ?? app.installedVersion,
            latestReleaseDate: release.publishedAt,
            fetchedPackage: packageInfo['packageName'] as String?,
            lastChecked: DateTime.now(),
          );
          await db.updateApp(updatedApp);
        } else if (extVersion != null) {
          // Always update if we found a version and current is different or null
          if (extVersion != app.installedVersion) {
            final updatedApp = app.copyWith(
              installedVersion: extVersion,
              lastChecked: DateTime.now(),
            );
            await db.updateApp(updatedApp);
          }
        }
      } catch (e) {
        // Silent fail on startup - don't bother user
      }
    }

    // Reload apps to show updated versions
    _loadApps();
  }

  Future<void> _batchUpdateCheck() async {
    if (_selectedIndices.isEmpty && _selectedDebIndices.isEmpty) return;

    final gh = context.read<GitHubService>();
    final db = context.read<DatabaseService>();
    
    // Create progress tracker
    final progress = BatchProgress(
      total: _selectedIndices.length + _selectedDebIndices.length,
      startTime: DateTime.now(),
    );
    
    // Show progress dialog
    if (!mounted) return;
    
    final dialogController = ProgressController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BatchProgressDialog(
        progress: progress,
        controller: dialogController,
      ),
    );

    final results = <BatchOperationResult>[];
    const concurrencyLimit = 5;
    
    try {
      // Process GitHub Apps with limited concurrency
      for (var i = 0; i < _selectedIndices.length; i += concurrencyLimit) {
        final batch = _selectedIndices
            .skip(i)
            .take(concurrencyLimit)
            .where((idx) => idx < _apps.length)
            .toList();
        
        final batchTasks = batch.map((index) async {
          final app = _apps[index];
          progress.currentOperation = app.displayName;
          
          try {
            final packageInfo = await gh.getLatestReleaseWithPackageInfo(
              app.repoOwner,
              app.repoName,
              assetFilterPattern: app.assetFilterPattern,
              tagPrefix: app.tagPrefix,
              architectures: app.architectures,
              includePrerelease: app.includePrerelease,
            );
            
            String? extVersion = await ExternalAppChecker.getExternalVersion(app);
            
            if (packageInfo != null) {
              final release = packageInfo['release'] as Release;
              final updatedApp = app.copyWith(
                latestVersion: release.tagName,
                installedVersion: extVersion ?? app.installedVersion,
                latestReleaseDate: release.publishedAt,
                fetchedPackage: packageInfo['packageName'] as String?,
                lastChecked: DateTime.now(),
              );
              await db.updateApp(updatedApp);
              
              progress.completed++;
              progress.successful++;
              
              return BatchOperationResult(
                appName: app.displayName,
                success: true,
                newVersion: release.tagName,
              );
            } else {
              if (extVersion != null && extVersion != app.installedVersion) {
                await db.updateApp(app.copyWith(installedVersion: extVersion));
              }
              progress.completed++;
              progress.failed++;
              
              return const BatchOperationResult(
                appName: '',
                success: false,
                error: 'No package info found',
              );
            }
          } catch (e) {
            progress.completed++;
            progress.failed++;
            
            return BatchOperationResult(
              appName: app.displayName,
              success: false,
              error: e.toString(),
            );
          }
        });
        
        final batchResults = await Future.wait(batchTasks);
        results.addAll(batchResults);
        
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Process Deb Packages
      for (var index in _selectedDebIndices) {
        if (index >= _debPackages.length) continue;
        final pkg = _debPackages[index];
        progress.currentOperation = pkg.effectiveDisplayName;
        
        try {
           await db.checkDebPackageUpdates();
           progress.completed++;
           progress.successful++;
        } catch (e) {
           progress.completed++;
           progress.failed++;
        }
      }

    } catch (e) {
      // Handle unexpected errors
    } finally {
      dialogController.close();
    }

    _loadApps();
    
    // Show results summary
    if (mounted) {
      await _showBatchResultsSummary(results, progress);
    }
  }

  Future<void> _showBatchResultsSummary(
    List<BatchOperationResult> results,
    BatchProgress progress,
  ) async {
    final successful = results.where((r) => r.success).toList();
    final failed = results.where((r) => !r.success).toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batch Update Results'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text('${successful.length} successful'),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.error,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text('${failed.length} failed'),
                  ],
                ),
                const Divider(),
                // Time info
                Text(
                  'Completed in ${progress.elapsed.inSeconds}.${(progress.elapsed.inMilliseconds % 1000).toString().padLeft(3, '0')}s',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                // Successful updates
                if (successful.isNotEmpty) ...[
                  const Text(
                    'Updated:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...successful.map((result) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(result.appName),
                        if (result.newVersion != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '→ ${result.newVersion}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
                // Failed updates
                if (failed.isNotEmpty) ...[
                  const Text(
                    'Failed:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...failed.map((result) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.error, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(result.appName),
                              if (result.error != null)
                                Text(
                                  result.error!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red.shade700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSingleApp(int index) async {
    if (index < 0 || index >= _apps.length) return;
    
    final app = _apps[index];
    final gh = context.read<GitHubService>();
    final db = context.read<DatabaseService>();
    
    try {
      final packageInfo = await gh.getLatestReleaseWithPackageInfo(
        app.repoOwner,
        app.repoName,
        assetFilterPattern: app.assetFilterPattern,
        tagPrefix: app.tagPrefix,
        architectures: app.architectures,
        includePrerelease: app.includePrerelease,
      );
      
      String? extVersion = await ExternalAppChecker.getExternalVersion(app);
      
      if (packageInfo != null) {
        final release = packageInfo['release'] as Release;
        final updatedApp = app.copyWith(
          latestVersion: release.tagName,
          installedVersion: extVersion ?? app.installedVersion,
          latestReleaseDate: release.publishedAt,
          fetchedPackage: packageInfo['packageName'] as String?,
          lastChecked: DateTime.now(),
        );
        await db.updateApp(updatedApp);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated ${app.displayName} to ${release.tagName}'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } else {
        if (extVersion != null) {
          if (extVersion != app.installedVersion) {
            await db.updateApp(app.copyWith(installedVersion: extVersion));
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No update found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
    
    _loadApps();
  }

  Future<void> _updateSingleDebPackage(int index) async {
    if (index < 0 || index >= _debPackages.length) return;
    
    final pkg = _debPackages[index];
    final db = context.read<DatabaseService>();
    
    try {
      final updates = await db.checkDebPackageUpdates();
      if (updates.containsKey(pkg.name)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New version found for ${pkg.name}: ${updates[pkg.name]}'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No update found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating deb package: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
    
    _loadApps();
  }

  Future<void> _batchInstall() async {
    final gh = context.read<GitHubService>();
    final installer = context.read<InstallerService>();
    final db = context.read<DatabaseService>();
    int successCount = 0;
    int failCount = 0;

    // Install Apps
    for (var index in _selectedIndices) {
      if (index >= _apps.length) continue;
      final app = _apps[index];
      try {
        final release = await gh.getLatestRelease(
          app.repoOwner,
          app.repoName,
          assetFilterPattern: app.assetFilterPattern,
          tagPrefix: app.tagPrefix,
          architectures: app.architectures,
          includePrerelease: app.includePrerelease,
        );
        if (release == null) continue;

        // Find first supported asset
        InstallType? installType;
        String? assetUrl;
        String? assetName;

        for (var asset in release.assets) {
          final type = installer.identifyAssetType(asset.name);
          if (type != null) {
            installType = type;
            assetUrl = asset.browserDownloadUrl;
            assetName = asset.name;
            break;
          }
        }

        if (installType == null || assetUrl == null) continue;

        final file = await installer.downloadFile(assetUrl, assetName!);
        final result = await installer.installPackage(file, installType);

        final updatedApp = app.copyWith(
          installedVersion: release.tagName,
          installType: installType,
          launchCommand: result.launchCommand,
          packageName: result.packageName,
          lastChecked: DateTime.now(),
        );
        await db.updateApp(updatedApp);
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    // Install Deb Packages
    for (var index in _selectedDebIndices) {
      if (index >= _debPackages.length) continue;
      final pkg = _debPackages[index];
      try {
        final file = await installer.downloadFile(pkg.packageUrl, pkg.name.endsWith('.deb') ? pkg.name : '${pkg.name}.deb');
        final result = await installer.installPackage(file, InstallType.deb);
        
        final version = TrackedDebPackage.extractVersionFromFilename(file.path.split('/').last);

        final updatedPkg = pkg.copyWith(
          installedVersion: version ?? pkg.latestVersion,
          launchCommand: result.launchCommand,
          packageName: result.packageName,
          lastChecked: DateTime.now(),
        );
        await db.updateDebPackage(updatedPkg);
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    _loadApps();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Batch install: $successCount succeeded, $failCount failed')),
      );
    }
  }

  Future<void> _addApp() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddAppDialog(),
    );

    if (result != null) {
      try {
        final db = context.read<DatabaseService>();
        if (result['isDirectUrl'] == true) {
          await db.addDebPackage(
            name: result['name']!,
            packageUrl: result['url']!,
            displayName: result['name'],
            launchCommand: result['launchCommand'] as String?,
            packageName: result['packageName'] as String?,
          );
        } else {
          await db.addApp(
            result['owner']!,
            result['repo']!,
            result['name']!,
            assetFilterPattern: result['assetFilterPattern'] as String?,
            tagPrefix: result['tagPrefix'] as String?,
            architectures: result['architectures'] as List<String>? ?? [],
            includePrerelease: result['includePrerelease'] as bool? ?? false,
            launchCommand: result['launchCommand'] as String?,
            packageName: result['packageName'] as String?,
          );
        }
        await _loadApps();
        
        if (result['isDirectUrl'] != true) {
          // Trigger an immediate check for the new GitHub app
          final index = _apps.indexWhere((a) => 
            a.repoOwner == result['owner'] && a.repoName == result['repo']);
          if (index != -1) {
            _updateSingleApp(index);
          }
        } else {
          // For direct URLs, we might want to check version too
          final index = _debPackages.indexWhere((p) => p.packageUrl == result['url']);
          if (index != -1) {
             _updateSingleDebPackage(index);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding app: $e')),
          );
        }
      }
    }
  }

  Future<void> _showEditAppDialog() async {
    if (_apps.isEmpty) return;

    final result = await showDialog<TrackedApp>(
      context: context,
      builder: (context) => EditAppDialog(app: _apps.first),
    );

    if (result != null) {
      try {
        final db = context.read<DatabaseService>();
        await db.updateApp(result);
        _loadApps();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('App updated: ${result.displayName}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving: $e')),
          );
        }
      }
    }
  }

  Future<void> _checkForUpdates() async {
    final gh = context.read<GitHubService>();
    final db = context.read<DatabaseService>();

    // Check GitHub Apps
    for (var app in _apps) {
      try {
        final packageInfo = await gh.getLatestReleaseWithPackageInfo(
          app.repoOwner,
          app.repoName,
          assetFilterPattern: app.assetFilterPattern,
          tagPrefix: app.tagPrefix,
          architectures: app.architectures,
          includePrerelease: app.includePrerelease,
        );
        if (packageInfo != null) {
          final release = packageInfo['release'] as Release;
          final updatedApp = app.copyWith(
            latestVersion: release.tagName,
            latestReleaseDate: release.publishedAt,
            fetchedPackage: packageInfo['packageName'] as String?,
            lastChecked: DateTime.now(),
          );
          await db.updateApp(updatedApp);
        }
      } catch (e) {
        print('Error checking updates for ${app.displayName}: $e');
      }
    }

    // Check Deb Packages
    try {
      await db.checkDebPackageUpdates();
    } catch (e) {
      print('Error checking deb package updates: $e');
    }

    _loadApps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isMultiSelectMode
            ? Text('${_selectedIndices.length + _selectedDebIndices.length} selected')
: Row(
        children: [
          const Text('Autonomix'),
          const SizedBox(width: 16),
          const Icon(Icons.info, size: 16, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            _appVersion.isEmpty ? 'v0.3.6' : _appVersion,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
        actions: [
          IconButton(
            icon: const Icon(Icons.code, size: 20, color: Colors.white70),
            onPressed: _openGitHubRepo,
            tooltip: 'View on GitHub',
          ),
        if (_isMultiSelectMode) ...[
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _selectAll,
            tooltip: 'Select All',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _deselectAll,
            tooltip: 'Deselect All',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _batchUpdateCheck,
            tooltip: 'Check Selected for Updates',
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditAppDialog(),
            tooltip: 'Edit app',
          ),
        ],
        IconButton(
          icon: const Icon(Icons.bug_report),
          onPressed: _showDebugLog,
          tooltip: 'Debug Log',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _showSettings(context),
          tooltip: 'Settings',
        ),
        IconButton(
          icon: Icon(_isMultiSelectMode ? Icons.close : Icons.select_all),
          onPressed: _toggleMultiSelectMode,
          tooltip: _isMultiSelectMode ? 'Close Multi-select' : 'Select Multiple',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _checkForUpdates,
          tooltip: 'Check for updates',
        ),
      ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_apps.isEmpty && _debPackages.isEmpty)
              ? const Center(child: Text('No apps tracked. Add one!'))
    : ListView.builder(
        itemCount: _apps.length + _debPackages.length,
        itemBuilder: (context, index) {
          if (index < _apps.length) {
            return AppListItem(
              app: _apps[index],
              isSelected: _isMultiSelectMode && _selectedIndices.contains(index),
              onEdit: () => _editApp(index),
              onDelete: () async {
                if (mounted && index < _apps.length) {
                  _deleteApp(index);
                }
              },
              onUpdate: () => _updateSingleApp(index),
              onTap: () {
                if (_isMultiSelectMode) {
                  _toggleSelection(index);
                } else {
                  _showAppDetails(_apps[index]);
                }
              },
            );
          } else {
            final debIndex = index - _apps.length;
            return DebPackageListItem(
              package: _debPackages[debIndex],
              isSelected: _isMultiSelectMode && _selectedDebIndices.contains(debIndex),
              onEdit: () => _editDebPackage(debIndex),
              onDelete: () async {
                if (mounted) {
                  _deleteDebPackage(debIndex);
                }
              },
              onUpdate: () => _updateSingleDebPackage(debIndex),
              onTap: () {
                if (_isMultiSelectMode) {
                  _toggleDebSelection(debIndex);
                } else {
                  _showDebDetails(_debPackages[debIndex]);
                }
              },
            );
          }
        },
      ),
    bottomSheet: _isMultiSelectMode
        ? BatchActionBar(
            selectedCount: _selectedIndices.length + _selectedDebIndices.length,
            totalCount: _apps.length + _debPackages.length,
            onSelectAll: _selectAll,
            onDeselectAll: _deselectAll,
            onUpdateAll: _batchUpdateCheck,
            onInstallAll: _batchInstall,
            onDeleteAll: _batchDelete,
          )
        : null,
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton(
              onPressed: _addApp,
              child: const Icon(Icons.add),
            ),
    );
  }

  Future<void> _showAppDetails(TrackedApp app) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => AppDetailsSheet(app: app),
    );
    _loadApps();
  }

  Future<void> _showDebDetails(TrackedDebPackage package) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => DebPackageDetailsSheet(package: package),
    );
    _loadApps();
  }

  Future<void> _editDebPackage(int index) async {
    final pkg = _debPackages[index];
    final updatedPkg = await showDialog<TrackedDebPackage>(
      context: context,
      builder: (context) => EditDebPackageDialog(package: pkg),
    );

    if (updatedPkg != null) {
      final db = context.read<DatabaseService>();
      await db.updateDebPackage(updatedPkg);
      _loadApps();
    }
  }

  Future<void> _showSettings(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => _SettingsSheet(),
    );
  }


  Future<void> _deleteDebPackage(int index) async {
    final pkg = _debPackages[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Package'),
        content: Text('Are you sure you want to stop tracking ${pkg.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = context.read<DatabaseService>();
      await db.deleteDebPackage(pkg.id!);
      _loadApps();
    }
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isSavingToken = false;
  String? _message;
  String? _githubToken;
  bool _hasToken = false;
  int? _releasesPerPage;
  String _defaultArchitecture = 'amd64';
  final TextEditingController _releasesPerPageController = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _releasesPerPageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = context.read<SettingsService>();
    final token = await settings.getGithubToken();
    final hasToken = await settings.hasGithubToken();
    final releasesPerPage = await settings.getReleasesPerPage();
    final defaultArch = await settings.getDefaultArchitecture();
    
    await DebugLogger().log('SettingsUI', '_loadSettings: loaded values', data: {
      'token': token != null ? '***' : 'null',
      'releasesPerPage': releasesPerPage?.toString() ?? 'null',
      'defaultArch': defaultArch ?? 'null',
    });
    
    setState(() {
      _githubToken = token;
      _hasToken = hasToken;
      _releasesPerPage = releasesPerPage;
      _releasesPerPageController.text = releasesPerPage?.toString() ?? '100';
      _defaultArchitecture = defaultArch ?? 'amd64';
    });
    
    await DebugLogger().log('SettingsUI', '_loadSettings: setState completed', data: {
      'releasesPerPage': _releasesPerPage?.toString(),
      'defaultArchitecture': _defaultArchitecture,
      'controller_text': _releasesPerPageController.text,
    });
  }

  Future<void> _handleSaveReleasesPerPage(String value) async {
    final count = int.tryParse(value);
    if (count == null || count <= 0) {
      setState(() => _message = 'Invalid number');
      return;
    }
    try {
      final settings = context.read<SettingsService>();
      await settings.setReleasesPerPage(count);
      await _loadSettings();
      setState(() => _message = 'Releases per page saved');
    } catch (e) {
      setState(() => _message = 'Failed to save: $e');
    }
  }

  Future<void> _handleSaveDefaultArchitecture(String arch) async {
    try {
      final settings = context.read<SettingsService>();
      await settings.setDefaultArchitecture(arch);
      await _loadSettings();
      setState(() => _message = 'Default architecture saved');
    } catch (e) {
      setState(() => _message = 'Failed to save: $e');
    }
  }

  Future<void> _handleSaveToken(String token) async {
    setState(() => _isSavingToken = true);
    try {
      final settings = context.read<SettingsService>();
      await settings.setGithubToken(token);
      await _loadSettings();
      setState(() {
        _message = 'GitHub token saved';
        _isSavingToken = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to save token: $e';
        _isSavingToken = false;
      });
    }
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
      _message = null;
    });

    try {
      final db = context.read<DatabaseService>();
      final path = await db.exportConfig();
      setState(() {
        _message = 'Exported to: $path';
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Export failed: $e';
        _isExporting = false;
      });
    }
  }

  Future<void> _handleImport() async {
    setState(() {
      _isImporting = true;
      _message = null;
    });

    try {
      final db = context.read<DatabaseService>();
      final files = await db.getAllApps();
      final configDir = await getApplicationSupportDirectory();
      final importFile = File('${configDir.path}/autonomix-import.json');

      if (await importFile.exists()) {
        final count = await db.importConfig(importFile.path);
        setState(() {
          _message = 'Imported $count apps';
          _isImporting = false;
        });
      } else {
        setState(() {
          _message = 'No import file found';
          _isImporting = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Import failed: $e';
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const ThemeSelector(),
            const SizedBox(height: 16),
            const Text(
              'GitHub API',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a Personal Access Token to increase API rate limits.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _GithubTokenForm(
              initialValue: _githubToken,
              hasToken: _hasToken,
              onSave: _handleSaveToken,
              isLoading: _isSavingToken,
            ),
            const SizedBox(height: 16),
            Text(
              'GitHub API Limits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure how many releases to fetch from GitHub API (max 100).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _ReleasesPerPageForm(
              initialValue: _releasesPerPage?.toString() ?? '100',
              onSave: _handleSaveReleasesPerPage,
            ),
            const SizedBox(height: 16),
            const Text(
              'Defaults',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Default architecture for new apps',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _DefaultArchitectureForm(
              initialValue: _defaultArchitecture,
              onSave: _handleSaveDefaultArchitecture,
            ),
            const SizedBox(height: 16),
            const Text(
              'Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _handleExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: const Text('Export'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isImporting ? null : _handleImport,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload),
                    label: const Text('Import'),
                  ),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 8),
              Text(
                _message!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DefaultArchitectureForm extends StatefulWidget {
  final String initialValue;
  final Function(String) onSave;

  const _DefaultArchitectureForm({
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_DefaultArchitectureForm> createState() => _DefaultArchitectureFormState();
}

class _DefaultArchitectureFormState extends State<_DefaultArchitectureForm> {
  String _selectedArch = 'amd64';
  final List<String> _architectures = ['amd64', 'arm64', 'x86_64', 'arm', 'armhf', 'i386'];

  @override
  void initState() {
    super.initState();
    _selectedArch = widget.initialValue;
  }

  @override
  void didUpdateWidget(_DefaultArchitectureForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _selectedArch = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _architectures.contains(_selectedArch) ? _selectedArch : 'amd64',
          decoration: const InputDecoration(
            labelText: 'Default Architecture',
            prefixIcon: Icon(Icons.architecture),
          ),
          items: _architectures.map((arch) {
            return DropdownMenuItem(
              value: arch,
              child: Text(arch),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedArch = value);
            }
          },
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => widget.onSave(_selectedArch),
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ],
    );
  }
}

class _ReleasesPerPageForm extends StatefulWidget {
  final String initialValue;
  final Function(String) onSave;

  const _ReleasesPerPageForm({
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_ReleasesPerPageForm> createState() => _ReleasesPerPageFormState();
}

class _ReleasesPerPageFormState extends State<_ReleasesPerPageForm> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue;
  }

  @override
  void didUpdateWidget(_ReleasesPerPageForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Releases per page',
            hintText: '100',
            prefixIcon: const Icon(Icons.list),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => widget.onSave(_controller.text.trim()),
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _controller.text = '100';
                  widget.onSave('100');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GithubTokenForm extends StatefulWidget {
  final String? initialValue;
  final bool hasToken;
  final Function(String) onSave;
  final bool isLoading;

  const _GithubTokenForm({
    this.initialValue,
    required this.hasToken,
    required this.onSave,
    required this.isLoading,
  });

  @override
  State<_GithubTokenForm> createState() => _GithubTokenFormState();
}

class _GithubTokenFormState extends State<_GithubTokenForm> {
  final _controller = TextEditingController();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
  }

  @override
  void didUpdateWidget(_GithubTokenForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          obscureText: _obscureText,
          decoration: InputDecoration(
            labelText: 'Personal Access Token',
            hintText: 'ghp_...',
            prefixIcon: const Icon(Icons.key),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.isLoading
                    ? null
                    : () => widget.onSave(_controller.text.trim()),
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ),
            if (widget.hasToken) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isLoading
                      ? null
                      : () => widget.onSave(''),
                  icon: const Icon(Icons.delete),
                  label: const Text('Clear'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Controller for batch progress dialog
class ProgressController {
  final _streamController = StreamController<bool>.broadcast();
  
  Stream<bool> get stream => _streamController.stream;
  
  void close() {
    _streamController.add(true);
    _streamController.close();
  }
}

/// Progress dialog for batch operations
class _BatchProgressDialog extends StatelessWidget {
  final BatchProgress progress;
  final ProgressController controller;

  const _BatchProgressDialog({
    required this.progress,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Checking for Updates'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          StreamBuilder<bool>(
            stream: controller.stream,
            builder: (context, snapshot) {
              return FutureBuilder(
                future: Future.delayed(const Duration(milliseconds: 100)),
                builder: (context, _) {
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress.progressPercentage / 100,
                      ),
                      const SizedBox(height: 16),
                      // Progress text
                      Text(
                        '${progress.completed} of ${progress.total} completed',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current: ${progress.currentOperation}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatChip(
                            icon: Icons.check_circle,
                            color: Colors.green,
                            count: progress.successful,
                            label: 'Success',
                          ),
                          _StatChip(
                            icon: Icons.error,
                            color: Colors.red,
                            count: progress.failed,
                            label: 'Failed',
                          ),
                          _StatChip(
                            icon: Icons.access_time,
                            color: Colors.blue,
                            count: progress.elapsed.inSeconds,
                            label: 'Seconds',
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => controller.close(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Small stat chip for progress dialog
class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class AppDetailsSheet extends StatefulWidget {
  final TrackedApp app;

  const AppDetailsSheet({super.key, required this.app});

  @override
  State<AppDetailsSheet> createState() => _AppDetailsSheetState();
}

class _AppDetailsSheetState extends State<AppDetailsSheet> {
  bool _isInstalling = false;
  String? _statusMessage;
  String? _latestVersion;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _fetchLatestVersion();
  }

  Future<void> _fetchLatestVersion() async {
    try {
      final gh = context.read<GitHubService>();
      final release = await gh.getLatestRelease(
        widget.app.repoOwner,
        widget.app.repoName,
        assetFilterPattern: widget.app.assetFilterPattern,
        tagPrefix: widget.app.tagPrefix,
        architectures: widget.app.architectures,
        includePrerelease: widget.app.includePrerelease,
      );
      if (mounted) {
        setState(() {
          _latestVersion = release?.tagName;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchError = e.toString();
        });
      }
    }
  }

  Future<void> _install(BuildContext context) async {
    setState(() {
      _isInstalling = true;
      _statusMessage = 'Fetching releases...';
    });

    try {
      final gh = context.read<GitHubService>();
      final installer = context.read<InstallerService>();
      final db = context.read<DatabaseService>();

    final release = await gh.getLatestRelease(
  widget.app.repoOwner,
  widget.app.repoName,
  assetFilterPattern: widget.app.assetFilterPattern,
  tagPrefix: widget.app.tagPrefix,
  architectures: widget.app.architectures,
  includePrerelease: widget.app.includePrerelease,
);
    if (release == null) {
      throw Exception('No release found matching criteria');
    }

    // Find candidates
    final candidates = <InstallType, dynamic>{}; // dynamic to avoid importing ReleaseAsset
    for (var asset in release.assets) {
        final type = installer.identifyAssetType(asset.name);
        if (type != null) {
          candidates[type] = asset;
        }
      }

      if (candidates.isEmpty) {
        throw Exception('No supported assets found in release');
      }

      if (!mounted) return;

      // Show selection dialog
      final selectedType = await showDialog<InstallType>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Select Package Type'),
          children: candidates.keys.map((type) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, type),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(_getIconForType(type)),
                    const SizedBox(width: 12),
                    Text(type.displayName),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );

      if (selectedType == null) {
        setState(() => _isInstalling = false);
        return;
      }

      final asset = candidates[selectedType]!;
      
      setState(() => _statusMessage = 'Downloading ${asset.name}...');
      final file = await installer.downloadFile(asset.browserDownloadUrl, asset.name);

      setState(() => _statusMessage = 'Installing...');
      final result = await installer.installPackage(file, selectedType);

    // Update DB
    final updatedApp = widget.app.copyWith(
      installedVersion: release.tagName,
        installType: selectedType,
        launchCommand: result.launchCommand,
        packageName: result.packageName,
        lastChecked: DateTime.now(),
      );
      await db.updateApp(updatedApp);

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Installation successful')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInstalling = false;
          _statusMessage = 'Error: $e';
        });
      }
    }
  }

  IconData _getIconForType(InstallType type) {
    switch (type) {
      case InstallType.deb: return Icons.grid_view;
      case InstallType.rpm: return Icons.settings;
      case InstallType.appImage: return Icons.extension;
      case InstallType.flatpak: return Icons.layers;
      case InstallType.snap: return Icons.shopping_bag;
      default: return Icons.download;
    }
  }

  Future<void> _uninstall(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall App'),
        content: const Text('Are you sure you want to uninstall this app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isInstalling = true;
      _statusMessage = 'Uninstalling...';
    });

    try {
      await context.read<InstallerService>().uninstallPackage(widget.app);

      // Update DB - Clear installed fields
      final updatedApp = TrackedApp(
        id: widget.app.id,
        repoOwner: widget.app.repoOwner,
        repoName: widget.app.repoName,
        displayName: widget.app.displayName,
        createdAt: widget.app.createdAt,
        latestVersion: widget.app.latestVersion,
        lastChecked: widget.app.lastChecked,
        // Cleared:
        installedVersion: null,
        installType: null,
        launchCommand: null,
        packageName: null,
      );
      
      await context.read<DatabaseService>().updateApp(updatedApp);

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uninstallation successful')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInstalling = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Uninstall Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _launch(BuildContext context) async {
    try {
      await context.read<InstallerService>().launchApp(widget.app);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Launch Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.app.displayName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Repo: ${widget.app.repoOwner}/${widget.app.repoName}'),
Text('Installed: ${widget.app.installedVersion ?? "Not installed"}'),
Text('Latest: ${_fetchError != null ? "Error fetching" : (_latestVersion?.isNotEmpty == true ? _latestVersion : (widget.app.latestVersion ?? "Fetching..."))}'),
          const SizedBox(height: 16),
          if (_isInstalling) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(_statusMessage ?? ''),
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.app.isInstalled) ...[
                  OutlinedButton.icon(
                    onPressed: () => _uninstall(context),
                    icon: const Icon(Icons.delete),
                    label: const Text('Uninstall'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _launch(context),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Launch'),
                  ),
                ],
                const SizedBox(width: 8),
                if (widget.app.hasUpdate)
                  FilledButton.icon(
                    onPressed: () => _install(context),
                    icon: const Icon(Icons.system_update),
                    label: const Text('Update'),
                  ),
                const SizedBox(width: 8),
                if (!widget.app.isInstalled)
                  FilledButton.icon(
                    onPressed: () => _install(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Install'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
