import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/github_service.dart';
import '../../services/settings_service.dart';
import 'filter_preview.dart';

class AddAppDialog extends StatefulWidget {
  const AddAppDialog({super.key});

  @override
  State<AddAppDialog> createState() => _AddAppDialogState();
}

class _AddAppDialogState extends State<AddAppDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _nameController = TextEditingController();
  final _assetFilterController = TextEditingController();
  final _tagPrefixController = TextEditingController();
  bool _isFetching = false;
  bool _hasFetched = false;
  bool _showFilters = false;
  bool _includePrerelease = false;
  bool _isDirectUrl = false; // GitHub repo vs Direct package URL
  String? _error;
  final List<String> _availableArchitectures = [
    'amd64',
    'x86_64',
    'arm64',
    'aarch64',
    'arm',
    'armhf',
    'i386',
  ];
  final Set<String> _selectedArchitectures = {};

  @override
  void initState() {
    super.initState();
    _loadDefaultArchitecture();
  }

  Future<void> _loadDefaultArchitecture() async {
    final settings = context.read<SettingsService>();
    final defaultArch = await settings.getEffectiveDefaultArchitecture();
    if (mounted) {
      setState(() {
        _selectedArchitectures.add(defaultArch);
      });
    }
  }

  Future<void> _fetchDetails() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isFetching = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(url);
      
      // Check if it's a direct deb package URL
      if (uri.path.endsWith('.deb') || uri.toString().contains('/dl.php') || uri.toString().contains('package=deb')) {
        // Direct deb package URL - extract name from URL
        final filename = uri.path.split('/').last;
        final displayName = filename.isEmpty ? 'Custom Package' : filename.replaceAll('.deb', '');
        
        setState(() {
          _nameController.text = displayName;
          _hasFetched = true;
          _isFetching = false;
        });
        return;
      }
      
      // GitHub repository URL
      if (uri.host != 'github.com') {
        throw Exception('Not a GitHub URL or valid package URL');
      }

      final segments = uri.pathSegments;
      if (segments.length < 2) {
        throw Exception('Invalid repository URL');
      }

      final owner = segments[0];
      final repo = segments[1];

      final gh = context.read<GitHubService>();
      final info = await gh.getRepository(owner, repo);

      setState(() {
        _ownerController.text = info['owner']['login'];
        _repoController.text = info['name'];
        _nameController.text = info['description'] ?? info['name'];
        _hasFetched = true;
        _isFetching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isFetching = false;
      });
    }
  }

  void _toggleArchitecture(String arch) {
    setState(() {
      if (_selectedArchitectures.contains(arch)) {
        _selectedArchitectures.remove(arch);
      } else {
        _selectedArchitectures.add(arch);
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _ownerController.dispose();
    _repoController.dispose();
    _nameController.dispose();
    _assetFilterController.dispose();
    _tagPrefixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add App'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
              if (!_hasFetched) ...[
                // Mode toggle
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('GitHub Repo')),
                          ButtonSegment(value: true, label: Text('Direct URL')),
                        ],
                        selected: {_isDirectUrl},
                        onSelectionChanged: (Set<bool> selected) {
                          setState(() {
                            _isDirectUrl = selected.first;
                            _urlController.text = '';
                            _error = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // URL input
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: _isDirectUrl ? 'Package URL' : 'GitHub URL',
                          hintText: _isDirectUrl
                              ? 'https://example.com/package.deb'
                              : 'https://github.com/owner/repo',
                        ),
                        onFieldSubmitted: (_) => _fetchDetails(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isFetching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: _isFetching ? null : _fetchDetails,
                      tooltip: 'Fetch details',
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_paste),
                      onPressed: () async {
                        // TODO: Paste from clipboard
                      },
                      tooltip: 'Paste from clipboard',
                    ),
                  ],
                ),
              ],
        if (!_hasFetched && _error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (_hasFetched) ...[
          TextFormField(
            controller: _ownerController,
            decoration: const InputDecoration(labelText: 'Repo Owner'),
            validator: (v) => v?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _repoController,
            decoration: const InputDecoration(labelText: 'Repo Name'),
            validator: (v) => v?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Display Name'),
            validator: (v) => v?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          // Asset Filter Pattern - Always visible for easy access
          TextFormField(
            controller: _assetFilterController,
            decoration: const InputDecoration(
              labelText: 'Asset Filter Pattern',
              hintText: '*.deb, *amd64*, *linux*',
              helperText: 'Filter release assets by filename pattern (e.g., *.deb for Debian packages)',
              prefixIcon: Icon(Icons.filter_alt),
            ),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Advanced Filters'),
            subtitle: const Text('Tag prefix, architectures, pre-releases'),
            initiallyExpanded: _showFilters,
            onExpansionChanged: (expanded) {
              setState(() => _showFilters = expanded);
            },
            children: [
              TextFormField(
                controller: _tagPrefixController,
                decoration: const InputDecoration(
                  labelText: 'Tag Prefix',
                  hintText: 'v, release-, app-v, etc.',
                  helperText: 'Only consider releases with this tag prefix',
                ),
              ),
              const SizedBox(height: 12),
              const Text('Architectures', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableArchitectures.map((arch) {
                  final selected = _selectedArchitectures.contains(arch);
                  return FilterChip(
                    label: Text(arch),
                    selected: selected,
                    onSelected: (_) => _toggleArchitecture(arch),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Include Pre-releases'),
                subtitle: const Text('Allow beta/alpha releases'),
                value: _includePrerelease,
                onChanged: (v) {
                  setState(() => _includePrerelease = v ?? false);
                },
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter Preview - shows what package will be fetched
          FilterPreview(
            owner: _ownerController.text,
            repo: _repoController.text,
            assetFilterPattern: _assetFilterController.text.isEmpty ? null : _assetFilterController.text,
            tagPrefix: _tagPrefixController.text.isEmpty ? null : _tagPrefixController.text,
            architectures: _selectedArchitectures.toList(),
            includePrerelease: _includePrerelease,
          ),
        ],
      ],
    ),
    ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_hasFetched)
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context, {
                  'owner': _ownerController.text,
                  'repo': _repoController.text,
                  'name': _nameController.text,
                  'assetFilterPattern': _assetFilterController.text.isEmpty ? null : _assetFilterController.text,
                  'tagPrefix': _tagPrefixController.text.isEmpty ? null : _tagPrefixController.text,
                  'architectures': _selectedArchitectures.toList(),
                  'includePrerelease': _includePrerelease,
                });
              }
            },
            child: const Text('Add'),
          ),
      ],
    );
  }
}
