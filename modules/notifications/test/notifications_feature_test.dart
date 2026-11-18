import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_notifications/ferret_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';
import 'package:protocol/notifications.dart';

import 'support/fakes.dart';

void main() {
  late Bus bus;
  final engines = <FerretEngine>[];

  setUp(() => bus = Bus());

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
  });

  Future<FerretEngine> startEngine(
    String name,
    NotificationsFeature feature, {
    MemorySecretStore? secrets,
    MemorySettingsStore? settings,
  }) async {
    final engine = await FerretEngine.create(
      secrets: secrets ?? MemorySecretStore(),
      settings: settings ?? MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      features: [feature],
      discovery: bus.join(),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  Future<void> pair(FerretEngine phone, FerretEngine laptop) async {
    final handle = await laptop.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    if (offer == null) {
      fail('The offer did not parse');
    }

    offer
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await phone.pairWithOffer(offer), isA<Paired>());
    await until(() => laptop.sessions.isNotEmpty && phone.sessions.isNotEmpty);
  }

  group('with a phone and a laptop', () {
    late FakeNotificationSource source;
    late NotificationsFeature phoneFeature;
    late NotificationsFeature laptopFeature;
    late FerretEngine phone;
    late FerretEngine laptop;
    late List<MirrorEvent> received;

    Future<void> connect() async {
      source = FakeNotificationSource();
      phoneFeature = NotificationsFeature(source: source);
      laptopFeature = NotificationsFeature();
      received = [];
      laptopFeature.mirrorEvents.listen(received.add);

      phone = await startEngine(
        'Phone',
        phoneFeature,
        settings: MemorySettingsStore({MirrorPreferences.enabledKey: true}),
      );
      laptop = await startEngine('Laptop', laptopFeature);
      await pair(phone, laptop);
      await until(() => received.whereType<MirrorCaughtUp>().isNotEmpty);
    }

    String phoneId() => phone.identity.deviceId;

    List<MirroredNotification> posted() => [
      for (final event in received.whereType<MirrorPosted>())
        event.notification,
    ];

    test('the phone sends and the laptop receives', () async {
      await connect();

      expect(phoneFeature.flags, [NotificationsFeature.sendFlag]);
      expect(laptopFeature.flags, [NotificationsFeature.receiveFlag]);
      expect(laptopFeature.senders.single.remoteDeviceId, phoneId());
    });

    test(
      'notifications posted before the session opened are never replayed',
      () async {
        await connect();
        final beforeSession = DateTime.now()
            .subtract(const Duration(minutes: 5))
            .millisecondsSinceEpoch;

        source.post(phoneNotification(key: 'old', postedAtMs: beforeSession));
        source.post(phoneNotification(key: 'new'));

        await until(() => posted().isNotEmpty);
        await pumpEventQueue();
        expect(posted().map((item) => item.key), ['new']);
      },
    );

    test('the computer shows the phone health, and no home card', () async {
      await connect();
      await until(() => laptopFeature.senderSettings.containsKey(phoneId()));
      final ui = NotificationsFeatureUi.withFeature(laptopFeature);
      final context = FeatureContext(
        engine: laptop,
        navigatorKey: GlobalKey<NavigatorState>(),
        notifier: FakeNotifier(),
      );
      await ui.onAppStarted(context);
      addTearDown(ui.dispose);
      var changes = 0;
      ui.uiChanges?.addListener(() => changes++);

      source.post(phoneNotification());
      await until(() => posted().isNotEmpty);
      await pumpEventQueue();

      final health = ui.healthFor(context, laptop.devices.single);
      expect(health?.state, FeatureHealthState.ok);
      expect(health?.reason, 'All apps');
      expect(ui.hasHomeCard(context), isFalse);
      expect(changes, greaterThan(0));
    });

    test('the health chip says when mirroring is off on the phone', () async {
      await connect();
      await until(() => laptopFeature.senderSettings.containsKey(phoneId()));
      final ui = NotificationsFeatureUi.withFeature(laptopFeature);
      final context = FeatureContext(
        engine: laptop,
        navigatorKey: GlobalKey<NavigatorState>(),
        notifier: FakeNotifier(),
      );

      await phone.settings.set(MirrorPreferences.enabledKey, false);
      await until(
        () => laptopFeature.senderSettings[phoneId()]?.enabled == false,
      );

      final health = ui.healthFor(context, laptop.devices.single);
      expect(health?.state, FeatureHealthState.off);
      expect(health?.reason, startsWith('Off on '));
      expect(
        ui.healthFor(context, DeviceStatus(laptop.devices.single.device, null)),
        isNull,
      );
    });

    test('the same content is sent once, a change is sent again', () async {
      await connect();

      source
        ..post(phoneNotification())
        ..post(phoneNotification())
        ..post(phoneNotification(text: 'Running late'));

      await until(() => posted().length == 2);
      await pumpEventQueue();
      expect(posted().map((item) => item.text), [
        'Are you coming?',
        'Running late',
      ]);
      expect(posted().first.appIcon, isNotNull);
      expect(posted().last.appIcon, isNotNull);
    });

    test('noise and muted apps stay on the phone', () async {
      await connect();
      await phoneFeature.applySettings(
        UpdateMirrorSettings(
          appFilter: .APP_FILTER_ALL_EXCEPT,
          apps: [AppChoice(package: game)],
        ),
      );

      source
        ..post(phoneNotification(key: 'game', packageName: game))
        ..post(phoneNotification(key: 'ongoing', isOngoing: true))
        ..post(phoneNotification(key: 'quiet', importance: 2))
        ..post(phoneNotification(key: 'summary', isGroupSummary: true))
        ..post(phoneNotification(key: 'media', isMedia: true))
        ..post(phoneNotification(key: 'chat'));

      await until(() => posted().isNotEmpty);
      await pumpEventQueue();
      expect(posted().map((item) => item.key), ['chat']);

      await phoneFeature.applySettings(
        UpdateMirrorSettings(
          apps: [AppChoice(package: game, allowed: true)],
        ),
      );
      source.post(phoneNotification(key: 'game-2', packageName: game));

      await until(() => posted().length == 2);
      expect(posted().last.key, 'game-2');
    });

    test('nothing is mirrored while the phone is in use', () async {
      await connect();
      source.deviceInUse = true;

      source.post(phoneNotification(key: 'seen'));
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(posted(), isEmpty);

      source.deviceInUse = false;
      source.post(phoneNotification(key: 'unseen'));
      await until(() => posted().isNotEmpty);
      expect(posted().single.key, 'unseen');
    });

    test('dismissing on the laptop dismisses on the phone', () async {
      await connect();
      source.post(phoneNotification());
      await until(() => posted().isNotEmpty);

      expect(await laptopFeature.dismiss(phoneId(), 'k1'), isTrue);

      await until(() => received.whereType<MirrorRemoved>().isNotEmpty);
      expect(source.cancelled, ['k1']);
      expect(received.whereType<MirrorRemoved>().single.key, 'k1');
    });

    test('dismissing on the phone removes it on the laptop', () async {
      await connect();
      await phoneFeature.applySettings(
        UpdateMirrorSettings(apps: [AppChoice(package: game)]),
      );
      source
        ..post(phoneNotification())
        ..post(phoneNotification(key: 'never-sent', packageName: game));
      await until(() => posted().isNotEmpty);

      source
        ..remove('k1')
        ..remove('never-sent');

      await until(() => received.whereType<MirrorRemoved>().isNotEmpty);
      await pumpEventQueue();
      expect(received.whereType<MirrorRemoved>().map((event) => event.key), [
        'k1',
      ]);
    });

    test('a reply goes to the right notification and action', () async {
      await connect();
      source.post(phoneNotification());
      await until(() => posted().isNotEmpty);
      final notification = posted().single;
      final reply = notification.replyAction;
      if (reply == null) {
        fail('The notification lost its reply action');
      }

      final sent = await laptopFeature.invokeAction(
        phoneId(),
        notification.key,
        reply.id,
        replyText: 'On my way',
      );

      expect(sent, isTrue);
      expect(source.invoked, [('k1', '0', 'On my way')]);
    });

    test('a failed action is reported', () async {
      await connect();
      source.actionResult = false;

      final sent = await laptopFeature.invokeAction(phoneId(), 'gone', '1');

      expect(sent, isFalse);
      expect(source.invoked, [('gone', '1', null)]);
    });

    test('the laptop reads and changes the phone settings', () async {
      await connect();
      await until(() => laptopFeature.senderSettings.containsKey(phoneId()));
      source.apps = [
        PlatformApp(packageName: signal, name: 'Signal'),
        PlatformApp(packageName: game, name: 'Game'),
      ];

      final apps = await laptopFeature.fetchApps(phoneId());
      final settings = await laptopFeature.updateSettings(
        phoneId(),
        UpdateMirrorSettings(
          skipWhileUsing: false,
          apps: [AppChoice(package: signal, allowed: false)],
        ),
      );

      expect(
        [for (final app in apps) (app.package, app.allowed)],
        [
          (signal, true),
          (game, true),
        ],
      );
      expect(apps.first.isMessaging, isTrue);
      expect(settings.skipWhileUsing, isFalse);
      expect(settings.appFilter, AppFilter.APP_FILTER_ALL_EXCEPT);
      expect(settings.excludedPackages, [signal]);
      expect(phoneFeature.preferences.isAllowed(signal), isFalse);
      expect(phoneFeature.preferences.skipWhileUsing, isFalse);
    });

    test(
      'reconnecting sends one summary of what came while away, not a replay',
      () async {
        final laptopSecrets = MemorySecretStore();
        final laptopSettings = MemorySettingsStore();
        source = FakeNotificationSource();
        phoneFeature = NotificationsFeature(source: source);
        laptopFeature = NotificationsFeature();
        received = [];
        laptopFeature.mirrorEvents.listen(received.add);
        phone = await startEngine(
          'Phone',
          phoneFeature,
          settings: MemorySettingsStore({MirrorPreferences.enabledKey: true}),
        );
        laptop = await startEngine(
          'Laptop',
          laptopFeature,
          secrets: laptopSecrets,
          settings: laptopSettings,
        );
        await pair(phone, laptop);
        source
          ..post(phoneNotification(key: 'kept'))
          ..post(phoneNotification(key: 'dismissed-while-away'));
        await until(() => posted().length == 2);

        await laptop.stop();
        await until(() => phone.sessions.isEmpty);
        source
          ..remove('dismissed-while-away')
          ..post(phoneNotification(key: 'a', appName: 'Signal'))
          ..post(phoneNotification(key: 'b', appName: 'Signal'))
          ..post(phoneNotification(key: 'c', appName: 'Signal', title: 'Sam'))
          ..remove('c');
        await pumpEventQueue();

        final again = NotificationsFeature();
        final afterReconnect = <MirrorEvent>[];
        again.mirrorEvents.listen(afterReconnect.add);
        await startEngine(
          'Laptop',
          again,
          secrets: laptopSecrets,
          settings: laptopSettings,
        );
        await until(
          () => afterReconnect.whereType<MirrorCaughtUp>().isNotEmpty,
        );
        await pumpEventQueue();

        final catchUp = afterReconnect.whereType<MirrorCaughtUp>().single;
        expect(catchUp.missedCount, 2);
        expect(catchUp.missedAppNames, ['Signal']);
        expect(catchUp.activeKeys, {'kept'});
        expect(afterReconnect.whereType<MirrorPosted>(), isEmpty);
      },
    );
  });

  test('a computer refuses phone requests', () async {
    final laptopA = NotificationsFeature();
    final laptopB = NotificationsFeature();
    final first = await startEngine('A', laptopA);
    final second = await startEngine('B', laptopB);
    await pair(first, second);

    expect(laptopA.senders, isEmpty);
    await expectLater(
      first.sessions.single.call(
        NotificationsFeature.featureId,
        AppListRequest(),
        AppListResponse.new,
      ),
      throwsA(isA<RemoteErrorException>()),
    );
  });
}
