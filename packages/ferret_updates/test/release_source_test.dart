import 'dart:convert';
import 'dart:io';

import 'package:ferret_updates/ferret_updates.dart';
import 'package:flutter_test/flutter_test.dart';

/// A loopback server standing in for api.github.com, remembering each
/// request's headers.
class _FakeGithub {
  _FakeGithub._(this._server);

  static Future<_FakeGithub> start(
    Object? Function(HttpRequest request) answer,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = _FakeGithub._(server);
    server.listen((request) async {
      fake.requests.add(request);
      final body = answer(request);
      if (body == null) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      request.response.write(jsonEncode(body));
      await request.response.close();
    });
    return fake;
  }

  final HttpServer _server;
  final requests = <HttpRequest>[];

  Uri get url => Uri.parse('http://127.0.0.1:${_server.port}');

  GithubReleaseSource source() => GithubReleaseSource(
    http: UpdateHttp(allowInsecure: true),
    api: url,
  );

  Future<void> close() => _server.close(force: true);
}

Map<String, Object?> _json(
  String tag, {
  bool prerelease = false,
  bool draft = false,
}) => {
  'tag_name': tag,
  'body': '## What is new\n- Faster',
  'prerelease': prerelease,
  'draft': draft,
  'html_url': 'https://github.com/simonpham/ferret/releases/tag/$tag',
  'assets': [
    {
      'name': 'Ferret-mac.dmg',
      'browser_download_url':
          'https://github.com/simonpham/ferret/releases/download/$tag/Ferret-mac.dmg',
      'size': 1234,
    },
  ],
};

void main() {
  test('asks for the latest release with a plain User-Agent', () async {
    final github = await _FakeGithub.start((_) => _json('v0.2.0'));
    addTearDown(github.close);

    final release = await github.source().newest(includePreReleases: false);

    expect(release?.versionText, '0.2.0');
    expect(release?.notes, contains('Faster'));
    expect(release?.assetNamed('Ferret-mac.dmg')?.size, 1234);
    final request = github.requests.single;
    expect(request.uri.path, '/repos/simonpham/ferret/releases/latest');
    expect(request.headers.value(HttpHeaders.userAgentHeader), 'Ferret');
    expect(request.headers.value(HttpHeaders.cookieHeader), isNull);
    expect(request.headers.value(HttpHeaders.authorizationHeader), isNull);
    expect(request.uri.queryParameters, isEmpty);
  });

  test('no release yet is no update, not an error', () async {
    final github = await _FakeGithub.start((_) => null);
    addTearDown(github.close);

    expect(await github.source().newest(includePreReleases: false), isNull);
  });

  test('with test versions on, takes the highest, never a draft', () async {
    final github = await _FakeGithub.start(
      (_) => [
        _json('v0.4.0', draft: true),
        _json('v0.3.0-beta.2', prerelease: true),
        _json('v0.2.0'),
      ],
    );
    addTearDown(github.close);

    final release = await github.source().newest(includePreReleases: true);

    expect(release?.tag, 'v0.3.0-beta.2');
    expect(github.requests.single.uri.path, '/repos/simonpham/ferret/releases');
  });

  test('a server error is an error', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
    });

    final source = GithubReleaseSource(
      http: UpdateHttp(allowInsecure: true),
      api: Uri.parse('http://127.0.0.1:${server.port}'),
    );

    await expectLater(
      source.newest(includePreReleases: false),
      throwsA(isA<HttpException>()),
    );
  });

  test('refuses anything but HTTPS outside a test feed', () async {
    await expectLater(
      UpdateHttp().getText(Uri.parse('http://example.org/SHA256SUMS')),
      throwsArgumentError,
    );
  });

  group('test feed', () {
    late Directory folder;

    setUp(() async {
      folder = await Directory.systemTemp.createTemp('feed');
    });

    tearDown(() => folder.delete(recursive: true));

    test('reads a folder: release.json and the files next to it', () async {
      File('${folder.path}/release.json').writeAsStringSync(
        jsonEncode({'tag_name': 'v9.0.0', 'body': 'Hello'}),
      );
      File('${folder.path}/Ferret-mac.dmg').writeAsStringSync('dmg');
      File('${folder.path}/SHA256SUMS').writeAsStringSync('');

      final feed = FeedReleaseSource.fromEnvironment({
        'FERRET_UPDATE_FEED': folder.path,
      });
      final release = await feed?.newest(includePreReleases: false);

      expect(release?.versionText, '9.0.0');
      expect(release?.assets.map((asset) => asset.name).toSet(), {
        'Ferret-mac.dmg',
        'SHA256SUMS',
      });
      expect(release?.assetNamed('Ferret-mac.dmg')?.downloadUrl.scheme, 'file');
    });

    test('downloads a file from it with progress', () async {
      File('${folder.path}/release.json').writeAsStringSync(
        jsonEncode({'tag_name': 'v9.0.0'}),
      );
      File('${folder.path}/Ferret-mac.dmg').writeAsStringSync('x' * 1000);
      final release = await FeedReleaseSource(
        folder.uri,
      ).newest(includePreReleases: false);
      final asset = release?.assetNamed('Ferret-mac.dmg');
      final progress = <double?>[];
      final out = File('${folder.path}/out.dmg');

      await UpdateHttp(allowInsecure: true).download(
        asset?.downloadUrl ?? Uri(),
        out,
        onProgress: progress.add,
      );

      expect(out.readAsStringSync(), 'x' * 1000);
      expect(progress.first, 0);
      expect(progress.last, 1);
    });

    test('is off without FERRET_UPDATE_FEED', () {
      expect(FeedReleaseSource.fromEnvironment(const {}), isNull);
    });
  });
}
