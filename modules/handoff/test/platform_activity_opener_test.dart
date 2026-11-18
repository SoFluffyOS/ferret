import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:protocol/handoff.dart';
import 'package:protocol/protocol.dart';
import 'package:url_launcher/url_launcher.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final article = Activity(
    id: '1',
    kind: .ACTIVITY_KIND_APP,
    uri: 'https://en.wikipedia.org/wiki/Ferret',
    deepLink: 'wikipedia://en/Ferret',
    apps: AppIdentifiers(androidPackage: 'org.wikipedia'),
  );

  ({PlatformActivityOpener opener, FakeHandoffApi api, List<Uri> launched})
  build({
    Platform platform = .PLATFORM_ANDROID,
    bool appInstalled = true,
    Set<String> handled = const {},
    bool foreground = true,
  }) {
    final api = FakeHandoffApi()..appInstalled = appInstalled;
    final launched = <Uri>[];
    final opener = PlatformActivityOpener(
      platform: platform,
      handoff: FerretHandoff(api: api, isAndroid: true, isMacOS: false),
      launch: (uri, mode) async {
        launched.add(uri);
        if (mode == LaunchMode.externalNonBrowserApplication) {
          return handled.contains(uri.scheme);
        }

        return true;
      },
      isInForeground: () => foreground,
    );
    return (opener: opener, api: api, launched: launched);
  }

  test('the installed app takes its deep link', () async {
    final setup = build();

    expect(await setup.opener.open(article), OpenResult.opened);
    expect(setup.api.openedInApp.single, (
      'wikipedia://en/Ferret',
      'org.wikipedia',
    ));
    expect(setup.launched, isEmpty);
  });

  test('without the app, the web page opens', () async {
    final setup = build(appInstalled: false);

    expect(await setup.opener.open(article), OpenResult.opened);
    expect(setup.launched.map((uri) => uri.toString()), [
      'wikipedia://en/Ferret',
      'https://en.wikipedia.org/wiki/Ferret',
    ]);
  });

  test('in the background on Android it waits for a tap', () async {
    final setup = build(foreground: false);

    expect(await setup.opener.open(article), OpenResult.deferred);
    expect(setup.api.openedInApp, isEmpty);
  });

  test('text is copied even in the background', () async {
    final copied = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            final arguments = call.arguments as Map<Object?, Object?>;
            copied.add('${arguments['text']}');
          }

          return null;
        });
    final setup = build(foreground: false);

    final result = await setup.opener.open(
      Activity(id: 't', kind: .ACTIVITY_KIND_TEXT, text: 'Milk'),
    );

    expect(result, OpenResult.opened);
    expect(copied, ['Milk']);
  });

  test('nothing safe to open fails', () async {
    final setup = build();

    final result = await setup.opener.open(
      Activity(id: 'x', kind: .ACTIVITY_KIND_WEB, uri: 'file:///etc/hosts'),
    );

    expect(result, OpenResult.failed);
    expect(setup.launched, isEmpty);
  });
}
