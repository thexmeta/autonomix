import 'package:flutter/material.dart';
import '../../models/tracked_app.dart';

class AppListItem extends StatelessWidget {
  final TrackedApp app;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUpdate;
  final bool isSelected;

  const AppListItem({
    super.key,
    required this.app,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onUpdate,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasUpdate = app.hasUpdate;
    
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
              app.displayName,
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
            icon: const Icon(Icons.open_in_new, size: 16),
            onPressed: () => _openRepoUrl(context),
            tooltip: 'Open repository on GitHub',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${app.repoOwner}/${app.repoName}'),
          // Installed version
          if (app.installedVersion != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.install_desktop, size: 14, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Installed: ${app.installedVersion}',
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
          if (app.latestVersion != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.new_releases, size: 14, color: hasUpdate ? Colors.orange[600] : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Latest: ${app.latestVersion}',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasUpdate ? Colors.orange[600] : Colors.grey[600],
                      fontWeight: hasUpdate ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
          if (app.architectures.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.architecture, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    app.architectures.join(', '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          if (app.fetchedPackage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      app.fetchedPackage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (app.latestReleaseDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Released: ${_formatDate(app.latestReleaseDate!)}',
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
          if (app.architectures.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                app.architectures.first.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          const SizedBox(width: 4),
          // Update button for individual app
          if (hasUpdate)
            IconButton(
              icon: const Icon(Icons.system_update, size: 20),
              onPressed: onUpdate,
              tooltip: 'Update this app',
              color: Colors.orange.shade700,
            ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
              tooltip: 'Edit app',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
            tooltip: 'Remove from list',
          ),
          const SizedBox(width: 8),
          if (app.isInstalled)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            const Icon(Icons.circle_outlined, color: Colors.grey),
        ],
      ),
      onTap: onTap,
      selected: isSelected,
    );
  }



  Future<void> _openRepoUrl(BuildContext context) async {
    final url = 'https://github.com/${app.repoOwner}/${app.repoName}';
    try {
      // Use launcher if available, otherwise show snackbar
      // For now, copy to clipboard
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repository: $url'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // Would use url_launcher package here
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
