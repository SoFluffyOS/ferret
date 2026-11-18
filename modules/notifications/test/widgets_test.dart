import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:fixnum/fixnum.dart';
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
          "Shows this phone's notifications on your computer. Every app "
          "comes through, and you can mute the ones you don't want.",
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
        expect(feature.preferences.appFilter, AppFilter.APP_FILTER_ALL);
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
      await pumpSetup(tester);

      expect(find.text('Notification access is on'), findsOneWidget);
      expect(find.text("Pause while I'm using the phone"), findsOneWidget);
      expect(find.text('Choose apps · All apps'), findsOneWidget);
    });

    testWidgets('picks saved before filters still read as only these', (
      tester,
    ) async {
      source.accessGranted = true;
      await settings.set(MirrorPreferences.enabledKey, true);
      await settings.set(MirrorPreferences.allowedAppsKey, [signal, game]);
      await pumpSetup(tester);

      expect(find.text('Choose apps · 2 apps'), findsOneWidget);
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
        "See this phone's notifications on your computer.",
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
        find.text(
          'Notification access is off on this phone, so your computer gets '
          'no notifications.',
        ),
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
    late ConnectedHost host;

    setUp(() async {
      control = FakeMirrorControl();
      inbox = InboxViewModel(
        feature: control,
        notifier: FakeNotifier(),
        deviceName: (_) => 'Pixel',
        strings: platformNotificationsL10n,
      );
      host = ConnectedHost();
      feature = NotificationsFeature();
      await feature.start(host);
    });

    tearDown(() => inbox.dispose());

    Future<void> pumpCard(
      WidgetTester tester, {
      List<PairedPhone> paired = const [],
    }) async {
      await tester.pumpWidget(
        testApp(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: inbox),
              ChangeNotifierProvider(
                create: (_) => PhonesViewModel(
                  feature: feature,
                  sessionChanges: const Stream.empty(),
                  pairedPhones: () => paired,
                ),
              ),
            ],
            child: const InboxCardFrame(),
          ),
        ),
      );
    }

    testWidgets('says when the paired phone is offline', (tester) async {
      await pumpCard(tester, paired: [(deviceId: 'phone', name: 'Pixel 9')]);

      expect(
        find.text(
          "Pixel 9 is offline. Notifications show here when it's back.",
        ),
        findsOneWidget,
      );
      expect(find.text('How?'), findsNothing);
      expect(find.text('Clear all'), findsNothing);
    });

    testWidgets(
      'asks to turn mirroring on on a connected phone, and says where',
      (tester) async {
        host.connected.add('phone');
        await pumpCard(tester, paired: [(deviceId: 'phone', name: 'Pixel 9')]);

        expect(
          find.text(
            'Turn on Notifications on Pixel 9 to see its notifications here.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Connect your Android'), findsNothing);

        await tester.tap(find.text('How?'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Ferret → Do more → Notifications'),
          findsOneWidget,
        );
      },
    );

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
    AppEntry entry(String package, String name, {int lastPostedMs = 0}) =>
        AppEntry(
          package: package,
          name: name,
          lastPostedMs: Int64(lastPostedMs),
          isMessaging: package == signal,
        );

    Future<List<UpdateMirrorSettings>> pumpPicker(
      WidgetTester tester,
      MirrorSettings settings,
    ) async {
      final updates = <UpdateMirrorSettings>[];
      var current = settings;
      await tester.pumpWidget(
        testApp(
          scroll: false,
          AppPickerPage(
            deviceName: 'Pixel',
            load: () async => (
              settings: current,
              apps: [
                entry(signal, 'Signal'),
                entry(game, 'Game', lastPostedMs: 2000),
                entry('com.bank', 'Bank', lastPostedMs: 1000),
              ],
            ),
            update: (update) async {
              updates.add(update);
              current = current.withUpdate(update);
              return current;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return updates;
    }

    testWidgets('leads with all apps and hides the list', (tester) async {
      await pumpPicker(tester, MirrorSettings(appFilter: .APP_FILTER_ALL));

      expect(find.text('All apps'), findsOneWidget);
      expect(find.text('All apps except…'), findsOneWidget);
      expect(find.text('Only these apps…'), findsOneWidget);
      expect(find.text('Game'), findsNothing);
    });

    testWidgets('muting an app lists apps by recent activity', (tester) async {
      final updates = await pumpPicker(
        tester,
        MirrorSettings(appFilter: .APP_FILTER_ALL),
      );

      await tester.tap(find.text('All apps except…'));
      await tester.pumpAndSettle();

      expect(updates.single.appFilter, AppFilter.APP_FILTER_ALL_EXCEPT);
      final gameTop = tester.getTopLeft(find.text('Game')).dy;
      final bankTop = tester.getTopLeft(find.text('Bank')).dy;
      final signalTop = tester.getTopLeft(find.text('Signal')).dy;
      expect(gameTop, lessThan(bankTop));
      expect(bankTop, lessThan(signalTop));

      await tester.tap(find.byType(SwitchToggle).first);
      await tester.pumpAndSettle();

      expect(updates.last.apps.single.package, game);
      expect(updates.last.apps.single.allowed, isFalse);
    });

    testWidgets('select none, then search and select all', (tester) async {
      final updates = await pumpPicker(
        tester,
        MirrorSettings(appFilter: .APP_FILTER_ONLY, allowedPackages: [signal]),
      );

      await tester.tap(find.text('Select none'));
      await tester.pumpAndSettle();
      expect(updates.last.apps.map((choice) => choice.allowed), [
        false,
        false,
        false,
      ]);

      await tester.enterText(find.byType(EditableText), 'ban');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();

      expect(updates.last.apps.single.package, 'com.bank');
      expect(updates.last.apps.single.allowed, isTrue);
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
            update: (_) async => MirrorSettings(),
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
