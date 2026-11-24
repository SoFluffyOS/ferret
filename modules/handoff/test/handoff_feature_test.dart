import 'package:feature_kit/feature_kit.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:protocol/handoff.dart';

import 'support/fakes.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = HandoffFeatureUi(opener: FakeOpener());

    expect(ui.featureId, HandoffFeature.featureId);
    expect(ui.feature.id, HandoffFeature.featureId);
  });

  test(
    'a suggestion tells the shell to look again, without a home card',
    () async {
      final ui = HandoffFeatureUi(opener: FakeOpener());
      await ui.feature.start(await FakeHost.create());
      addTearDown(() async {
        ui.dispose();
        await ui.feature.stop();
      });
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);
      final context = _NoContext();

      await ui.feature.receivePublished(pixel, webActivity('a'));
      await Future<void>.delayed(Duration.zero);

      expect(ui.feature.suggestions, hasLength(1));
      expect(ui.hasHomeCard(context), isFalse);
      expect(changes, greaterThan(0));
    },
  );

  group('passive', () {
    test('a published activity becomes a suggestion that expires', () async {
      final clock = TestClock();
      final feature = await startedFeature(clock: clock);
      addTearDown(feature.stop);

      await feature.receivePublished(pixel, webActivity('a'));

      expect(feature.suggestions.single.id, 'a');
      expect(feature.suggestions.single.isExplicit, isFalse);
      clock.advance(const Duration(minutes: 4, seconds: 59));
      expect(feature.suggestions, hasLength(1));
      clock.advance(const Duration(seconds: 2));
      expect(feature.suggestions, isEmpty);
    });

    test('a newer activity from the same device replaces the old', () async {
      final feature = await startedFeature(clock: TestClock());
      addTearDown(feature.stop);
      final removed = <String>[];
      feature.removals.listen((suggestion) => removed.add(suggestion.id));

      await feature.receivePublished(pixel, webActivity('old'));
      await feature.receivePublished(tablet, webActivity('other'));
      await feature.receivePublished(pixel, webActivity('new'));
      await pumpEventQueue();

      expect(feature.suggestions.map((item) => item.id), ['new', 'other']);
      expect(removed, ['old']);
    });

    test(
      'a short lifetime from the sender is kept, a long one capped',
      () async {
        final clock = TestClock();
        final feature = await startedFeature(clock: clock);
        addTearDown(feature.stop);
        final short = webActivity('short')
          ..createdAtMs = Int64(1000)
          ..expiresAtMs = Int64(61000);
        final long = webActivity('long')
          ..createdAtMs = Int64(1000)
          ..expiresAtMs = Int64(1000 + const Duration(hours: 2).inMilliseconds);

        await feature.receivePublished(pixel, short);
        await feature.receivePublished(tablet, long);

        final byId = {for (final item in feature.suggestions) item.id: item};
        expect(
          byId['short']?.expiresAt,
          clock.now.add(const Duration(minutes: 1)),
        );
        expect(
          byId['long']?.expiresAt,
          clock.now.add(const Duration(minutes: 5)),
        );
      },
    );

    test('turning passive off ignores and clears passive ones', () async {
      final feature = await startedFeature(clock: TestClock());
      addTearDown(feature.stop);
      await feature.receivePublished(pixel, webActivity('a'));
      await feature.receiveContinue(tablet, webActivity('kept'));

      await feature.setPassiveEnabled(false);
      await feature.receivePublished(pixel, webActivity('b'));

      expect(feature.suggestions.map((item) => item.id), ['kept']);
    });

    test('publishing while passive is off sends nothing', () async {
      final host = await FakeHost.create({HandoffSettings.passive: false});
      final feature = await startedFeature(host: host);

      expect(await feature.publish(webActivity('a')), 0);
    });

    test('a clear from the sender withdraws its suggestions', () async {
      final feature = await startedFeature(clock: TestClock());
      addTearDown(feature.stop);
      await feature.receivePublished(pixel, webActivity('a'));
      await feature.receivePublished(tablet, webActivity('b'));

      feature.receiveClear(pixel, '');

      expect(feature.suggestions.single.id, 'b');
    });

    test('activities with nothing to open are ignored', () async {
      final feature = await startedFeature(clock: TestClock());
      addTearDown(feature.stop);

      await feature.receivePublished(pixel, Activity(id: 'empty'));
      await feature.receivePublished(pixel, Activity(uri: 'https://x.org'));

      expect(feature.suggestions, isEmpty);
    });
  });

  group('explicit', () {
    test('opens right away by default, without a suggestion', () async {
      final opener = FakeOpener();
      final feature = await startedFeature(opener: opener, clock: TestClock());
      addTearDown(feature.stop);
      final arrivals = <Suggestion>[];
      feature.arrivals.listen(arrivals.add);

      final outcome = await feature.receiveContinue(pixel, webActivity('a'));

      expect(outcome, ContinueOutcome.CONTINUE_OUTCOME_OPENED);
      expect(opener.opened.single.id, 'a');
      expect(feature.suggestions, isEmpty);
      expect(arrivals, isEmpty);
      expect(feature.timeline.single.direction, TimelineDirection.received);
    });

    test('with automatic opening off it waits as a suggestion', () async {
      final host = await FakeHost.create({
        HandoffSettings.openAutomatically: false,
      });
      final opener = FakeOpener();
      final feature = await startedFeature(
        host: host,
        opener: opener,
        clock: TestClock(),
      );
      addTearDown(feature.stop);
      final arrivals = <Suggestion>[];
      feature.arrivals.listen(arrivals.add);

      final outcome = await feature.receiveContinue(pixel, webActivity('a'));
      await pumpEventQueue();

      expect(outcome, ContinueOutcome.CONTINUE_OUTCOME_SUGGESTED);
      expect(opener.opened, isEmpty);
      expect(feature.suggestions.single.isExplicit, isTrue);
      expect(arrivals.single.id, 'a');
    });

    test('an activity the opener defers becomes a suggestion', () async {
      final feature = await startedFeature(
        opener: FakeOpener(.deferred),
        clock: TestClock(),
      );
      addTearDown(feature.stop);

      final outcome = await feature.receiveContinue(pixel, webActivity('a'));

      expect(outcome, ContinueOutcome.CONTINUE_OUTCOME_SUGGESTED);
      expect(feature.suggestions.single.id, 'a');
    });

    test('an activity that can not open is reported as failed, and waits '
        'here to be copied or opened', () async {
      final feature = await startedFeature(
        opener: FakeOpener(.failed),
        clock: TestClock(),
      );
      addTearDown(feature.stop);
      final arrival = feature.arrivals.first;

      final outcome = await feature.receiveContinue(pixel, webActivity('a'));

      expect(outcome, ContinueOutcome.CONTINUE_OUTCOME_FAILED);
      expect(feature.suggestions.single.openFailed, isTrue);
      expect(feature.suggestions.single.isExplicit, isTrue);
      expect((await arrival).id, 'a');
      expect(feature.timeline.single.openFailed, isTrue);
      expect(feature.timeline.single.isExplicit, isTrue);
    });

    test('an opener that throws is a failed open, not a lost link', () async {
      final feature = await startedFeature(
        opener: _ThrowingOpener(),
        clock: TestClock(),
      );
      addTearDown(feature.stop);

      final outcome = await feature.receiveContinue(pixel, webActivity('a'));
      final retried = await feature.open(feature.suggestions.single);

      expect(outcome, ContinueOutcome.CONTINUE_OUTCOME_FAILED);
      expect(retried, OpenResult.failed);
      expect(feature.suggestions.single.openFailed, isTrue);
    });

    test('opening it by hand later clears the failure', () async {
      final opener = FakeOpener(.failed);
      final feature = await startedFeature(opener: opener, clock: TestClock());
      addTearDown(feature.stop);
      await feature.receiveContinue(pixel, webActivity('a'));

      opener.result = .opened;
      final result = await feature.open(feature.suggestions.single);

      expect(result, OpenResult.opened);
      expect(feature.suggestions, isEmpty);
      expect(feature.timeline.single.openFailed, isFalse);
    });

    test('a line in the history opens again, and can be let go', () async {
      final opener = FakeOpener();
      final feature = await startedFeature(opener: opener, clock: TestClock());
      addTearDown(feature.stop);
      await feature.receiveContinue(pixel, webActivity('a'));

      final result = await feature.reopen(feature.timeline.single);
      await feature.forget(feature.timeline.single);

      expect(result, OpenResult.opened);
      expect(opener.opened, hasLength(2));
      expect(feature.timeline, isEmpty);
    });

    test('the same send twice opens once', () async {
      final opener = FakeOpener();
      final feature = await startedFeature(opener: opener, clock: TestClock());
      addTearDown(feature.stop);

      await feature.receiveContinue(pixel, webActivity('a'));
      final second = await feature.receiveContinue(pixel, webActivity('a'));

      expect(second, ContinueOutcome.CONTINUE_OUTCOME_OPENED);
      expect(opener.opened, hasLength(1));
    });

    test(
      'explicit suggestions outlive passive ones and are not replaced',
      () async {
        final clock = TestClock();
        final feature = await startedFeature(
          opener: FakeOpener(.deferred),
          clock: clock,
        );
        addTearDown(feature.stop);

        await feature.receiveContinue(pixel, webActivity('sent'));
        await feature.receivePublished(pixel, webActivity('passive'));
        clock.advance(const Duration(minutes: 10));

        expect(feature.suggestions.single.id, 'sent');
      },
    );

    test('opening a suggestion removes it; dismissing too', () async {
      final opener = FakeOpener(.deferred);
      final feature = await startedFeature(opener: opener, clock: TestClock());
      addTearDown(feature.stop);
      await feature.receiveContinue(pixel, webActivity('a'));
      await feature.receivePublished(tablet, webActivity('b'));

      opener.result = .opened;
      final suggestion = feature.suggestions.firstWhere((s) => s.id == 'a');
      expect(await feature.open(suggestion), OpenResult.opened);
      feature.dismiss('b');

      expect(feature.suggestions, isEmpty);
    });

    test('sending to a device that is not connected is unreachable', () async {
      final feature = await startedFeature();

      expect(
        await feature.sendTo('nobody', webActivity('a')),
        SendOutcome.unreachable,
      );
    });
  });
}

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingOpener implements ActivityOpener {
  @override
  Future<OpenResult> open(Activity activity) async =>
      throw StateError('no browser');
}
