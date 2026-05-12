import 'package:flutter/material.dart';
import '../../models/tracked_deb_package.dart';
import 'package:url_launcher/url_launcher.dart';

class DebPackageListItem extends StatelessWidget {
  final TrackedDebPackage package;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUpdate;
  final bool isSelected;

  const DebPackageListItem({
    super.key,
    required this.package,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onUpdate,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasUpdate = package.hasUpdate;
    
    return ListTile(
      leading: isSelected
          ? Checkbox(
              value: true,
              onChanged: (value) => onTap(),
            )
          : null,
      title: Row(
        children: [
          Expanded(
            child: Text(
              package.effectiveDisplayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hasUpdate
                    ? Colors.orange.shade700
                    : (isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.link, size: 16),
            onPressed: () => _openPackageUrl(context),
            tooltip: 'Open direct download URL',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(package.packageUrl, 
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          // Installed version
          if (package.installedVersion != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.install_desktop, size: 14, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Installed: ${package.installedVersion}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          // Latest version
          if (package.latestVersion != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.new_releases, size: 14, color: hasUpdate ? Colors.orange[600] : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Latest: ${package.latestVersion}',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasUpdate ? Colors.orange[600] : Colors.grey[600],
                      fontWeight: hasUpdate ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
          if (package.fileSize != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.storage, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Size: ${package.fileSize}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'DIRECT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Update button for individual package
          if (hasUpdate)
            IconButton(
              icon: const Icon(Icons.system_update, size: 20),
              onPressed: onUpdate,
              tooltip: 'Update this package',
              color: Colors.orange.shade700,
            ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
              tooltip: 'Edit package',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
            tooltip: 'Remove from list',
          ),
          const SizedBox(width: 8),
          if (package.installedVersion != null)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            const Icon(Icons.circle_outlined, color: Colors.grey),
        ],
      ),
      onTap: onTap,
      selected: isSelected,
    );
  }

  Future<void> _openPackageUrl(BuildContext context) async {
    final uri = Uri.parse(package.packageUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open URL: $e')),
        );
      }
    }
  }
}
