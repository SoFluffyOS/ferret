import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:protocol/handoff.dart';

import 'support/browser_fakes.dart';
import 'support/fakes.dart';

void main() {
  group('origins', () {
    test('only exact extension origins pass', () {
      expect(BrowserOrigin.isExtension(chromeOrigin), isTrue);
      expect(BrowserOrigin.isExtension(firefoxOrigin), isTrue);
      expect(BrowserOrigin.isExtension('$chromeOrigin/'), isFalse);
      expect(BrowserOrigin.isExtension('https://example.org'), isFalse);
      expect(BrowserOrigin.isExtension(null), isFalse);
    });

    test('the host must name this computer', () {
      expect(BrowserOrigin.isLoopbackHost('127.0.0.1:47650'), isTrue);
      expect(BrowserOrigin.isLoopbackHost('localhost:47651'), isTrue);
      expect(BrowserOrigin.isLoopbackHost('[::1]:47650'), isTrue);
      expect(BrowserOrigin.isLoopbackHost('127.0.0.1.evil.example'), isFalse);
      expect(BrowserOrigin.isLoopbackHost('evil.example'), isFalse);
      expect(BrowserOrigin.isLoopbackHost(null), isFalse);
    });
  });

  group('tokens', () {
    test('a token matches its hash and nothing else', () {
      final token = BrowserToken.create();
      final hash = BrowserToken.hash(token);

      expect(token.length, greaterThanOrEqualTo(43));
      expect(BrowserToken.matches(token, hash), isTrue);
      expect(BrowserToken.matches('${token}x', hash), isFalse);
      expect(BrowserToken.matches(token, 'short'), isFalse);
      expect(BrowserToken.create(), isNot(token));
    });
  });

  group('limiter', () {
    test('allows a burst, then waits out the window', () {
      final clock = TestClock();
      final limiter = AttemptLimiter(
        maxAttempts: 2,
        window: const Duration(seconds: 10),
        clock: () => clock.now,
      );

      expect(limiter.tryAcquire(), isTrue);
      clock.advance(const Duration(seconds: 4));
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isFalse);
      expect(limiter.retryAfter, const Duration(seconds: 6));

      clock.advance(const Duration(seconds: 6));
      expect(limiter.tryAcquire(), isTrue);
    });
  });

  group('extension tabs', () {
    test('the position travels in the activity state', () {
      final tab = ExtensionTab.fromJson({
        'url': ' https://example.org/watch ',
        'title': 'A video\nsecond line',
        'videoTime': 61.5,
        'scrollY': 1200.4,
      });
      if (tab == null) {
        fail('The tab did not parse');
      }

      final activity = tab.toActivity(browser: 'Firefox');

      expect(activity.uri, 'https://example.org/watch');
      expect(activity.title, 'A video');
      expect(activity.sourceAppName, 'Firefox');
      expect(activity.stateType, ExtensionTab.stateType);
      expect(ExtensionTab.positionOf(activity), (
        videoTime: 61.5,
        scrollY: 1200,
      ));
    });

    test('a tab without a title is named after its host', () {
      final activity = ExtensionTab.fromJson({
        'url': 'https://www.example.org/a',
      })?.toActivity(browser: 'Chrome');

      expect(activity?.title, 'example.org');
      expect(activity?.state, isEmpty);
    });

    test('only web links of a sane size are accepted', () {
      expect(ExtensionTab.fromJson({'url': 'javascript:alert(1)'}), isNull);
      expect(ExtensionTab.fromJson({'url': 'file:///etc/hosts'}), isNull);
      expect(
        ExtensionTab.fromJson({'url': 'https://e.org/${'a' * 9000}'}),
        isNull,
      );
      expect(ExtensionTab.fromJson('https://example.org'), isNull);
    });

    test('bad positions are dropped', () {
      final tab = ExtensionTab.fromJson({
        'url': 'https://example.org',
        'videoTime': -3,
        'scrollY': 'far',
      });

      expect(tab?.videoTime, isNull);
      expect(tab?.scrollY, isNull);
    });

    test('other apps state is not read as a position', () {
      final activity = Activity(state: [1, 2], stateType: 'application/x-app');

      expect(ExtensionTab.positionOf(activity), (
        videoTime: null,
        scrollY: null,
      ));
    });
  });

  group('client store', () {
    test(
      'pairing again from the same origin replaces the old pairing',
      () async {
        final host = await FakeHost.create();
        final store = BrowserClientStore(host.settings);
        BrowserClient client(String id) => BrowserClient(
          id: id,
          name: 'Chrome',
          origin: chromeOrigin,
          tokenHash: BrowserToken.hash(id),
          pairedAt: DateTime(2026),
        );

        await store.add(client('one'));
        await store.add(client('two'));

        expect(store.clients.map((client) => client.id), ['two']);
        expect(store.find(token: 'two', origin: chromeOrigin)?.id, 'two');
        expect(store.find(token: 'one', origin: chromeOrigin), isNull);
        expect(await store.remove('two'), isTrue);
        expect(store.clients, isEmpty);
      },
    );
  });
}
