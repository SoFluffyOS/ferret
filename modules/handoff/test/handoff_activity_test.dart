import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_handoff/ferret_handoff.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handoff/handoff.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/handoff.dart';
import 'package:provider/provider.dart';

import 'support/fakes.dart';

void main() {
  final l10n = lookupHandoffLocalizations(const Locale('en'));
  final offeredAt = DateTime(2026, 11, 18, 9);

  Suggestion suggestion(Activity activity, {HandoffPeer from = pixel}) =>
      Suggestion(
        activity: activity,
        from: from,
        isExplicit: false,
        receivedAt: offeredAt,
        expiresAt: offeredAt.add(const Duration(minutes: 5)),
      );

  Future<
    ({HandoffViewModel viewModel, HandoffFeature feature, FakeOpener opener})
  >
  build() async {
    final host = await FakeHost.create();
    final opener = FakeOpener();
    final feature = await startedFeature(host: host, opener: opener);
    final handoff = FerretHandoff(
      api: FakeHandoffApi(),
      isAndroid: false,
      isMacOS: false,
    );
    final viewModel = HandoffViewModel(
      feature: feature,
      bridge: HandoffBridge(
        feature: feature,
        engine: host,
        notifier: FakeNotifier(),
        handoff: handoff,
        pickDevice: (_) async => null,
        strings: () => l10n,
      ),
      handoff: handoff,
    );
    addTearDown(feature.stop);
    addTearDown(viewModel.dispose);
    return (viewModel: viewModel, feature: feature, opener: opener);
  }

  group('HandoffActivity.items', () {
    test('has no lines with nothing to continue', () {
      expect(HandoffActivity.items(l10n, const [], onOpen: (_) {}), isEmpty);
    });

    test('a page becomes a line with its device, site and time', () {
      final items = HandoffActivity.items(l10n, [
        suggestion(
          Activity(
            id: 'a',
            kind: .ACTIVITY_KIND_WEB,
            title: 'Cats',
            uri: 'https://www.example.org/cats?page=2',
          ),
        ),
      ], onOpen: (_) {});

      final item = items.single;
      expect(item.id, 'a');
      expect(item.icon, LucideIcons.globe);
      expect(item.title, 'Continue “Cats” from Pixel');
      expect(item.detail, 'example.org');
      expect(item.at, offeredAt);
      expect(item.pinned, isFalse);
      expect(item.deviceId, pixel.id);
      expect(item.actions.single.label, 'Open');
    });

    test('leaves the site out when it is the title, or not a page', () {
      final items = HandoffActivity.items(l10n, [
        suggestion(
          Activity(
            id: 'a',
            kind: .ACTIVITY_KIND_WEB,
            title: 'example.org',
            uri: 'https://example.org/',
          ),
        ),
        suggestion(
          Activity(
            id: 'b',
            kind: .ACTIVITY_KIND_TEXT,
            title: 'A note',
            text: 'Something private',
          ),
          from: tablet,
        ),
        suggestion(
          Activity(id: 'c', kind: .ACTIVITY_KIND_GEO, uri: 'geo:48.85,2.35'),
        ),
      ], onOpen: (_) {});

      expect(items.map((item) => item.detail), [null, null, null]);
      expect(items[1].title, 'Continue “A note” from Tablet');
      expect(items[1].icon, LucideIcons.text);
      expect(items[2].title, 'Continue from Pixel');
    });

    test('Open hands back its own suggestion', () {
      final opened = <String>[];
      final items = HandoffActivity.items(l10n, [
        suggestion(webActivity('a')),
        suggestion(webActivity('b'), from: tablet),
      ], onOpen: (suggestion) => opened.add(suggestion.id));

      items[1].actions.single.onPressed();

      expect(opened, ['b']);
    });

    test('a line can be let go only when there is a way to', () {
      final dismissed = <String>[];
      final items = HandoffActivity.items(
        l10n,
        [suggestion(webActivity('a')), suggestion(webActivity('b'))],
        onOpen: (_) {},
        onDismiss: (suggestion) => dismissed.add(suggestion.id),
      );
      final quiet = HandoffActivity.items(l10n, [
        suggestion(webActivity('a')),
      ], onOpen: (_) {});

      items[1].onDismiss?.call();

      expect(dismissed, ['b']);
      expect(quiet.single.onDismiss, isNull);
    });
  });

  group('a link that could not open', () {
    test('waits with Copy and Open, under its title', () {
      final copied = <String>[];
      final items = HandoffActivity.items(
        l10n,
        [
          Suggestion(
            activity: webActivity('a', title: 'Cats'),
            from: pixel,
            isExplicit: true,
            receivedAt: offeredAt,
            expiresAt: offeredAt.add(const Duration(minutes: 30)),
            openFailed: true,
          ),
        ],
        onOpen: (_) {},
        onCopy: (suggestion) => copied.add(suggestion.id),
      );

      final item = items.single;
      expect(item.title, "Couldn't open what Pixel sent");
      expect(item.detail, 'Cats · example.org');
      expect(item.actions.map((action) => action.label), ['Copy', 'Open']);
      item.actions.first.onPressed();
      expect(copied, ['a']);
    });
  });

  group('HandoffActivity.history', () {
    TimelineEntry entry(
      Activity activity, {
      TimelineDirection direction = .received,
      bool isExplicit = true,
      bool openFailed = false,
    }) => TimelineEntry(
      activity: activity,
      peer: pixel,
      direction: direction,
      at: offeredAt,
      isExplicit: isExplicit,
      openFailed: openFailed,
    );

    List<ActivityItem> history(
      List<TimelineEntry> entries, {
      Set<String> shown = const {},
    }) => HandoffActivity.history(
      l10n,
      entries,
      shown: shown,
      onOpen: (_) {},
      onCopy: (_) {},
      onForget: (_) {},
    );

    test('says what was sent and got, and whether it opened', () {
      final items = history([
        entry(webActivity('a', title: 'Cats'), direction: .sent),
        entry(
          webActivity('b', title: 'Dogs'),
          direction: .sent,
          openFailed: true,
        ),
        entry(webActivity('c', title: 'Birds')),
        entry(webActivity('d', title: 'Fish'), openFailed: true),
      ]);

      expect(items.map((item) => item.title), [
        'Sent to Pixel',
        "Pixel couldn't open it",
        'From Pixel',
        "Couldn't open what Pixel sent",
      ]);
      expect(items.first.detail, 'Cats · example.org');
      expect(items.first.actions, isEmpty);
      expect(items[1].tone, FeatureTone.warning);
      expect(items[3].actions.map((action) => action.label), ['Copy', 'Open']);
      expect(items.every((item) => item.onDismiss != null), isTrue);
      expect(items.every((item) => item.deviceId == pixel.id), isTrue);
    });

    test('leaves out passive offers and what a suggestion already shows', () {
      final items = history(
        [
          entry(webActivity('a'), isExplicit: false),
          entry(webActivity('b')),
          entry(webActivity('c')),
        ],
        shown: {'b'},
      );

      expect(items.single.id, 'handoff.received.c');
    });

    test('text from another device is private, a link is not', () {
      final items = history([
        entry(
          Activity(
            id: 't',
            kind: .ACTIVITY_KIND_TEXT,
            title: 'A note',
            text: 'A note',
          ),
        ),
        entry(webActivity('a')),
      ]);

      expect(items.first.private?.cover, 'From Pixel');
      expect(items.last.private, isNull);
    });
  });

  testWidgets('a line from before a restart opens again', (tester) async {
    final setup = await tester.runAsync(build);
    if (setup == null) {
      fail('Setup failed');
    }

    await tester.pumpWidget(testApp(const SizedBox()));
    await tester.runAsync(
      () => setup.feature.receiveContinue(pixel, webActivity('a')),
    );
    final context = tester.element(find.byType(SizedBox));
    final items = HandoffActivity.history(
      l10n,
      setup.viewModel.history,
      onOpen: (entry) =>
          HandoffActivity.reopen(context, setup.viewModel, entry),
      onCopy: (_) {},
      onForget: (_) {},
    );

    await tester.runAsync(() async {
      items.single.actions.last.onPressed();
      await pumpEventQueue();
    });

    expect(setup.opener.opened.map((activity) => activity.id), ['a', 'a']);
  });

  testWidgets('dismissing a line takes it off the list without opening it', (
    tester,
  ) async {
    final setup = await tester.runAsync(build);
    if (setup == null) {
      fail('Setup failed');
    }

    await tester.runAsync(
      () => setup.feature.receivePublished(
        pixel,
        webActivity('a', title: 'Cats'),
      ),
    );
    final items = HandoffActivity.items(
      l10n,
      setup.feature.suggestions,
      onOpen: (_) {},
      onDismiss: setup.viewModel.dismiss,
    );

    items.single.onDismiss?.call();

    expect(setup.opener.opened, isEmpty);
    expect(setup.feature.suggestions, isEmpty);
  });

  testWidgets('opening a line opens the activity and takes it off the list', (
    tester,
  ) async {
    final setup = await tester.runAsync(build);
    if (setup == null) {
      fail('Setup failed');
    }

    await tester.pumpWidget(testApp(const SizedBox()));
    await tester.runAsync(
      () => setup.feature.receivePublished(
        pixel,
        webActivity('a', title: 'Cats'),
      ),
    );
    final context = tester.element(find.byType(SizedBox));
    final items = HandoffActivity.items(
      l10n,
      setup.feature.suggestions,
      onOpen: (suggestion) =>
          HandoffActivity.open(context, setup.viewModel, suggestion),
    );

    await tester.runAsync(() async {
      items.single.actions.single.onPressed();
      await pumpEventQueue();
    });

    expect(setup.opener.opened.single.id, 'a');
    expect(setup.feature.suggestions, isEmpty);
  });

  testWidgets('the home frame leaves suggestions to Activity', (tester) async {
    final setup = await tester.runAsync(build);
    if (setup == null) {
      fail('Setup failed');
    }

    await tester.runAsync(
      () => setup.feature.receivePublished(
        pixel,
        webActivity('a', title: 'Cats'),
      ),
    );
    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: setup.viewModel,
          child: const HandoffHomeFrame(),
        ),
      ),
    );
    await tester.pump();

    expect(setup.viewModel.suggestions, hasLength(1));
    expect(find.textContaining('Cats'), findsNothing);
    expect(find.text('Open'), findsNothing);
  });
}
