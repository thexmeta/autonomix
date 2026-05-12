/// Represents a tracked Debian package from a direct URL
/// Used for tracking packages that are not from GitHub releases
class TrackedDebPackage {
  final int? id;
  final String name;
  final String packageUrl;
  final String? displayName;
  final String? installedVersion;
  final String? latestVersion;
  final String? fileSize;
  final DateTime? fileDate;
  final DateTime? lastChecked;
  final DateTime createdAt;
  final String? checksum;
  final bool autoUpdate;
  final String? packageName;
  final String? launchCommand;

  TrackedDebPackage({
    this.id,
    required this.name,
    required this.packageUrl,
    this.displayName,
    this.installedVersion,
    this.latestVersion,
    this.fileSize,
    this.fileDate,
    this.lastChecked,
    required this.createdAt,
    this.checksum,
    this.autoUpdate = false,
    this.packageName,
    this.launchCommand,
  });

  /// Extract version from filename (e.g., "app_1.2.3_amd64.deb" -> "1.2.3")
  static String? extractVersionFromFilename(String filename) {
    final match = RegExp(r'[_-]([0-9]+(?:\.[0-9]+)*(?:-[a-zA-Z0-9]+)?)').firstMatch(filename);
    return match?.group(1);
  }

  /// Get filename from URL
  String get filename {
    try {
      final uri = Uri.parse(packageUrl);
      final path = uri.path;
      return path.split('/').last;
    } catch (_) {
      return '';
    }
  }

  /// Check if package has update available
  bool get hasUpdate {
    if (installedVersion == null || latestVersion == null) return false;
    return latestVersion != installedVersion;
  }

  /// Get display name or fallback to filename
  String get effectiveDisplayName => displayName ?? name;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'package_url': packageUrl,
      'display_name': displayName,
      'installed_version': installedVersion,
      'latest_version': latestVersion,
      'file_size': fileSize,
      'file_date': fileDate?.toIso8601String(),
      'last_checked': lastChecked?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'checksum': checksum,
      'auto_update': autoUpdate,
      'package_name': packageName,
      'launch_command': launchCommand,
    };
  }

  factory TrackedDebPackage.fromMap(Map<String, dynamic> map) {
    return TrackedDebPackage(
      id: map['id'] as int?,
      name: map['name'] as String,
      packageUrl: map['package_url'] as String,
      displayName: map['display_name'] as String?,
      installedVersion: map['installed_version'] as String?,
      latestVersion: map['latest_version'] as String?,
      fileSize: map['file_size'] as String?,
      fileDate: map['file_date'] != null
          ? (map['file_date'] is DateTime
              ? map['file_date']
              : DateTime.parse(map['file_date'] as String))
          : null,
      lastChecked: map['last_checked'] != null
          ? (map['last_checked'] is DateTime
              ? map['last_checked']
              : DateTime.parse(map['last_checked'] as String))
          : null,
      createdAt: map['created_at'] is DateTime
          ? map['created_at']
          : DateTime.parse(map['created_at'] as String),
      checksum: map['checksum'] as String?,
      autoUpdate: map['auto_update'] as bool? ?? false,
      packageName: map['package_name'] as String?,
      launchCommand: map['launch_command'] as String?,
    );
  }

  TrackedDebPackage copyWith({
    int? id,
    String? name,
    String? packageUrl,
    String? displayName,
    String? installedVersion,
    String? latestVersion,
    String? fileSize,
    DateTime? fileDate,
    DateTime? lastChecked,
    DateTime? createdAt,
    String? checksum,
    bool? autoUpdate,
    String? packageName,
    String? launchCommand,
  }) {
    return TrackedDebPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      packageUrl: packageUrl ?? this.packageUrl,
      displayName: displayName ?? this.displayName,
      installedVersion: installedVersion ?? this.installedVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      fileSize: fileSize ?? this.fileSize,
      fileDate: fileDate ?? this.fileDate,
      lastChecked: lastChecked ?? this.lastChecked,
      createdAt: createdAt ?? this.createdAt,
      checksum: checksum ?? this.checksum,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      packageName: packageName ?? this.packageName,
      launchCommand: launchCommand ?? this.launchCommand,
    );
  }
}
