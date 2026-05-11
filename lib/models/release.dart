class Release {
  final String tagName;
  final String? name;
  final String? body;
  final DateTime? publishedAt;
  final bool prerelease;
  final bool draft;
  final List<ReleaseAsset> assets;

  Release({
    required this.tagName,
    this.name,
    this.body,
    this.publishedAt,
    required this.prerelease,
    required this.draft,
    required this.assets,
  });

  Release copyWith({
    String? tagName,
    String? name,
    String? body,
    DateTime? publishedAt,
    bool? prerelease,
    bool? draft,
    List<ReleaseAsset>? assets,
  }) {
    return Release(
      tagName: tagName ?? this.tagName,
      name: name ?? this.name,
      body: body ?? this.body,
      publishedAt: publishedAt ?? this.publishedAt,
      prerelease: prerelease ?? this.prerelease,
      draft: draft ?? this.draft,
      assets: assets ?? this.assets,
    );
  }

  factory Release.fromJson(Map<String, dynamic> json) {
    return Release(
      tagName: json['tag_name'] as String,
      name: json['name'] as String?,
      body: json['body'] as String?,
      publishedAt: json['published_at'] != null 
          ? DateTime.parse(json['published_at'] as String) 
          : null,
      prerelease: json['prerelease'] as bool? ?? false,
      draft: json['draft'] as bool? ?? false,
      assets: (json['assets'] as List<dynamic>?)
          ?.map((e) => ReleaseAsset.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class ReleaseAsset {
  final String name;
  final String browserDownloadUrl;
  final String contentType;
  final int size;

  ReleaseAsset({
    required this.name,
    required this.browserDownloadUrl,
    required this.contentType,
    required this.size,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String,
      browserDownloadUrl: json['browser_download_url'] as String,
      contentType: json['content_type'] as String,
      size: json['size'] as int,
    );
  }
}
