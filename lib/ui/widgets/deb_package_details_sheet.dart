import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tracked_deb_package.dart';
import '../../models/install_type.dart';
import '../../services/database_service.dart';
import '../../services/installer_service.dart';

class DebPackageDetailsSheet extends StatefulWidget {
  final TrackedDebPackage package;

  const DebPackageDetailsSheet({super.key, required this.package});

  @override
  State<DebPackageDetailsSheet> createState() => _DebPackageDetailsSheetState();
}

class _DebPackageDetailsSheetState extends State<DebPackageDetailsSheet> {
  bool _isInstalling = false;
  bool _isUninstalling = false;

  Future<void> _install() async {
    setState(() => _isInstalling = true);
    try {
      final installer = context.read<InstallerService>();
      final db = context.read<DatabaseService>();
      
      final file = await installer.downloadFile(
        widget.package.packageUrl, 
        widget.package.name.endsWith('.deb') ? widget.package.name : '${widget.package.name}.deb'
      );
      
      final result = await installer.installPackage(file, InstallType.deb);
      
      final version = TrackedDebPackage.extractVersionFromFilename(file.path.split('/').last);

      final updatedPkg = widget.package.copyWith(
        installedVersion: version ?? widget.package.latestVersion,
        packageName: result.packageName,
        launchCommand: result.launchCommand,
        lastChecked: DateTime.now(),
      );
      await db.updateDebPackage(updatedPkg);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Installation successful'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Installation failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isInstalling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, size: 48, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg.effectiveDisplayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      pkg.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow('URL', pkg.packageUrl),
          _buildInfoRow('Installed Version', pkg.installedVersion ?? 'Not installed'),
          _buildInfoRow('Latest Version', pkg.latestVersion ?? 'Unknown'),
          if (pkg.lastChecked != null)
            _buildInfoRow('Last Checked', pkg.lastChecked!.toLocal().toString().split('.').first),
          
          const SizedBox(height: 32),
          Row(
            children: [
              if (pkg.installedVersion != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUninstalling ? null : _uninstall,
                    icon: _isUninstalling 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.delete_outline),
                    label: const Text('Uninstall'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _launch,
                    icon: const Icon(Icons.launch),
                    label: const Text('Launch'),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isInstalling ? null : _installUpdate,
                    icon: _isInstalling 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download),
                    label: const Text('Install'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (pkg.hasUpdate && pkg.installedVersion != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isInstalling ? null : _installUpdate,
                icon: const Icon(Icons.update),
                label: const Text('Update to Latest'),
                style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _uninstall() async {
    setState(() => _isUninstalling = true);
    try {
      final installer = context.read<InstallerService>();
      final db = context.read<DatabaseService>();
      
      await installer.uninstallDebPackage(widget.package);
      
      final updatedPkg = widget.package.copyWith(installedVersion: null);
      await db.updateDebPackage(updatedPkg);
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uninstallation failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUninstalling = false);
    }
  }

  Future<void> _launch() async {
    try {
      final installer = context.read<InstallerService>();
      await installer.launchDebPackage(widget.package);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Launch failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _installUpdate() async {
    setState(() => _isInstalling = true);
    try {
      final installer = context.read<InstallerService>();
      final db = context.read<DatabaseService>();
      
      final filename = widget.package.name.endsWith('.deb') ? widget.package.name : '${widget.package.name}.deb';
      final file = await installer.downloadFile(widget.package.packageUrl, filename);
      
      final result = await installer.installPackage(file, InstallType.deb);
      
      final version = TrackedDebPackage.extractVersionFromFilename(file.path.split('/').last);

      final updatedPkg = widget.package.copyWith(
        installedVersion: version ?? widget.package.latestVersion,
        packageName: result.packageName,
        launchCommand: result.launchCommand,
        lastChecked: DateTime.now(),
      );
      await db.updateDebPackage(updatedPkg);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Installation successful'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Installation failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isInstalling = false);
    }
  }
}
