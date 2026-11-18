import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notifications/notifications.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'support/fakes.dart';

/// A computer's feature whose phones are played by the test.
class _ScriptedFeature extends NotificationsFeature {
  final StreamController<MirrorEvent> events = .broadcast(sync: true);

  @override
  Stream<MirrorEvent> get mirrorEvents => events.stream;
}

MirroredNotification _notification({
  String deviceId = 'phone',
  String key = 'k1',
  String appName = 'Signal',
  String title = 'Alex',
  String text = 'Are you coming?',
  DateTime? postedAt,
}) => MirroredNotification(
  deviceId: deviceId,
  key: key,
  appPackage: signal,
  appName: appName,
  title: title,
  text: text,
  postedAt: postedAt ?? DateTime(2026, 11, 18, 9, 30),
  isConversation: false,
);

void main() {
  final l10n = lookupNotificationsLocalizations(const Locale('en'));

  List<ActivityItem> itemsFor(
    Map<String, List<MirroredNotification>> byDevice, {
    VoidCallback? onOpen,
  }) => NotificationsActivity.items(
    l10n,
    byDevice,
    deviceName: (deviceId) => switch (deviceId) {
      'phone' => 'Pixel 9',
      _ => 'Galaxy',
    },
    onOpen: onOpen ?? () {},
  );

  group('NotificationsActivity.items', () {
    test('has no lines with nothing waiting', () {
      expect(itemsFor(const {}), isEmpty);
      expect(itemsFor(const {'phone': []}), isEmpty);
    });

    test('a single notification shows its app, title and text', () {
      final item = itemsFor({
        'phone': [_notification()],
      }).single;

      expect(item.id, 'phone');
      expect(item.icon, LucideIcons.bell);
      expect(item.title, 'Signal: Alex');
      expect(item.detail, 'Are you coming?');
      expect(item.at, DateTime(2026, 11, 18, 9, 30));
      expect(item.pinned, isFalse);
      expect(item.actions, isEmpty);
    });

    test('several from one phone become one line with the count', () {
      final item = itemsFor({
        'phone': [
          _notification(
            key: 'new',
            text: 'On my way',
            postedAt: DateTime(2026, 11, 18, 9, 45),
          ),
          _notification(key: 'old'),
          _notification(key: 'older'),
        ],
      }).single;

      expect(item.title, '3 notifications from Pixel 9');
      expect(item.detail, 'On my way');
      expect(item.at, DateTime(2026, 11, 18, 9, 45));
    });

    test('each phone has its own line', () {
      final items = itemsFor({
        'phone': [_notification()],
        'other': [
          _notification(deviceId: 'other', key: 'a'),
          _notification(deviceId: 'other', key: 'b'),
        ],
      });

      expect(items.map((item) => item.id), ['phone', 'other']);
      expect(items.last.title, '2 notifications from Galaxy');
    });

    test('leaves out what the notification does not have', () {
      final untitled = itemsFor({
        'phone': [_notification(title: '', text: '')],
      }).single;
      final unnamed = itemsFor({
        'phone': [_notification(appName: '')],
      }).single;

      expect(untitled.title, 'Signal');
      expect(untitled.detail, isNull);
      expect(unnamed.title, 'Alex');
    });

    test('tapping a line opens the list', () {
      var opened = 0;
      final item = itemsFor({
        'phone': [_notification()],
      }, onOpen: () => opened++).single;

      item.onTap?.call();

      expect(opened, 1);
    });
  });

  group('on a computer', () {
    late FerretEngine engine;
    late _ScriptedFeature feature;
    late NotificationsFeatureUi ui;
    late FeatureContext featureContext;
    final navigatorKey = GlobalKey<NavigatorState>();

    Future<void> start() async {
      feature = _ScriptedFeature();
      engine = await FerretEngine.create(
        secrets: MemorySecretStore(),
        settings: MemorySettingsStore(),
        device: const LocalDevice(
          name: 'Laptop',
          platform: .PLATFORM_LINUX,
          formFactor: .FORM_FACTOR_LAPTOP,
        ),
        features: [feature],
        discovery: Bus().join(),
        port: 0,
      );
      await engine.start();
      ui = NotificationsFeatureUi.withFeature(feature);
      featureContext = FeatureContext(
        engine: engine,
        navigatorKey: navigatorKey,
        notifier: FakeNotifier(),
      );
      await ui.onAppStarted(featureContext);
    }

    Future<void> stop() async {
      ui.dispose();
      await engine.stop();
    }

    testWidgets('notifications are a line in Activity that opens them all', (
      tester,
    ) async {
      await tester.runAsync(start);
      addTearDown(() => tester.runAsync(stop));
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFFFFFFFF),
          navigatorKey: navigatorKey,
          localizationsDelegates: const [
            NotificationsLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: NotificationsLocalizations.supportedLocales,
          builder: (context, child) => FluffyTheme(
            data: FluffyThemeData.fallback(),
            child: DefaultTextStyle(
              style: const TextStyle(),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => const SizedBox.expand(),
          ),
        ),
      );
      final context = tester.element(find.byType(SizedBox));
      var changes = 0;
      ui.uiChanges?.addListener(() => changes++);

      expect(ui.activity(context, featureContext), isEmpty);

      for (final key in ['a', 'b', 'c', 'd']) {
        feature.events.add(
          MirrorPosted('phone', _notification(key: key, title: key)),
        );
      }

      final item = ui.activity(context, featureContext).single;
      expect(changes, greaterThan(0));
      expect(ui.hasHomeCard(featureContext), isFalse);
      expect(ui.buildHomeCard(context, featureContext), isNull);
      expect(item.title, '4 notifications from phone');

      item.onTap?.call();
      await tester.pumpAndSettle();

      expect(find.byType(InboxPage), findsOneWidget);
      expect(find.byType(NotificationRow), findsNWidgets(4));
    });
  });
}
