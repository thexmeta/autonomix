import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/release.dart';
import '../utils/glob_pattern.dart';
import 'settings_service.dart';

class GitHubService {
  static const String _baseUrl = 'https://api.github.com';
  static const String _userAgent = 'Autonomix/0.3.4';
  
  final SettingsService? _settingsService;
  
  GitHubService({SettingsService? settingsService}) : _settingsService = settingsService;

  Future<String?> _getGithubToken() async {
    if (_settingsService != null) {
      return await _settingsService!.getGithubToken();
    }
    return null;
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = {'User-Agent': _userAgent};
    final token = await _getGithubToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Release?> getLatestRelease(
    String owner,
    String repo, {
    String? assetFilterPattern,
    String? tagPrefix,
    List<String>? architectures,
    bool includePrerelease = false,
  }) async {
    final releases = await getReleases(owner, repo);

    final filteredReleases = releases.where((release) {
      if (!includePrerelease && release.prerelease) {
        return false;
      }
      if (tagPrefix != null && tagPrefix.isNotEmpty) {
        if (!release.tagName.startsWith(tagPrefix)) {
          return false;
        }
      }
      return true;
    }).toList();

    for (var release in filteredReleases) {
      final filteredAssets = filterAssets(
        release,
        assetFilterPattern: assetFilterPattern,
        architectures: architectures,
      );

      if (filteredAssets.isNotEmpty) {
        return release.copyWith(assets: filteredAssets);
      }
    }

    return null;
  }

  Future<Map<String, dynamic>?> getLatestReleaseWithPackageInfo(
    String owner,
    String repo, {
    String? assetFilterPattern,
    String? tagPrefix,
    List<String>? architectures,
    bool includePrerelease = false,
  }) async {
    final release = await getLatestRelease(
      owner,
      repo,
      assetFilterPattern: assetFilterPattern,
      tagPrefix: tagPrefix,
      architectures: architectures,
      includePrerelease: includePrerelease,
    );

    if (release == null) return null;

    // Find the best matching asset
    ReleaseAsset? bestAsset;
    for (var asset in release.assets) {
      if (architectures != null && architectures.isNotEmpty) {
        for (var arch in architectures) {
          if (matchesArchitecture(asset.name, arch)) {
            bestAsset = asset;
            break;
          }
        }
      } else {
        bestAsset = asset;
        break;
      }
      if (bestAsset != null) break;
    }

    if (bestAsset == null && release.assets.isNotEmpty) {
      bestAsset = release.assets.first;
    }

    return {
      'release': release,
      'packageName': bestAsset?.name,
      'downloadUrl': bestAsset?.browserDownloadUrl,
      'releaseDate': release.publishedAt?.toIso8601String(),
    };
  }

  Future<List<Release>> getReleases(String owner, String repo, {int? perPage}) async {
    final releasesPerPage = perPage ?? await _getReleasesPerPage();
    final url = Uri.parse('$_baseUrl/repos/$owner/$repo/releases?per_page=$releasesPerPage');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Release.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load releases: ${response.statusCode}');
    }
  }

  Future<int> _getReleasesPerPage() async {
    if (_settingsService != null) {
      return await _settingsService!.getEffectiveReleasesPerPage();
    }
    return 100; // Default
  }

  Future<Map<String, dynamic>> getRepository(String owner, String repo) async {
    final url = Uri.parse('$_baseUrl/repos/$owner/$repo');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load repository: ${response.statusCode}');
    }
  }

  List<ReleaseAsset> filterAssets(
    Release release, {
    String? assetFilterPattern,
    List<String>? architectures,
  }) {
    final assets = release.assets;

    return assets.where((asset) {
      final name = asset.name;

      if (assetFilterPattern != null && assetFilterPattern.isNotEmpty) {
        if (!matchesGlobPattern(name, assetFilterPattern)) {
          return false;
        }
      }

      if (architectures != null && architectures.isNotEmpty) {
        final hasMatchingArch = architectures.any((arch) =>
          matchesArchitecture(name, arch)
        );
        if (!hasMatchingArch) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
