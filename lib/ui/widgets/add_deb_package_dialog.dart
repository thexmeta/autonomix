import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/tracked_deb_package.dart';

/// Dialog for adding a new Debian package from URL
class AddDebPackageDialog extends StatefulWidget {
  const AddDebPackageDialog({super.key});

  @override
  State<AddDebPackageDialog> createState() => _AddDebPackageDialogState();
}

class _AddDebPackageDialogState extends State<AddDebPackageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isValidating = false;
  String? _validationError;
  bool _autoUpdate = false;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _validateUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        setState(() {
          _validationError = 'Invalid URL scheme';
          _isValidating = false;
        });
        return;
      }

      // Extract filename from URL
      final filename = uri.path.split('/').last;
      if (filename.isEmpty) {
        setState(() {
          _validationError = 'Could not extract filename from URL';
          _isValidating = false;
        });
        return;
      }

      // Try to extract version from filename
      TrackedDebPackage.extractVersionFromFilename(filename);
      
      setState(() {
        _isValidating = false;
      });

      // Set name from filename if not already set
      if (_nameController.text.trim().isEmpty) {
        final displayName = filename.replaceAll(RegExp(r'\.deb$'), '');
        _nameController.text = displayName;
      }
    } catch (e) {
      setState(() {
        _validationError = 'Invalid URL format';
        _isValidating = false;
      });
    }
  }

  Future<void> _testUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      // Try to launch the URL (this will typically just check if it's accessible)
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('URL is accessible')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('URL may not be accessible')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error testing URL: $e')),
        );
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final url = _urlController.text.trim();
    final name = _nameController.text.trim();

    if (url.isEmpty || name.isEmpty) return;

    Navigator.pop(context, {
      'name': name,
      'packageUrl': url,
      'autoUpdate': _autoUpdate,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.download),
          SizedBox(width: 8),
          Text('Add Debian Package'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Package URL field
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Package URL',
                  hintText: 'https://example.com/package.deb',
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: _isValidating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        onPressed: _isValidating ? null : _validateUrl,
                        tooltip: 'Validate URL',
                      ),
                      IconButton(
                        icon: const Icon(Icons.science),
                        onPressed: _testUrl,
                        tooltip: 'Test URL',
                      ),
                    ],
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!v.startsWith('http://') && !v.startsWith('https://')) {
                    return 'Must start with http:// or https://';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              if (_validationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _validationError!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 16),

              // Display name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Auto-update toggle
              SwitchListTile(
                title: const Text('Auto-update'),
                subtitle: const Text('Automatically check for updates'),
                value: _autoUpdate,
                onChanged: (value) {
                  setState(() {
                    _autoUpdate = value;
                  });
                },
                secondary: const Icon(Icons.autorenew),
              ),

              // Example URLs
              const SizedBox(height: 16),
              const Text(
                'Example URLs:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _ExampleUrlItem(
                url:
                    'https://app.warp.dev/get_warp?package=deb&channel=preview',
                onTap: () => _urlController.text =
                    'https://app.warp.dev/get_warp?package=deb&channel=preview',
              ),
              _ExampleUrlItem(
                url: 'https://greenfishsoftware.org/dl.php?filename=gfie-4.5.deb',
                onTap: () => _urlController.text =
                    'https://greenfishsoftware.org/dl.php?filename=gfie-4.5.deb',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add Package'),
        ),
      ],
    );
  }
}

class _ExampleUrlItem extends StatelessWidget {
  final String url;
  final VoidCallback onTap;

  const _ExampleUrlItem({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        child: Text(
          url,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 12,
            decoration: TextDecoration.underline,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
