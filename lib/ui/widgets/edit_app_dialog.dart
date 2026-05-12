import 'package:flutter/material.dart';
import '../../models/tracked_app.dart';
import '../../services/github_service.dart';
import 'filter_preview.dart';

class EditAppDialog extends StatefulWidget {
  final TrackedApp app;

  const EditAppDialog({super.key, required this.app});

  @override
  State<EditAppDialog> createState() => _EditAppDialogState();
}

class _EditAppDialogState extends State<EditAppDialog> {
  late TextEditingController _nameController;
  late TextEditingController _ownerController;
  late TextEditingController _repoController;
  late TextEditingController _assetFilterController;
  late TextEditingController _tagPrefixController;
  late TextEditingController _architecturesController;
  late TextEditingController _launchCommandController;
  late TextEditingController _packageNameController;
  bool _includePrerelease = false;
  bool _showPreview = false;
  bool _isFetching = false;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.app.displayName);
    _ownerController = TextEditingController(text: widget.app.repoOwner);
    _repoController = TextEditingController(text: widget.app.repoName);
    _assetFilterController = TextEditingController(text: widget.app.assetFilterPattern ?? '');
    _tagPrefixController = TextEditingController(text: widget.app.tagPrefix ?? '');
    _architecturesController = TextEditingController(
      text: widget.app.architectures.join(', '),
    );
    _launchCommandController = TextEditingController(text: widget.app.launchCommand ?? '');
    _packageNameController = TextEditingController(text: widget.app.packageName ?? '');
    _includePrerelease = widget.app.includePrerelease;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _repoController.dispose();
    _assetFilterController.dispose();
    _tagPrefixController.dispose();
    _architecturesController.dispose();
    _launchCommandController.dispose();
    _packageNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    final owner = _ownerController.text.trim();
    final repo = _repoController.text.trim();
    
    if (owner.isEmpty || repo.isEmpty) {
      setState(() {
        _fetchError = 'Owner and repo are required';
      });
      return;
    }

    setState(() {
      _isFetching = true;
      _fetchError = null;
    });

    try {
      final gh = GitHubService();
      final info = await gh.getRepository(owner, repo);

      setState(() {
        _nameController.text = info['description'] ?? info['name'];
        _isFetching = false;
      });
    } catch (e) {
      setState(() {
        _fetchError = e.toString();
        _isFetching = false;
      });
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _ownerController.text.trim().isEmpty ||
        _repoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final architectures = _architecturesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final updatedApp = widget.app.copyWith(
        displayName: _nameController.text.trim(),
        repoOwner: _ownerController.text.trim(),
        repoName: _repoController.text.trim(),
        assetFilterPattern: _assetFilterController.text.isEmpty ? null : _assetFilterController.text,
        tagPrefix: _tagPrefixController.text.isEmpty ? null : _tagPrefixController.text,
        architectures: architectures,
        includePrerelease: _includePrerelease,
        launchCommand: _launchCommandController.text.trim().isEmpty ? null : _launchCommandController.text.trim(),
        packageName: _packageNameController.text.trim().isEmpty ? null : _packageNameController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, updatedApp);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error preparing app update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Tracked App'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ownerController,
              decoration: const InputDecoration(
                labelText: 'Repository Owner',
                hintText: 'e.g., flutter',
                prefixText: 'https://github.com/',
                suffixText: '/repo-name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _repoController,
              decoration: const InputDecoration(
                labelText: 'Repository Name',
                hintText: 'e.g., flutter',
              ),
            ),
            const SizedBox(height: 16),
            // Asset Filter Pattern - Always visible
            TextField(
              controller: _assetFilterController,
              decoration: const InputDecoration(
                labelText: 'Asset Filter Pattern',
                hintText: '*.deb, *amd64*, *linux*',
                helperText: 'Filter release assets by filename (e.g., *.deb)',
                prefixIcon: Icon(Icons.filter_alt),
              ),
            ),
            const SizedBox(height: 16),
            // Tag Prefix
            TextField(
              controller: _tagPrefixController,
              decoration: const InputDecoration(
                labelText: 'Tag Prefix',
                hintText: 'v, release-, app-v',
                helperText: 'Only consider releases with this tag prefix',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _architecturesController,
              decoration: const InputDecoration(
                labelText: 'Architectures',
                hintText: 'e.g., x64, arm64 (comma-separated)',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Include Pre-releases'),
              subtitle: const Text('Check for pre-release versions'),
              value: _includePrerelease,
              onChanged: (value) {
                setState(() => _includePrerelease = value);
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text('System Detection (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _launchCommandController,
              decoration: const InputDecoration(
                labelText: 'Custom Binary/Launch Command',
                hintText: 'e.g., code, discord, br',
                helperText: 'Command name to check with "which"',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _packageNameController,
              decoration: const InputDecoration(
                labelText: 'Custom Package Name',
                hintText: 'e.g., code-insiders, discord-canary',
                helperText: 'Package name to check with "dpkg"',
              ),
            ),
            const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() => _showPreview = !_showPreview);
              },
              icon: Icon(_showPreview ? Icons.visibility_off : Icons.visibility),
              label: Text(_showPreview ? 'Hide Preview' : 'Show Preview'),
            ),
            IconButton(
              icon: _isFetching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isFetching ? null : _fetchDetails,
              tooltip: 'Fetch repository details',
            ),
          ],
        ),
        if (_fetchError != null)
          Text(
            _fetchError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
            if (_showPreview)
              FilterPreview(
                owner: _ownerController.text.trim(),
                repo: _repoController.text.trim(),
                assetFilterPattern: _assetFilterController.text.isEmpty ? null : _assetFilterController.text,
                tagPrefix: _tagPrefixController.text.isEmpty ? null : _tagPrefixController.text,
                architectures: _architecturesController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
                includePrerelease: _includePrerelease,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
