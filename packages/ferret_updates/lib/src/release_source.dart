import 'dart:io';

import 'package:ferret_updates/src/release_version.dart';
import 'package:ferret_updates/src/update_asset.dart';
import 'package:ferret_updates/src/update_http.dart';
import 'package:ferret_updates/src/update_release.dart';
import 'package:path/path.dart' as p;

/// Where releases come from.
abstract interface class ReleaseSource {
  /// The newest release, or null when there is none yet. Test versions
  /// count only with [includePreReleases].
  Future<UpdateRelease?> newest({required bool includePreReleases});
}

/// Ferret's releases on GitHub. Asks `api.github.com` for the latest
/// release (or the last few, to include test versions) and nothing else.
class GithubReleaseSource implements ReleaseSource {
  GithubReleaseSource({
    UpdateHttp? http,
    this.repository = defaultRepository,
    Uri? api,
  }) : _http = http ?? UpdateHttp(),
       _api = api ?? Uri.https('api.github.com');

  static const defaultRepository = 'simonpham/ferret';

  /// `owner/name` on GitHub.
  final String repository;
  final UpdateHttp _http;
  final Uri _api;

  Uri get _releases => _api.replace(path: '/repos/$repository/releases');

  @override
  Future<UpdateRelease?> newest({required bool includePreReleases}) async {
    if (!includePreReleases) {
      final json = await _http.getJson(
        _releases.replace(path: '${_releases.path}/latest'),
      );
      return switch (json) {
        final Map<String, Object?> release => UpdateRelease.fromJson(release),
        _ => null,
      };
    }

    final json = await _http.getJson(
      _releases.replace(queryParameters: {'per_page': '20'}),
    );
    return switch (json) {
      final List<Object?> list => newestOf([
        for (final entry in list)
          if (entry case final Map<String, Object?> release)
            UpdateRelease.fromJson(release),
      ]),
      _ => null,
    };
  }

  /// The release with the highest version that isn't a draft.
  static UpdateRelease? newestOf(List<UpdateRelease> releases) {
    UpdateRelease? best;
    ReleaseVersion? bestVersion;
    for (final release in releases) {
      final version = release.version;
      if (release.draft || version == null) {
        continue;
      }

      if (bestVersion == null || version > bestVersion) {
        best = release;
        bestVersion = version;
      }
    }

    return best;
  }
}

/// A release laid out by hand, for trying an update before one is
/// published: a folder (or a web server) with `release.json` and the files.
///
/// `release.json` holds GitHub's fields that matter: `tag_name`, `body`,
/// `prerelease`, and optionally `assets` as a list of file names. Without
/// `assets`, a folder's files are the release's files.
class FeedReleaseSource implements ReleaseSource {
  FeedReleaseSource(this.base, {UpdateHttp? http})
    : _http = http ?? UpdateHttp(allowInsecure: true);

  /// Reads a feed from FERRET_UPDATE_FEED: a folder path or an `http(s)`
  /// URL. Null when it isn't set.
  static FeedReleaseSource? fromEnvironment([
    Map<String, String>? environment,
  ]) {
    final value =
        (environment ?? Platform.environment)['FERRET_UPDATE_FEED'] ??
        const String.fromEnvironment('FERRET_UPDATE_FEED');
    if (value.isEmpty) {
      return null;
    }

    final url = Uri.tryParse(value);
    if (url != null && (url.scheme == 'http' || url.scheme == 'https')) {
      return FeedReleaseSource(_asFolder(url));
    }

    return FeedReleaseSource(Directory(value).absolute.uri);
  }

  /// Ends with a slash, so names resolve inside it.
  final Uri base;
  final UpdateHttp _http;

  @override
  Future<UpdateRelease?> newest({required bool includePreReleases}) async {
    final json = await _http.getJson(base.resolve('release.json'));
    if (json is! Map<String, Object?>) {
      return null;
    }

    final names = switch (json['assets']) {
      final List<Object?> list => [
        for (final name in list)
          if (name case final String name) name,
      ],
      _ => await _filesInFolder(),
    };
    final release = UpdateRelease.fromJson({...json, 'assets': null});
    if (release.preRelease && !includePreReleases) {
      return null;
    }

    return UpdateRelease(
      tag: release.tag,
      notes: release.notes,
      preRelease: release.preRelease,
      pageUrl: base,
      assets: [
        for (final name in names)
          UpdateAsset(
            name: name,
            downloadUrl: base.resolve(Uri.encodeComponent(name)),
          ),
      ],
    );
  }

  Future<List<String>> _filesInFolder() async {
    if (base.scheme != 'file') {
      return const [];
    }

    final folder = Directory.fromUri(base);
    return [
      await for (final entity in folder.list())
        if (entity is File && p.basename(entity.path) != 'release.json')
          p.basename(entity.path),
    ];
  }

  static Uri _asFolder(Uri url) => switch (url.path.endsWith('/')) {
    true => url,
    false => url.replace(path: '${url.path}/'),
  };
}
