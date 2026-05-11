import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/github_service.dart';
import '../../models/release.dart';

class FilterPreview extends StatefulWidget {
  final String owner;
  final String repo;
  final String? assetFilterPattern;
  final String? tagPrefix;
  final List<String> architectures;
  final bool includePrerelease;

  const FilterPreview({
    super.key,
    required this.owner,
    required this.repo,
    this.assetFilterPattern,
    this.tagPrefix,
    this.architectures = const [],
    this.includePrerelease = false,
  });

  @override
  State<FilterPreview> createState() => _FilterPreviewState();
}

class _FilterPreviewState extends State<FilterPreview> {
  Release? _latestRelease;
  List<Release>? _releases;
  bool _isLoading = false;
  String? _error;
  int _debounceCount = 0;

  @override
  void initState() {
    super.initState();
    _debounceFetch();
  }

  @override
  void didUpdateWidget(FilterPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.owner != oldWidget.owner ||
        widget.repo != oldWidget.repo ||
        widget.assetFilterPattern != oldWidget.assetFilterPattern ||
        widget.tagPrefix != oldWidget.tagPrefix ||
        widget.architectures != oldWidget.architectures ||
        widget.includePrerelease != oldWidget.includePrerelease) {
      _debounceFetch();
    }
  }

  void _debounceFetch() {
    _debounceCount++;
    final currentDebounce = _debounceCount;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && currentDebounce == _debounceCount) {
        _fetchPreview();
      }
    });
  }

  Future<void> _fetchPreview() async {
    if (widget.owner.isEmpty || widget.repo.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gh = context.read<GitHubService>();
      
      // Fetch latest release with filters
      final release = await gh.getLatestRelease(
        widget.owner,
        widget.repo,
        assetFilterPattern: widget.assetFilterPattern,
        tagPrefix: widget.tagPrefix,
        architectures: widget.architectures,
        includePrerelease: widget.includePrerelease,
      );

      // Fetch recent releases for preview
      final allReleases = await gh.getReleases(widget.owner, widget.repo);
      final filteredReleases = allReleases.take(5).toList();

      if (mounted) {
        setState(() {
          _latestRelease = release;
          _releases = filteredReleases;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Filter Preview',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error: $_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          else if (_latestRelease != null)
            _buildPreviewContent()
          else
            _buildNoResults(),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    final assetCount = _latestRelease?.assets.length ?? 0;
    final archLabels = _getArchitectureLabels();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Latest release info
        Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Will fetch:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Release name
        Text(
          _latestRelease!.tagName.isNotEmpty 
            ? 'Release: ${_latestRelease!.tagName}'
            : 'Latest release',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        
        // Asset count
        Text(
          assetCount > 0
            ? '$assetCount matching asset(s)'
            : 'No matching assets',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: assetCount > 0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),

        // Architecture badges
        if (archLabels.isNotEmpty) ...[
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: archLabels.map((arch) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  arch,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Asset list (first 3)
        if (assetCount > 0) ...[
          const Text('Assets:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...(_latestRelease!.assets.take(3).map((asset) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.file_present, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      asset.name,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList()),
          if (assetCount > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... and ${assetCount - 3} more',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildNoResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning,
              size: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'No releases found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Try adjusting your filters or check if the repository has releases.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  List<String> _getArchitectureLabels() {
    final labels = <String>[];
    final assetNames = _latestRelease?.assets.map((a) => a.name).join(' ') ?? '';
    
    if (widget.architectures.any((a) => a.toLowerCase().contains('x64') || a.toLowerCase().contains('amd64'))) {
      if (assetNames.toLowerCase().contains('x64') || assetNames.toLowerCase().contains('amd64')) {
        labels.add('x64');
      }
    }
    if (widget.architectures.any((a) => a.toLowerCase().contains('arm64') || a.toLowerCase().contains('aarch64'))) {
      if (assetNames.toLowerCase().contains('arm64') || assetNames.toLowerCase().contains('aarch64')) {
        labels.add('arm64');
      }
    }
    if (widget.architectures.any((a) => a.toLowerCase().contains('arm'))) {
      if (assetNames.toLowerCase().contains('armhf') || assetNames.toLowerCase().contains('armv7')) {
        labels.add('arm');
      }
    }
    
    return labels;
  }
}
