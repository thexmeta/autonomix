import 'package:flutter/material.dart';
import '../../models/tracked_deb_package.dart';

class EditDebPackageDialog extends StatefulWidget {
  final TrackedDebPackage package;

  const EditDebPackageDialog({super.key, required this.package});

  @override
  State<EditDebPackageDialog> createState() => _EditDebPackageDialogState();
}

class _EditDebPackageDialogState extends State<EditDebPackageDialog> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _displayNameController;
  bool _autoUpdate = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.package.name);
    _urlController = TextEditingController(text: widget.package.packageUrl);
    _displayNameController = TextEditingController(text: widget.package.displayName ?? '');
    _autoUpdate = widget.package.autoUpdate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Deb Package'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Internal Name (Package ID)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'Package URL'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Auto Update Check'),
              value: _autoUpdate,
              onChanged: (v) => setState(() => _autoUpdate = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final updated = widget.package.copyWith(
              name: _nameController.text,
              displayName: _displayNameController.text.isEmpty ? null : _displayNameController.text,
              packageUrl: _urlController.text,
              autoUpdate: _autoUpdate,
            );
            Navigator.of(context).pop(updated);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
