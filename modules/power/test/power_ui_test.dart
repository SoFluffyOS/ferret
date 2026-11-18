import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:power/power.dart';
import 'package:power/ui/frames/frames.dart';
import 'package:power/ui/widgets/widgets.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

void main() {
  late PowerHarness harness;
  var opened = 0;

  Future<void> start(
    WidgetTester tester, {
    PowerStatus status = const PowerStatus(supported: true),
    Map<String, Object?>? settings,
  }) async {
    opened = 0;
    await tester.runAsync(() async {
      harness = await PowerHarness.start(status: status, settings: settings);
    });
    addTearDown(() => tester.runAsync(harness.dispose));
  }

  Widget framed(Widget frame) => testApp(
    ChangeNotifierProvider.value(value: harness.viewModel, child: frame),
  );

  Future<void> tapAndSettle(WidgetTester tester, String label) async {
    await tester.runAsync(() async {
      await tester.tap(find.text(label));
      await settle();
      await settle();
    });
    await tester.pump();
  }

  Finder rung(LadderRung rung) => find.byKey(ValueKey(rung));

  int locksIn(LadderRung target) => find
      .descendant(of: rung(target), matching: find.byIcon(LucideIcons.lock))
      .evaluate()
      .length;

  int checksIn(LadderRung target) => find
      .descendant(of: rung(target), matching: find.byIcon(LucideIcons.check))
      .evaluate()
      .length;

  group('the ladder', () {
    testWidgets('a plain phone has Basic on and the rest locked', (
      tester,
    ) async {
      await start(tester);

      await tester.pumpWidget(framed(const PowerLadderFrame()));

      expect(find.byType(LadderRungTile), findsNWidgets(5));
      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('+ Notifications'), findsOneWidget);
      expect(find.text('+ Messages & calls'), findsOneWidget);
      expect(find.text('+ Shizuku'), findsOneWidget);
      expect(find.text('+ Root'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
      expect(find.text('Not on yet'), findsNWidgets(4));
      expect(checksIn(.basic), 5);
      expect(locksIn(.basic), 0);
      expect(locksIn(.notifications), 2);
      expect(locksIn(.messagesAndCalls), 2);
      expect(locksIn(.shizuku), 2);
      expect(locksIn(.root), 2);
      expect(
        find.text('Send what you copy on its own, also in the background'),
        findsOneWidget,
      );
    });

    testWidgets('each rung opens its own features', (tester) async {
      await start(
        tester,
        status: const PowerStatus(
          supported: true,
          shizuku: .ready,
          notificationAccess: true,
        ),
        settings: {PowerSettings.shizukuEnabledKey: true},
      );

      await tester.pumpWidget(framed(const PowerLadderFrame()));

      expect(checksIn(.notifications), 2);
      expect(checksIn(.shizuku), 2);
      expect(locksIn(.messagesAndCalls), 2);
      expect(locksIn(.root), 2);
      expect(find.text('Open notification access'), findsNothing);
    });

    testWidgets('notification access opens the setting, with the fix for '
        'restricted settings', (tester) async {
      await start(tester);
      await tester.pumpWidget(framed(const PowerLadderFrame()));

      expect(find.textContaining('Allow restricted settings'), findsOneWidget);
      await tapAndSettle(tester, 'Open notification access');

      expect(harness.phone.opened, ['notificationAccess']);
      expect(harness.phone.shellCalls, isEmpty);
    });

    testWidgets('with Shizuku on, notification access is one tap', (
      tester,
    ) async {
      await start(
        tester,
        status: const PowerStatus(supported: true, shizuku: .ready),
        settings: {PowerSettings.shizukuEnabledKey: true},
      );
      await tester.pumpWidget(framed(const PowerLadderFrame()));

      await tapAndSettle(tester, 'Turn on now');

      expect(harness.phone.shellCalls, ['grant:shizuku:notificationAccess']);
      expect(checksIn(.notifications), 2);
      expect(find.text('Turn on now'), findsNothing);
    });

    testWidgets('a grant that fails says so', (tester) async {
      await start(
        tester,
        status: const PowerStatus(supported: true, shizuku: .ready),
        settings: {PowerSettings.shizukuEnabledKey: true},
      );
      harness.phone.failGrants = true;
      await tester.pumpWidget(framed(const PowerLadderFrame()));

      await tapAndSettle(tester, 'Turn on now');

      expect(find.textContaining("That didn't work."), findsOneWidget);
      expect(locksIn(.notifications), 2);
    });
  });

  group('Shizuku setup', () {
    testWidgets('walks install, start and allow, checking again on return', (
      tester,
    ) async {
      await start(tester);
      await tester.pumpWidget(framed(const PowerShizukuFrame()));

      expect(find.text('Get Shizuku'), findsOneWidget);
      expect(find.text('Open Shizuku'), findsNothing);
      expect(find.text('Allow'), findsNothing);
      await tapAndSettle(tester, 'Get Shizuku');
      expect(harness.openedLinks.single, PowerViewModel.shizukuDownload);

      harness.phone.setQuietly(
        const PowerStatus(supported: true, shizuku: .notRunning),
      );
      await tester.runAsync(() async {
        await harness.viewModel.refresh();
        await settle();
      });
      await tester.pump();
      expect(find.text('Get Shizuku'), findsNothing);
      await tapAndSettle(tester, 'Open Shizuku');
      expect(harness.phone.opened, ['shizuku']);

      harness.phone.emit(
        const PowerStatus(supported: true, shizuku: .notAuthorized),
      );
      await tester.runAsync(settle);
      await tester.pump();
      expect(find.text('Open Shizuku'), findsNothing);
      expect(find.byIcon(LucideIcons.circleCheck), findsNWidgets(2));
      await tapAndSettle(tester, 'Allow');

      expect(find.text('Shizuku is on.'), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleCheck), findsNWidgets(3));
      expect(harness.feature.tier, PowerTier.shizuku);
      expect(harness.feature.settings.shizukuEnabled, isTrue);
    });

    testWidgets('a no from Shizuku is explained', (tester) async {
      await start(
        tester,
        status: const PowerStatus(supported: true, shizuku: .notAuthorized),
      );
      harness.phone.shizukuAnswer = false;
      await tester.pumpWidget(framed(const PowerShizukuFrame()));

      await tapAndSettle(tester, 'Allow');

      expect(find.textContaining('Shizuku said no.'), findsOneWidget);
      expect(find.text('Shizuku is on.'), findsNothing);
    });

    testWidgets('once on, background running is one tap and it can be '
        'stopped', (tester) async {
      await start(
        tester,
        status: const PowerStatus(supported: true, shizuku: .ready),
        settings: {PowerSettings.shizukuEnabledKey: true},
      );
      await tester.pumpWidget(framed(const PowerShizukuFrame()));

      await tapAndSettle(tester, 'Turn on');
      expect(harness.phone.shellCalls, ['grant:shizuku:batteryUnrestricted']);
      expect(find.text('Ferret may run in the background.'), findsOneWidget);
      expect(find.text('Turn on'), findsNothing);

      await tapAndSettle(tester, 'Stop using Shizuku');
      expect(harness.feature.tier, PowerTier.standard);
      expect(find.text('Allow'), findsOneWidget);
    });
  });

  group('root', () {
    testWidgets('a phone without root is told it needs none', (tester) async {
      await start(tester);

      await tester.pumpWidget(framed(const PowerRootFrame()));

      expect(find.textContaining("This phone isn't rooted"), findsOneWidget);
      expect(find.text('Use root'), findsNothing);
    });

    testWidgets('a rooted phone gets the warning before the button', (
      tester,
    ) async {
      await start(
        tester,
        status: const PowerStatus(
          supported: true,
          root: .found,
          rootManager: .magisk,
        ),
      );
      await tester.pumpWidget(framed(const PowerRootFrame()));

      expect(find.text('Root found on this phone (Magisk).'), findsOneWidget);
      expect(
        find.textContaining('Root gives an app full control of your phone.'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
      expect(harness.phone.rootRequests, 0);

      await tapAndSettle(tester, 'Use root');

      expect(harness.phone.rootRequests, 1);
      expect(find.text('Root is on.'), findsOneWidget);
      expect(find.text('Stop using root'), findsOneWidget);
    });

    testWidgets('a denied prompt is explained and leaves root off', (
      tester,
    ) async {
      await start(
        tester,
        status: const PowerStatus(supported: true, root: .found),
      );
      harness.phone.rootAnswer = false;
      await tester.pumpWidget(framed(const PowerRootFrame()));

      await tapAndSettle(tester, 'Use root');

      expect(find.textContaining('Root access was denied.'), findsOneWidget);
      expect(harness.feature.settings.rootEnabled, isFalse);
      expect(find.text('Use root'), findsOneWidget);
    });
  });

  group('the home card and the offer', () {
    Widget card() => framed(PowerCardFrame(onOpen: () => opened++));

    Future<(PowerFeatureUi, FeatureOffer?)> offerOf(WidgetTester tester) async {
      final ui = PowerFeatureUi(feature: harness.feature);
      addTearDown(ui.viewModel.dispose);
      await tester.runAsync(settle);
      await tester.pumpWidget(card());
      return (
        ui,
        ui.offerFor(tester.element(find.byType(PowerCardFrame)), _NoContext()),
      );
    }

    testWidgets('a phone with Shizuku gets an offer, not a card', (
      tester,
    ) async {
      await start(
        tester,
        status: const PowerStatus(supported: true, shizuku: .notAuthorized),
      );

      final (ui, offer) = await offerOf(tester);

      expect(offer?.title, 'Power-ups');
      expect(
        offer?.description,
        'Allow Shizuku and Ferret sends what you copy on its own.',
      );
      expect(offer?.actionLabel, 'Set up');
      expect(ui.hasHomeCard(_NoContext()), isFalse);
      expect(find.text('Power-ups'), findsNothing);
    });

    testWidgets('a rooted phone is offered root', (tester) async {
      await start(
        tester,
        status: const PowerStatus(supported: true, root: .found),
      );

      final (_, offer) = await offerOf(tester);

      expect(
        offer?.description,
        'Use root and Ferret sends what you copy on its own.',
      );
      expect(harness.phone.rootRequests, 0);
    });

    testWidgets('a plain phone gets neither', (tester) async {
      await start(tester);

      final (ui, offer) = await offerOf(tester);

      expect(offer, isNull);
      expect(ui.hasHomeCard(_NoContext()), isFalse);
    });

    testWidgets('a stopped Shizuku is a card, not an offer', (tester) async {
      await start(
        tester,
        status: const PowerStatus(supported: true, shizuku: .notRunning),
        settings: {PowerSettings.shizukuEnabledKey: true},
      );

      final (ui, offer) = await offerOf(tester);

      expect(offer, isNull);
      expect(ui.hasHomeCard(_NoContext()), isTrue);
      expect(find.textContaining('Shizuku stopped'), findsOneWidget);
      await tapAndSettle(tester, 'Open Shizuku');

      expect(harness.phone.opened, ['shizuku']);
    });

    testWidgets('lost root asks again or stops using it', (tester) async {
      await start(
        tester,
        settings: {PowerSettings.rootEnabledKey: true},
      );
      await tester.pumpWidget(card());

      expect(find.textContaining('Root access was taken away'), findsOneWidget);
      expect(find.text('Ask again'), findsOneWidget);
      await tapAndSettle(tester, 'Stop using root');

      expect(harness.feature.settings.rootEnabled, isFalse);
      expect(find.text('Power-ups'), findsNothing);
    });
  });

  group('settings', () {
    Widget section() => framed(PowerSettingsFrame(onOpen: () => opened++));

    testWidgets('a computer is told there is nothing to set up', (
      tester,
    ) async {
      await start(tester, status: PowerStatus.unsupported);

      await tester.pumpWidget(section());

      expect(
        find.textContaining('Power-ups are extra abilities for Android phones'),
        findsOneWidget,
      );
      expect(find.text('Open Power-ups'), findsNothing);
    });

    testWidgets('a phone sees its tier and the way to the ladder', (
      tester,
    ) async {
      await start(
        tester,
        status: const PowerStatus(supported: true, shizuku: .ready),
        settings: {PowerSettings.shizukuEnabledKey: true},
      );
      await tester.pumpWidget(section());

      expect(find.textContaining('Shizuku is on.'), findsOneWidget);
      await tester.tap(find.text('Open Power-ups'));

      expect(opened, 1);
    });
  });
}

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
