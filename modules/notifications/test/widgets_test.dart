import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notifications/notifications.dart';
import 'package:protocol/notifications.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('phone setup', () {
    late FakeNotificationSource source;
    late NotificationsFeature feature;
    late MemorySettingsStore settings;

    Future<void> pumpSetup(WidgetTester tester) async {
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider(
            create: (_) =>
                MirrorSetupViewModel(feature: feature, access: source),
            child: PhoneSetupFrame(onChooseApps: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() async {
      source = FakeNotificationSource()
        ..accessGranted = false
        ..apps = [.new(packageName: signal, name: 'Signal')];
      feature = NotificationsFeature(source: source);
      settings = MemorySettingsStore();
      await feature.start(SettingsOnlyHost(settings));
    });

    testWidgets('starts with the explainer', (tester) async {
      await pumpSetup(tester);

      expect(
        find.text(
          "Shows your phone's notifications on your computer. "
          'You pick which apps.',
        ),
        findsOneWidget,
      );
      expect(find.text('Turn on'), findsOneWidget);
    });

    testWidgets(
      'turning on opens access settings and says when it is still off',
      (tester) async {
        await pumpSetup(tester);

        await tester.tap(find.text('Turn on'));
        await tester.pumpAndSettle();

        expect(source.openedAccessSettings, 1);
        expect(feature.preferences.enabled, isTrue);
        expect(feature.preferences.allowedApps, {signal});
        expect(find.text('Notification access is off'), findsOneWidget);

        tester.binding.handleAppLifecycleStateChanged(.inactive);
        tester.binding.handleAppLifecycleStateChanged(.resumed);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Still off.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows the restricted settings guide when Android blocks it', (
      tester,
    ) async {
      source.restricted = true;
      await settings.set(MirrorPreferences.enabledKey, true);
      await pumpSetup(tester);

      expect(find.text('Android blocked this setting'), findsOneWidget);

      await tester.tap(find.text('Open App info'));
      await tester.pumpAndSettle();
      expect(source.openedAppInfo, 1);
    });

    testWidgets('shows a check mark and the options once access is on', (
      tester,
    ) async {
      source.accessGranted = true;
      await settings.set(MirrorPreferences.enabledKey, true);
      await settings.set(MirrorPreferences.allowedAppsKey, [signal]);
      await pumpSetup(tester);

      expect(find.text('Notification access is on'), findsOneWidget);
      expect(find.text("Pause while I'm using the phone"), findsOneWidget);
      expect(find.text('Choose apps · 1 app picked'), findsOneWidget);
    });
  });

  group('phone home card and offer', () {
    late FakeNotificationSource source;
    late NotificationsFeature feature;
    late MemorySettingsStore settings;
    late NotificationsFeatureUi ui;
    final context = _NoContext();

    setUp(() async {
      source = FakeNotificationSource()..accessGranted = false;
      feature = NotificationsFeature(source: source);
      settings = MemorySettingsStore();
      await feature.start(SettingsOnlyHost(settings));
      ui = NotificationsFeatureUi.withFeature(feature, access: source);
    });

    tearDown(() => ui.dispose());

    Future<FeatureOffer?> pumpUi(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (buildContext) =>
                ui.buildHomeCard(buildContext, context) ?? const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return ui.offerFor(tester.element(find.byType(ListView)), context);
    }

    testWidgets('offers mirroring while it is off, with no card', (
      tester,
    ) async {
      final offer = await pumpUi(tester);

      expect(offer?.title, 'Notifications');
      expect(
        offer?.description,
        "See your phone's notifications on your computer.",
      );
      expect(offer?.actionLabel, 'Set up');
      expect(ui.hasHomeCard(context), isFalse);
      expect(find.text('Notifications'), findsNothing);
    });

    testWidgets('on without access, the card asks for a fix', (tester) async {
      await settings.set(MirrorPreferences.enabledKey, true);

      final offer = await pumpUi(tester);

      expect(offer, isNull);
      expect(ui.hasHomeCard(context), isTrue);
      expect(
        find.text('Notification access is off, so nothing is mirrored.'),
        findsOneWidget,
      );
      expect(find.text('Fix'), findsOneWidget);
    });

    testWidgets('once it works, neither an offer nor a card', (tester) async {
      source.accessGranted = true;
      await pumpUi(tester);
      var changes = 0;
      ui.uiChanges?.addListener(() => changes++);

      await settings.set(MirrorPreferences.enabledKey, true);
      await tester.pumpAndSettle();

      expect(
        ui.offerFor(tester.element(find.byType(ListView)), context),
        isNull,
      );
      expect(ui.hasHomeCard(context), isFalse);
      expect(changes, greaterThan(0));
    });
  });

  group('computer home card', () {
    late FakeMirrorControl control;
    late InboxViewModel inbox;
    late NotificationsFeature feature;

    setUp(() async {
      control = FakeMirrorControl();
      inbox = InboxViewModel(
        feature: control,
        notifier: FakeNotifier(),
        deviceName: (_) => 'Pixel',
        strings: platformNotificationsL10n,
      );
      feature = NotificationsFeature();
      await feature.start(SettingsOnlyHost());
    });

    tearDown(() => inbox.dispose());

    Future<void> pumpCard(WidgetTester tester) async {
      await tester.pumpWidget(
        testApp(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: inbox),
              ChangeNotifierProvider(
                create: (_) => PhonesViewModel(
                  feature: feature,
                  sessionChanges: const Stream.empty(),
                ),
              ),
            ],
            child: const InboxCardFrame(),
          ),
        ),
      );
    }

    testWidgets('says how to start with no phone connected', (tester) async {
      await pumpCard(tester);

      expect(
        find.text('Connect your Android phone to see its notifications here.'),
        findsOneWidget,
      );
      expect(find.text('Clear all'), findsNothing);
    });

    testWidgets('shows the last three per phone and clears them', (
      tester,
    ) async {
      await pumpCard(tester);

      for (final key in ['a', 'b', 'c', 'd']) {
        control.emit(MirrorPosted('phone', mirrored(key: key, title: key)));
      }
      await tester.pump();

      expect(find.text('Pixel · offline'), findsOneWidget);
      expect(find.byType(NotificationRow), findsNWidgets(3));
      expect(find.textContaining('d · '), findsOneWidget);
      expect(find.textContaining('a · '), findsNothing);

      await tester.tap(find.text('Clear all'));
      await tester.pump();

      expect(find.byType(NotificationRow), findsNothing);
    });

    testWidgets('dismissing a row dismisses on the phone', (tester) async {
      await pumpCard(tester);
      control.emit(MirrorPosted('phone', mirrored()));
      await tester.pump();

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();

      expect(control.dismissed, [('phone', 'k1')]);
      expect(find.byType(NotificationRow), findsNothing);
    });
  });

  group('app picker', () {
    testWidgets('lists messaging apps first and saves a choice', (
      tester,
    ) async {
      final saved = <(String, bool)>[];
      await tester.pumpWidget(
        testApp(
          scroll: false,
          AppPickerPage(
            deviceName: 'Pixel',
            load: () async => [
              AppEntry(package: game, name: 'Game'),
              AppEntry(
                package: signal,
                name: 'Signal',
                allowed: true,
                isMessaging: true,
              ),
            ],
            save: (package, allowed) async => saved.add((package, allowed)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MESSAGING APPS'), findsOneWidget);
      expect(find.text('OTHER APPS'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Signal')).dy,
        lessThan(tester.getTopLeft(find.text('Game')).dy),
      );

      await tester.tap(find.byType(SwitchToggle).last);
      await tester.pumpAndSettle();

      expect(saved, [(game, true)]);
    });

    testWidgets('explains a failed load with a retry', (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        testApp(
          scroll: false,
          AppPickerPage(
            deviceName: 'Pixel',
            load: () async {
              attempts++;
              throw StateError('offline');
            },
            save: (_, _) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Couldn't get the apps from Pixel. Make sure it's connected.",
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
    });
  });
}
