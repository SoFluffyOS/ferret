import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:handoff/l10n/l10n.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<
    ({
      HandoffBridge bridge,
      HandoffFeature feature,
      FakeNotifier notifier,
      FakeOpener opener,
      FakeHandoffApi api,
    })
  >
  build({
    List<SharedItem> pending = const [],
    Future<void> Function(Duration timeout)? untilForeground,
  }) async {
    final host = await FakeHost.create({
      HandoffSettings.openAutomatically: false,
    });
    final opener = FakeOpener();
    final feature = await startedFeature(
      host: host,
      opener: opener,
      clock: TestClock(),
    );
    final notifier = FakeNotifier();
    final api = FakeHandoffApi()..pending = [...pending];
    final bridge = HandoffBridge(
      feature: feature,
      engine: host,
      notifier: notifier,
      handoff: FerretHandoff(api: api, isAndroid: true, isMacOS: false),
      pickDevice: (_) async => null,
      strings: () => lookupHandoffLocalizations(const .new('en')),
      connectTimeout: const Duration(milliseconds: 50),
      untilForeground: untilForeground ?? (_) async {},
    );
    await bridge.start();
    addTearDown(bridge.dispose);
    addTearDown(feature.stop);
    return (
      bridge: bridge,
      feature: feature,
      notifier: notifier,
      opener: opener,
      api: api,
    );
  }

  test('a send that waits shows a notice that opens it', () async {
    final setup = await build();

    await setup.feature.receiveContinue(pixel, webActivity('a', title: 'Cats'));
    await pumpEventQueue();

    final notice = setup.notifier.shown.single;
    expect(notice.title, 'Continue “Cats”');
    expect(notice.body, 'From Pixel');
    expect(notice.channel, NoticeChannel.suggestions);
    expect(notice.category, HandoffBridge.continueCategory);

    setup.notifier.respond(
      NoticeResponse(
        noticeId: notice.id,
        actionId: HandoffBridge.openAction,
      ),
    );
    await pumpEventQueue();

    expect(setup.opener.opened.single.id, 'a');
    expect(setup.feature.suggestions, isEmpty);
    expect(setup.notifier.cancelled, [notice.id]);
  });

  test('a tap while Android blocks opening retries once in front', () async {
    late FakeOpener opener;
    final setup = await build(
      untilForeground: (_) async => opener.result = .opened,
    );
    opener = setup.opener..result = .deferred;
    await setup.feature.receiveContinue(pixel, webActivity('a'));
    await pumpEventQueue();

    setup.notifier.respond(
      NoticeResponse(noticeId: HandoffBridge.noticeIdFor('a')),
    );
    await pumpEventQueue();

    expect(setup.opener.opened, hasLength(2));
    expect(setup.feature.suggestions, isEmpty);
  });

  test('dismissing the notice dismisses the suggestion', () async {
    final setup = await build();
    await setup.feature.receiveContinue(pixel, webActivity('a'));
    await pumpEventQueue();

    setup.notifier.respond(
      NoticeResponse(
        noticeId: HandoffBridge.noticeIdFor('a'),
        actionId: HandoffBridge.dismissAction,
      ),
    );
    await pumpEventQueue();

    expect(setup.opener.opened, isEmpty);
    expect(setup.feature.suggestions, isEmpty);
  });

  test('passive suggestions never notify', () async {
    final setup = await build();

    await setup.feature.receivePublished(pixel, webActivity('a'));
    await pumpEventQueue();

    expect(setup.notifier.shown, isEmpty);
  });

  test('a share with nothing usable explains itself', () async {
    final setup = await build();

    final sent = await setup.bridge.onShared(
      SharedItem(origin: .shareSheet, createdAtMs: 0, text: '  '),
    );

    expect(sent, isFalse);
    expect(setup.notifier.shown.single.channel, NoticeChannel.problems);
  });

  test('a queued share to an offline device says it was not sent', () async {
    final setup = await build(
      pending: [
        SharedItem(
          origin: .shareSheet,
          createdAtMs: 0,
          text: 'https://example.org',
          targetDeviceId: 'gone',
        ),
      ],
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(setup.api.pending, isEmpty);
    expect(setup.notifier.shown.single.title, "Couldn't send to gone");
  });
}
