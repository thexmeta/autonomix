import 'package:flutter/material.dart';
import '../models/tracked_app.dart';

/// Batch Action Bar - displayed when multi-select mode is active
/// Provides bulk operations for selected apps
class BatchActionBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onUpdateAll;
  final VoidCallback onInstallAll;
  final VoidCallback onDeleteAll;

  const BatchActionBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onUpdateAll,
    required this.onInstallAll,
    required this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Selection info
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$selectedCount of $totalCount selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (selectedCount > 0)
                  Text(
                    'Ready for batch operation',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),

          // Select All / Deselect All
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: onSelectAll,
            tooltip: selectedCount == totalCount
                ? 'Deselect All'
                : 'Select All',
          ),

          // Update Selected
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: selectedCount > 0 ? onUpdateAll : null,
            tooltip: 'Update Selected Apps',
          ),

          // Install Selected
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: selectedCount > 0 ? onInstallAll : null,
            tooltip: 'Install Selected Apps',
          ),

          // Delete Selected
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: selectedCount > 0 ? onDeleteAll : null,
            tooltip: 'Delete Selected Apps',
          ),
        ],
      ),
    );
  }
}
