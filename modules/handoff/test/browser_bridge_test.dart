import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:protocol/handoff.dart';

import 'support/browser_fakes.dart';
import 'support/fakes.dart';

void main() {
  late FakeHost host;
  late RecordingFeature feature;
  late BrowserBridge bridge;
  late TestClock clock;

  setUp(() async {
    clock = TestClock();
    host = await FakeHost.create({HandoffSettings.openAutomatically: false});
    feature = RecordingFeature();
    await feature.start(host);
    bridge = BrowserBridge(
      feature: feature,
      isSupported: true,
      server: IdleServer(),
      clock: () => clock.now,
      pairTimeout: const Duration(milliseconds: 200),
      openTimeout: const Duration(milliseconds: 200),
    );
    await bridge.start();
  });

  tearDown(() async {
    await bridge.stop();
    await feature.stop();
  });

  Future<FakeChannel> connect({String origin = chromeOrigin}) async {
    final channel = FakeChannel(origin: origin);
    bridge.attach(channel);
    return channel;
  }

  /// Pairs a new extension and returns its channel and token.
  Future<({FakeChannel channel, String token})> paired({
    String origin = chromeOrigin,
  }) async {
    final channel = await connect(origin: origin);
    channel
      ..say({'type': 'hello', 'v': 1, 'browser': 'Chrome'})
      ..say({'type': 'pair', 'id': 'p1', 'code': '123456'});
    await pumpEventQueue();
    await bridge.answerPair(bridge.pairRequests.single.id, allow: true);
    final token = channel.last('paired')['token'];
    if (token is! String) {
      fail('No token');
    }

    return (channel: channel, token: token);
  }

  group('pairing', () {
    test('the user allows a browser after comparing the code', () async {
      final channel = await connect();
      final requested = <BrowserPairRequest>[];
      bridge.pairRequested.listen(requested.add);

      channel
        ..say({'type': 'hello', 'v': 1, 'id': 'h1', 'browser': 'Firefox'})
        ..say({'type': 'pair', 'id': 'p1', 'code': '482913'});
      await pumpEventQueue();

      final welcome = channel.last('welcome');
      expect(welcome['paired'], isFalse);
      expect(welcome['app'], 'ferret');
      expect(welcome['re'], 'h1');
      expect(requested.single.browser, 'Firefox');
      expect(requested.single.spacedCode, '482 913');

      await bridge.answerPair(requested.single.id, allow: true);

      final reply = channel.last('paired');
      expect(reply['re'], 'p1');
      expect(reply['token'], isA<String>());
      expect(bridge.pairRequests, isEmpty);
      expect(bridge.clients.single.name, 'Firefox');
      expect(bridge.clients.single.origin, chromeOrigin);
      expect(channel.ofType('devices'), hasLength(1));
    });

    test('Ferret keeps only a hash of the token', () async {
      final setup = await paired();

      final saved = jsonEncode(
        host.settings.get<Object>(HandoffSettings.browserClients),
      );
      expect(saved, isNot(contains(setup.token)));
    });

    test('a denied browser gets no token', () async {
      final channel = await connect();
      channel
        ..say({'type': 'hello', 'v': 1})
        ..say({'type': 'pair', 'id': 'p1', 'code': '123456'});
      await pumpEventQueue();

      await bridge.answerPair(bridge.pairRequests.single.id, allow: false);

      expect(channel.last('pair_denied')['reason'], 'denied');
      expect(channel.ofType('paired'), isEmpty);
      expect(bridge.clients, isEmpty);
    });

    test('an unanswered request times out', () async {
      final channel = await connect();
      channel
        ..say({'type': 'hello', 'v': 1})
        ..say({'type': 'pair', 'code': '123456'});
      await pumpEventQueue();

      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(channel.last('pair_denied')['reason'], 'timeout');
      expect(bridge.pairRequests, isEmpty);
    });

    test('a request goes away when the extension disconnects', () async {
      final channel = await connect();
      channel
        ..say({'type': 'hello', 'v': 1})
        ..say({'type': 'pair', 'code': '123456'});
      await pumpEventQueue();
      expect(bridge.pairRequests, hasLength(1));

      await channel.disconnect();
      await pumpEventQueue();

      expect(bridge.pairRequests, isEmpty);
    });

    test('codes must be six digits', () async {
      final channel = await connect();
      channel
        ..say({'type': 'hello', 'v': 1})
        ..say({'type': 'pair', 'id': 'p1', 'code': '12ab56'});
      await pumpEventQueue();

      expect(channel.last('error')['code'], 'bad_request');
      expect(bridge.pairRequests, isEmpty);
    });

    test('one pending request per connection', () async {
      final channel = await connect();
      channel
        ..say({'type': 'hello', 'v': 1})
        ..say({'type': 'pair', 'code': '123456'})
        ..say({'type': 'pair', 'id': 'again', 'code': '654321'});
      await pumpEventQueue();

      expect(bridge.pairRequests, hasLength(1));
      expect(channel.last('pair_denied')['reason'], 'busy');
    });

    test('hello comes first', () async {
      final channel = await connect();
      channel.say({'type': 'pair', 'code': '123456'});
      await pumpEventQueue();

      expect(channel.last('error')['code'], 'hello_first');
      expect(channel.closedWith, BrowserCloseCode.protocolError);
    });

    test('another protocol version is turned away', () async {
      final channel = await connect();
      channel.say({'type': 'hello', 'v': 2});
      await pumpEventQueue();

      expect(channel.last('error')['code'], 'unsupported_version');
      expect(channel.closedWith, isNotNull);
    });
  });

  group('tokens', () {
    test('a paired extension comes back with its token', () async {
      final setup = await paired();
      await setup.channel.disconnect();

      final channel = await connect();
      channel.say({'type': 'hello', 'v': 1, 'token': setup.token});
      await pumpEventQueue();

      expect(channel.last('welcome')['paired'], isTrue);
      expect(channel.ofType('devices'), hasLength(1));
      expect(channel.ofType('suggestions'), hasLength(1));
    });

    test('a token only works from the origin it was paired from', () async {
      final setup = await paired();

      final other = await connect(origin: firefoxOrigin);
      other.say({'type': 'hello', 'v': 1, 'token': setup.token});
      await pumpEventQueue();

      expect(other.last('welcome')['paired'], isFalse);
    });

    test('every message needs the token', () async {
      final setup = await paired();

      setup.channel.say({'type': 'devices', 'id': 'd1'});
      setup.channel.say({'type': 'devices', 'id': 'd2', 'token': 'wrong'});
      await pumpEventQueue();

      final errors = setup.channel.ofType('error');
      expect(errors.map((error) => error['code']), [
        'unauthorized',
        'unauthorized',
      ]);
      expect(errors.map((error) => error['re']), ['d1', 'd2']);
    });

    test('an unpaired connection may not send', () async {
      final channel = await connect();
      channel
        ..say({'type': 'hello', 'v': 1})
        ..say({
          'type': 'send',
          'token': 'guess',
          'deviceId': 'pixel',
          'tab': {'url': 'https://example.org'},
        });
      await pumpEventQueue();

      expect(channel.last('error')['code'], 'unauthorized');
      expect(feature.sends, isEmpty);
    });

    test('removing a browser in Ferret revokes it right away', () async {
      final setup = await paired();

      await bridge.removeClient(bridge.clients.single.id);

      expect(setup.channel.ofType('revoked'), hasLength(1));
      expect(setup.channel.closedWith, BrowserCloseCode.revoked);
      expect(bridge.clients, isEmpty);
    });

    test('the extension can unpair itself', () async {
      final setup = await paired();

      setup.channel.say({'type': 'unpair', 'token': setup.token});
      await pumpEventQueue();

      expect(setup.channel.ofType('unpaired'), hasLength(1));
      expect(bridge.clients, isEmpty);
    });
  });

  group('rate limit', () {
    test('wrong tokens are limited, then the connection is closed', () async {
      final channels = <FakeChannel>[];
      for (var attempt = 0; attempt < 11; attempt++) {
        final channel = await connect();
        channel.say({'type': 'hello', 'v': 1, 'token': 'guess-$attempt'});
        channels.add(channel);
      }
      await pumpEventQueue();

      expect(channels.take(10).every((c) => c.closedWith == null), isTrue);
      final limited = channels.last;
      expect(limited.last('error')['code'], 'rate_limited');
      expect(limited.last('error')['retryAfterMs'], greaterThan(0));
      expect(limited.closedWith, BrowserCloseCode.rateLimited);
    });

    test('the limit lifts after the window', () async {
      for (var attempt = 0; attempt < 10; attempt++) {
        (await connect()).say({'type': 'hello', 'v': 1, 'token': 'x$attempt'});
      }
      await pumpEventQueue();

      clock.advance(const Duration(minutes: 1, seconds: 1));
      final channel = await connect();
      channel.say({'type': 'hello', 'v': 1, 'token': 'later'});
      await pumpEventQueue();

      expect(channel.last('welcome')['paired'], isFalse);
      expect(channel.closedWith, isNull);
    });

    test('pair requests count too', () async {
      final last = <FakeChannel>[];
      for (var attempt = 0; attempt < 11; attempt++) {
        final channel = await connect();
        channel
          ..say({'type': 'hello', 'v': 1})
          ..say({'type': 'pair', 'code': '123456'});
        await pumpEventQueue();
        final pending = bridge.pairRequests;
        if (pending.isNotEmpty) {
          await bridge.answerPair(pending.first.id, allow: false);
        }

        last.add(channel);
      }

      expect(last.last.last('error')['code'], 'rate_limited');
    });

    test('messages that are too big close the connection', () async {
      final channel = await connect();
      channel.sayRaw('x' * (BrowserBridge.maxMessageLength + 1));
      await pumpEventQueue();

      expect(channel.closedWith, BrowserCloseCode.tooLarge);
    });

    test('garbage is answered, then cut off', () async {
      final channel = await connect();
      for (var strike = 0; strike < 5; strike++) {
        channel.sayRaw('not json');
      }
      await pumpEventQueue();

      expect(channel.ofType('error'), isNotEmpty);
      expect(channel.closedWith, BrowserCloseCode.protocolError);
    });
  });

  group('routing', () {
    test('send this tab becomes an explicit send', () async {
      final setup = await paired();

      setup.channel.say({
        'type': 'send',
        'id': 's1',
        'token': setup.token,
        'deviceId': 'pixel-id',
        'tab': {
          'url': 'https://www.youtube.com/watch?v=abc&t=95s',
          'title': 'A talk',
          'videoTime': 95.4,
          'scrollY': 300,
        },
      });
      await pumpEventQueue();

      final (deviceId, activity) = feature.sends.single;
      expect(deviceId, 'pixel-id');
      expect(activity.kind, ActivityKind.ACTIVITY_KIND_WEB);
      expect(activity.uri, 'https://www.youtube.com/watch?v=abc&t=95s');
      expect(activity.title, 'A talk');
      expect(activity.sourceAppName, 'Chrome');
      expect(ExtensionTab.positionOf(activity).videoTime, 95.4);
      expect(ExtensionTab.positionOf(activity).scrollY, 300);
      expect(setup.channel.last('sent'), {
        'type': 'sent',
        're': 's1',
        'outcome': 'opened',
      });
    });

    test('the outcome comes back as it is', () async {
      final setup = await paired();
      feature.outcome = .unreachable;

      setup.channel.say({
        'type': 'send',
        'id': 's1',
        'token': setup.token,
        'deviceId': 'gone',
        'tab': {'url': 'https://example.org'},
      });
      await pumpEventQueue();

      expect(setup.channel.last('sent')['outcome'], 'unreachable');
    });

    test('only web pages can be sent', () async {
      final setup = await paired();

      setup.channel.say({
        'type': 'send',
        'token': setup.token,
        'deviceId': 'pixel-id',
        'tab': {'url': 'file:///etc/passwd'},
      });
      await pumpEventQueue();

      expect(feature.sends, isEmpty);
      expect(setup.channel.last('error')['code'], 'bad_request');
    });

    test('the shared tab is published once while it stands', () async {
      final setup = await paired();
      final share = {
        'type': 'share',
        'token': setup.token,
        'tab': {'url': 'https://example.org/a', 'title': 'A'},
      };

      setup.channel
        ..say(share)
        ..say(share);
      await pumpEventQueue();

      expect(feature.published, hasLength(1));
      expect(feature.published.single.uri, 'https://example.org/a');
    });

    test('devices list the paired devices and who is connected', () async {
      await host.trustStore.save(trustedDevice('pixel-id', 'Pixel'));
      final setup = await paired();

      setup.channel.say({'type': 'devices', 'id': 'd', 'token': setup.token});
      await pumpEventQueue();

      final devices = setup.channel.last('devices')['devices'];
      expect(devices, [
        {
          'id': 'pixel-id',
          'name': 'Pixel',
          'platform': 'android',
          'formFactor': 'phone',
          'connected': false,
        },
      ]);
    });

    test('a new paired device is pushed to the extension', () async {
      final setup = await paired();
      final before = setup.channel.ofType('devices').length;

      await host.trustStore.save(trustedDevice('tablet-id', 'Tablet'));
      await pumpEventQueue();

      expect(setup.channel.ofType('devices'), hasLength(before + 1));
    });

    test('suggestions from other devices are pushed once each', () async {
      final setup = await paired();
      final before = setup.channel.ofType('suggestions').length;

      await feature.receivePublished(pixel, webActivity('a', title: 'Cats'));
      await feature.receivePublished(
        tablet,
        Activity(id: 't', kind: .ACTIVITY_KIND_TEXT, text: 'hi'),
      );
      await pumpEventQueue();

      final pushes = setup.channel.ofType('suggestions').skip(before).toList();
      expect(pushes, hasLength(1));
      final items = pushes.single['items'];
      if (items is! List) {
        fail('No items');
      }

      final item = items.single;
      if (item is! Map) {
        fail('Not an item');
      }

      expect(item['title'], 'Cats');
      expect(item['from'], 'Pixel');
      expect(item['url'], 'https://example.org/a');
    });

    test('the extension dismisses a suggestion it opened', () async {
      final setup = await paired();
      await feature.receivePublished(pixel, webActivity('a'));

      setup.channel.say({
        'type': 'dismiss',
        'token': setup.token,
        'activityId': 'a',
      });
      await pumpEventQueue();

      expect(feature.suggestions, isEmpty);
    });
  });

  group('opening here', () {
    test('a browser in front opens the page in a new tab', () async {
      final setup = await paired();
      setup.channel.say({
        'type': 'focus',
        'token': setup.token,
        'focused': true,
      });
      await pumpEventQueue();

      final opening = bridge.openInBrowser(webActivity('a', title: 'Cats'));
      await pumpEventQueue();
      final request = setup.channel.last('open');
      expect(request['url'], 'https://example.org/a');
      setup.channel.say({
        'type': 'opened',
        'token': setup.token,
        're': request['id'],
        'ok': true,
      });

      expect(await opening, isTrue);
    });

    test('a browser in the background is skipped', () async {
      final setup = await paired();
      setup.channel.say({
        'type': 'focus',
        'token': setup.token,
        'focused': false,
      });
      await pumpEventQueue();

      expect(await bridge.openInBrowser(webActivity('a')), isFalse);
      expect(setup.channel.ofType('open'), isEmpty);
    });

    test('no answer falls back to the system', () async {
      final setup = await paired();
      setup.channel.say({
        'type': 'focus',
        'token': setup.token,
        'focused': true,
      });
      await pumpEventQueue();

      final fallback = FakeOpener();
      final opener = BrowserFirstOpener(browser: bridge, fallback: fallback);

      expect(await opener.open(webActivity('a')), OpenResult.opened);
      expect(fallback.opened.single.id, 'a');
    });

    test('text and places never go to the browser', () async {
      final setup = await paired();
      setup.channel.say({
        'type': 'focus',
        'token': setup.token,
        'focused': true,
      });
      await pumpEventQueue();

      final opened = await bridge.openInBrowser(
        Activity(id: 'g', kind: .ACTIVITY_KIND_GEO, uri: 'geo:1,2'),
      );

      expect(opened, isFalse);
      expect(setup.channel.ofType('open'), isEmpty);
    });
  });

  group('setting', () {
    test('turning it off stops the server and closes browsers', () async {
      final server = IdleServer();
      final switchable = BrowserBridge(
        feature: feature,
        isSupported: true,
        server: server,
      );
      await switchable.start();
      addTearDown(switchable.stop);
      expect(switchable.state.status, BrowserBridgeStatus.listening);

      final channel = FakeChannel();
      switchable.attach(channel);
      await switchable.setEnabled(false);

      expect(server.started, isFalse);
      expect(switchable.state.status, BrowserBridgeStatus.off);
      expect(channel.closedWith, isNotNull);
    });

    test('phones never listen', () async {
      final server = IdleServer();
      final phone = BrowserBridge(
        feature: feature,
        isSupported: false,
        server: server,
      );
      await phone.start();
      addTearDown(phone.stop);

      expect(server.started, isFalse);
      expect(phone.state.status, BrowserBridgeStatus.off);
    });

    test('taken ports are reported', () async {
      final failing = BrowserBridge(
        feature: feature,
        isSupported: true,
        server: IdleServer(port: null),
      );
      await failing.start();
      addTearDown(failing.stop);

      expect(failing.state.status, BrowserBridgeStatus.failed);
    });
  });
}
