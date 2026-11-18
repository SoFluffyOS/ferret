import 'package:media/models/models.dart';

/// Builds the link that opens a media item on this device at a position:
/// YouTube `t=`, Spotify `spotify:` URIs with `#m:ss`, Vimeo and SoundCloud
/// fragments, or the plain link for anything else on the web.
abstract final class ContinueLinks {
  static const _youTubeHosts = {
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'music.youtube.com',
    'youtu.be',
  };
  static const _spotifyTypes = {
    'track',
    'episode',
    'album',
    'playlist',
    'show',
    'artist',
  };

  /// A link for the item, or null when Ferret can't open it here. Without a
  /// [contentUri], Spotify and YouTube items fall back to a search for
  /// [title] and [artist].
  static ContinueLink? build({
    required String contentUri,
    required String appId,
    required String title,
    required String artist,
    required int positionMs,
  }) {
    final seconds = positionMs ~/ 1000;
    if (Uri.tryParse(contentUri.trim()) case final uri?
        when contentUri.trim().isNotEmpty) {
      return _fromUri(uri, seconds);
    }

    return _search(appId: appId, title: title, artist: artist);
  }

  static ContinueLink? _fromUri(Uri uri, int seconds) {
    if (uri.scheme == 'spotify') {
      return _spotify(uri.path.split(':'), seconds, webFallback: null);
    }

    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (_youTubeHosts.contains(host)) {
      return _youTube(uri, seconds);
    }

    if (host == 'open.spotify.com') {
      final segments = uri.pathSegments
          .where((segment) => !segment.startsWith('intl-'))
          .toList();
      return _spotify(
        segments,
        seconds,
        webFallback: Uri.https('open.spotify.com', uri.path),
      );
    }

    if (host == 'vimeo.com' || host.endsWith('.vimeo.com')) {
      return _withFragment(uri, 't=${seconds}s', seconds);
    }

    if (host == 'soundcloud.com' || host.endsWith('.soundcloud.com')) {
      return _withFragment(uri, 't=${_clock(seconds)}', seconds);
    }

    if (host == 'twitch.tv' || host.endsWith('.twitch.tv')) {
      return _twitch(uri, seconds);
    }

    return ContinueLink([uri], keepsPosition: false);
  }

  static ContinueLink _youTube(Uri uri, int seconds) {
    final query = {...uri.queryParameters}
      ..remove('t')
      ..remove('start');
    if (seconds > 0) {
      query['t'] = '${seconds}s';
    }

    return ContinueLink([_withQuery(uri, query)], keepsPosition: seconds > 0);
  }

  static ContinueLink? _spotify(
    List<String> parts,
    int seconds, {
    required Uri? webFallback,
  }) {
    final cleaned = [
      for (final part in parts)
        if (part.isNotEmpty) part,
    ];
    if (cleaned.length < 2 || !_spotifyTypes.contains(cleaned[0])) {
      return switch (webFallback) {
        final fallback? => ContinueLink([fallback], keepsPosition: false),
        null => null,
      };
    }

    final type = cleaned[0];
    final id = cleaned[1];
    final keepsPosition = seconds > 0 && (type == 'track' || type == 'episode');
    final position = switch (keepsPosition) {
      true => '#${_clock(seconds)}',
      false => '',
    };
    final app = Uri.parse('spotify:$type:$id$position');
    final web = webFallback ?? Uri.https('open.spotify.com', '/$type/$id');
    return ContinueLink([app, web], keepsPosition: keepsPosition);
  }

  static ContinueLink _withFragment(Uri uri, String fragment, int seconds) {
    if (seconds <= 0) {
      return ContinueLink([uri], keepsPosition: false);
    }

    return ContinueLink([uri.replace(fragment: fragment)], keepsPosition: true);
  }

  static ContinueLink _twitch(Uri uri, int seconds) {
    final isVideo = uri.pathSegments.contains('videos');
    if (!isVideo || seconds <= 0) {
      return ContinueLink([uri], keepsPosition: false);
    }

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final rest = seconds % 60;
    final query = {...uri.queryParameters, 't': '${hours}h${minutes}m${rest}s'};
    return ContinueLink([
      uri.replace(queryParameters: query),
    ], keepsPosition: true);
  }

  static ContinueLink? _search({
    required String appId,
    required String title,
    required String artist,
  }) {
    final terms = [title, artist].where((part) => part.isNotEmpty).join(' ');
    if (terms.isEmpty) {
      return null;
    }

    final app = appId.toLowerCase();
    if (app.contains('spotify')) {
      return ContinueLink([
        Uri.parse('spotify:search:${Uri.encodeComponent(terms)}'),
        Uri.https('open.spotify.com', '/search/$terms'),
      ], keepsPosition: false);
    }

    if (app.contains('youtube.music') || app.contains('youtube_music')) {
      return ContinueLink([
        Uri.https('music.youtube.com', '/search', {'q': terms}),
      ], keepsPosition: false);
    }

    if (app.contains('youtube')) {
      return ContinueLink([
        Uri.https('www.youtube.com', '/results', {'search_query': terms}),
      ], keepsPosition: false);
    }

    return null;
  }

  /// `m:ss`, the position format Spotify and SoundCloud links use.
  static String _clock(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  static Uri _withQuery(Uri uri, Map<String, String> query) {
    if (query.isNotEmpty) {
      return uri.replace(queryParameters: query);
    }

    return Uri(scheme: uri.scheme, host: uri.host, path: uri.path);
  }
}
