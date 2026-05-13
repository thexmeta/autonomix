import 'install_type.dart';

class TrackedApp {
  final int? id;
  final String repoOwner;
  final String repoName;
  final String displayName;
  final String? installedVersion;
  final String? latestVersion;
  final InstallType? installType;
  final String? launchCommand;
  final String? packageName;
  final DateTime? lastChecked;
  final DateTime createdAt;
  final DateTime? latestReleaseDate;
  final String? fetchedPackage;

  // Advanced filtering fields
  final String? assetFilterPattern;
  final String? tagPrefix;
  final List<String> architectures;
  final bool includePrerelease;

  TrackedApp({
    this.id,
    required this.repoOwner,
    required this.repoName,
    required this.displayName,
    this.installedVersion,
    this.latestVersion,
    this.installType,
    this.launchCommand,
    this.packageName,
    this.lastChecked,
    required this.createdAt,
    this.latestReleaseDate,
    this.fetchedPackage,
    this.assetFilterPattern,
    this.tagPrefix,
    List<String>? architectures,
    this.includePrerelease = false,
  }) : architectures = architectures ?? [];

  String get repoUrl => 'https://github.com/$repoOwner/$repoName';

  bool get hasUpdate {
    if (installedVersion == null || latestVersion == null) return false;
    final installed = _normalizeVersion(installedVersion!);
    final latest = _normalizeVersion(latestVersion!);
    if (installed == latest) return false;
    return _isNewerVersion(latest, installed);
  }

  bool get isInstalled => installedVersion != null;

  static String _normalizeVersion(String version) {
    var v = version.trim();
    if (v.startsWith('v') || v.startsWith('V')) {
      v = v.substring(1);
    }
    return v.toLowerCase();
  }

  static bool _isNewerVersion(String newVersion, String oldVersion) {
    try {
      final newParts = _parseVersion(newVersion);
      final oldParts = _parseVersion(oldVersion);
      
      for (var i = 0; i < 3; i++) {
        if (newParts[i] > oldParts[i]) return true;
        if (newParts[i] < oldParts[i]) return false;
      }
      
      // If major.minor.patch are equal, check if one is a prerelease
      // A release version (no dash) is newer than a prerelease (has dash)
      final newIsPrerelease = newVersion.contains('-');
      final oldIsPrerelease = oldVersion.contains('-');
      
      if (!newIsPrerelease && oldIsPrerelease) return true;
      if (newIsPrerelease && !oldIsPrerelease) return false;
      
      // If both are prereleases, fallback to string comparison for the suffix
      return newVersion.compareTo(oldVersion) > 0;
    } catch (e) {
      // Fallback to lexicographical if parsing fails
      return newVersion.compareTo(oldVersion) > 0;
    }
  }

  static List<int> _parseVersion(String version) {
    // Remove v-prefix and any prerelease suffix for number parsing
    final clean = version.split('-').first.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = clean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts.sublist(0, 3);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'repo_owner': repoOwner,
      'repo_name': repoName,
      'display_name': displayName,
      'installed_version': installedVersion,
      'latest_version': latestVersion,
      'install_type': installType?.name,
      'launch_command': launchCommand,
      'package_name': packageName,
      'last_checked': lastChecked?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'latest_release_date': latestReleaseDate?.toIso8601String(),
      'fetched_package': fetchedPackage,
      'asset_filter_pattern': assetFilterPattern,
      'tag_prefix': tagPrefix,
      'architectures': architectures,
      'include_prerelease': includePrerelease,
    };
  }

  factory TrackedApp.fromMap(Map<String, dynamic> map) {
    return TrackedApp(
      id: map['id'] as int?,
      repoOwner: map['repo_owner'] as String,
      repoName: map['repo_name'] as String,
      displayName: map['display_name'] as String,
      installedVersion: (map['installed_version'] as String?)?.trim().isEmpty ?? true ? null : map['installed_version'] as String,
      latestVersion: (map['latest_version'] as String?)?.trim().isEmpty ?? true ? null : map['latest_version'] as String,
      installType: InstallType.fromString(map['install_type'] as String?),
      launchCommand: map['launch_command'] as String?,
      packageName: map['package_name'] as String?,
      lastChecked: map['last_checked'] != null ? DateTime.parse(map['last_checked'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      latestReleaseDate: map['latest_release_date'] != null ? DateTime.parse(map['latest_release_date'] as String) : null,
      fetchedPackage: map['fetched_package'] as String?,
      assetFilterPattern: map['asset_filter_pattern'] as String?,
      tagPrefix: map['tag_prefix'] as String?,
      architectures: map['architectures'] != null
          ? List<String>.from(map['architectures'] as List)
          : [],
      includePrerelease: map['include_prerelease'] as bool? ?? false,
    );
  }

  static const _sentinel = Object();

  TrackedApp copyWith({
    int? id,
    String? repoOwner,
    String? repoName,
    String? displayName,
    Object? installedVersion = _sentinel,
    Object? latestVersion = _sentinel,
    InstallType? installType,
    String? launchCommand,
    String? packageName,
    DateTime? lastChecked,
    DateTime? createdAt,
    DateTime? latestReleaseDate,
    String? fetchedPackage,
    String? assetFilterPattern,
    String? tagPrefix,
    List<String>? architectures,
    bool? includePrerelease,
  }) {
    return TrackedApp(
      id: id ?? this.id,
      repoOwner: repoOwner ?? this.repoOwner,
      repoName: repoName ?? this.repoName,
      displayName: displayName ?? this.displayName,
      installedVersion: installedVersion == _sentinel ? this.installedVersion : (installedVersion as String?),
      latestVersion: latestVersion == _sentinel ? this.latestVersion : (latestVersion as String?),
      installType: installType ?? this.installType,
      launchCommand: launchCommand ?? this.launchCommand,
      packageName: packageName ?? this.packageName,
      lastChecked: lastChecked ?? this.lastChecked,
      createdAt: createdAt ?? this.createdAt,
      latestReleaseDate: latestReleaseDate ?? this.latestReleaseDate,
      fetchedPackage: fetchedPackage ?? this.fetchedPackage,
      assetFilterPattern: assetFilterPattern ?? this.assetFilterPattern,
      tagPrefix: tagPrefix ?? this.tagPrefix,
      architectures: architectures ?? this.architectures,
      includePrerelease: includePrerelease ?? this.includePrerelease,
    );
  }

  /// Validates the asset filter pattern (glob pattern)
  static bool isValidFilterPattern(String? pattern) {
    if (pattern == null || pattern.isEmpty) return true;
    // Basic validation - should contain at least one wildcard or extension
    return pattern.contains('*') || pattern.contains('?') || pattern.contains('.');
  }

  /// Validates the tag prefix
  static bool isValidTagPrefix(String? prefix) {
    if (prefix == null || prefix.isEmpty) return true;
    // Tag prefix should not contain special characters
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(prefix);
  }

  /// Validates all filter settings
  static String? validateFilterSettings({
    String? assetFilterPattern,
    String? tagPrefix,
    List<String>? architectures,
  }) {
    if (assetFilterPattern != null && 
        assetFilterPattern.isNotEmpty && 
        !isValidFilterPattern(assetFilterPattern)) {
      return 'Invalid asset filter pattern. Use wildcards like * or ?';
    }
    
    if (tagPrefix != null && !isValidTagPrefix(tagPrefix)) {
      return 'Invalid tag prefix. Use only alphanumeric characters, hyphens, and underscores.';
    }
    
    return null;
  }
}
