import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The one way the updater reaches the internet: plain GETs over HTTPS
/// with a generic `User-Agent: Ferret` and nothing else about the person
/// or their devices. A test feed may also use `file:` and `http:` URLs.
class UpdateHttp {
  UpdateHttp({HttpClient Function()? client, this.allowInsecure = false})
    : _client = client ?? HttpClient.new;

  static const userAgent = 'Ferret';

  /// Lets `http:` and `file:` through, for a local test feed only.
  final bool allowInsecure;

  final HttpClient Function() _client;

  /// The JSON at [url], or null when there is none (404).
  Future<Object?> getJson(Uri url) async {
    final text = await getText(url, accept: 'application/vnd.github+json');
    if (text == null) {
      return null;
    }

    return jsonDecode(text);
  }

  /// The text at [url], or null when there is none (404). Refuses more
  /// than [maxBytes].
  Future<String?> getText(
    Uri url, {
    String? accept,
    int maxBytes = 4 * 1024 * 1024,
  }) async {
    _checkScheme(url);
    if (url.scheme == 'file') {
      final file = File.fromUri(url);
      if (!await file.exists()) {
        return null;
      }

      return file.readAsString();
    }

    final client = _client()..userAgent = userAgent;
    try {
      final request = await client.getUrl(url);
      if (accept case final accept?) {
        request.headers.set(HttpHeaders.acceptHeader, accept);
      }

      final response = await request.close();
      _checkRedirects(response);
      if (response.statusCode == HttpStatus.notFound) {
        await response.drain<void>();
        return null;
      }

      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HttpException('HTTP ${response.statusCode}', uri: url);
      }

      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > maxBytes) {
          throw HttpException('Response too large', uri: url);
        }
      }

      return utf8.decode(bytes, allowMalformed: true);
    } finally {
      client.close(force: true);
    }
  }

  /// Saves [url] to [destination], telling [onProgress] the share done
  /// (0 to 1, or null while the size is unknown). Stops with
  /// [UpdateDownloadCancelled] once [cancelled] completes.
  Future<void> download(
    Uri url,
    File destination, {
    int expectedSize = 0,
    void Function(double? progress)? onProgress,
    Future<void>? cancelled,
  }) async {
    _checkScheme(url);
    var stop = false;
    unawaited(cancelled?.then((_) => stop = true));
    final sink = destination.openWrite();
    final client = _client()..userAgent = userAgent;
    try {
      final (Stream<List<int>> body, int total) = switch (url.scheme) {
        'file' => (
          File.fromUri(url).openRead(),
          await File.fromUri(url).length(),
        ),
        _ => await _open(client, url),
      };
      final size = switch (total > 0) {
        true => total,
        false => expectedSize,
      };
      var received = 0;
      onProgress?.call(switch (size > 0) {
        true => 0,
        false => null,
      });
      await for (final chunk in body) {
        if (stop) {
          throw const UpdateDownloadCancelled();
        }

        sink.add(chunk);
        received += chunk.length;
        if (size > 0) {
          onProgress?.call((received / size).clamp(0, 1).toDouble());
        }
      }

      if (stop) {
        throw const UpdateDownloadCancelled();
      }
    } finally {
      await sink.close();
      client.close(force: true);
    }
  }

  Future<(Stream<List<int>>, int)> _open(HttpClient client, Uri url) async {
    final request = await client.getUrl(url);
    final response = await request.close();
    _checkRedirects(response);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }

    return (response, response.contentLength);
  }

  void _checkScheme(Uri url) {
    if (url.scheme == 'https') {
      return;
    }

    if (allowInsecure && (url.scheme == 'http' || url.scheme == 'file')) {
      return;
    }

    throw ArgumentError.value(url, 'url', 'Updates only come over HTTPS');
  }

  void _checkRedirects(HttpClientResponse response) {
    for (final redirect in response.redirects) {
      if (redirect.location.scheme == 'https' || allowInsecure) {
        continue;
      }

      throw HttpException(
        'Redirected away from HTTPS',
        uri: redirect.location,
      );
    }
  }
}

/// The download stopped because the person cancelled it.
class UpdateDownloadCancelled implements Exception {
  const UpdateDownloadCancelled();
}
