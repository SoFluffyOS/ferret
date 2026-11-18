import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:ferret_iphone/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iphone/iphone.dart';

import 'helpers/fakes.dart';

void main() {
  const delays = [Duration(seconds: 5), Duration(seconds: 10)];

  /// Runs [body] with a started rig under fake time.
  void withRig(
    void Function(FakeAsync async, Rig rig) body, {
    Map<String, Object?>? settings,
    FakeAppleTransport? transport,
    Duration connectTimeout = const Duration(seconds: 25),
  }) {
    fakeAsync((async) {
      late Rig rig;
      Rig.start(
        settings: settings,
        transport: transport,
        retryDelays: delays,
        connectTimeout: connectTimeout,
      ).then((started) => rig = started);
      async.flushMicrotasks();

      body(async, rig);

      rig.feature.stop();
      async.flushMicrotasks();
      expect(async.pendingTimers, isEmpty);
    });
  }

  test('stays off, and off Bluetooth, until the person turns it on', () {
    withRig((async, rig) {
      expect(rig.feature.link.phase, LinkPhase.off);
      expect(rig.transport.connects, isEmpty);
    });
  });

  test('asks for an iPhone when none is picked', () {
    withRig((async, rig) {
      expect(rig.feature.link.phase, LinkPhase.noDevice);
      expect(rig.feature.link.needsAttention, isTrue);
      expect(rig.transport.connects, isEmpty);
    }, settings: {IphoneSettings.enabledKey: true});
  });

  test('connects to the picked iPhone and subscribes to both services', () {
    withRig((async, rig) {
      final link = rig.feature.link;

      expect(link.phase, LinkPhase.connected);
      expect(link.deviceName, iphoneDevice.name);
      expect(link.hasNotifications, isTrue);
      expect(link.hasMedia, isTrue);
      expect(rig.transport.connects, [iphoneDevice.id]);
      expect(rig.transport.notifying, {
        AppleCharacteristic.dataSource,
        AppleCharacteristic.notificationSource,
        AppleCharacteristic.remoteCommand,
        AppleCharacteristic.entityUpdate,
      });
    }, settings: pairedSettings());
  });

  test('picking the iPhone connects without a restart', () {
    withRig((async, rig) {
      rig.feature.chooseDevice(iphoneDevice);
      async.flushMicrotasks();

      expect(rig.feature.link.phase, LinkPhase.connected);
      expect(rig.feature.link.deviceName, iphoneDevice.name);

      rig.feature.forgetDevice();
      async.flushMicrotasks();

      expect(rig.feature.link.phase, LinkPhase.noDevice);
      expect(rig.transport.connectedTo, isNull);
    }, settings: {IphoneSettings.enabledKey: true});
  });

  test('leaves out what the person turned off', () {
    withRig((async, rig) {
      expect(rig.feature.link.hasNotifications, isFalse);
      expect(rig.feature.link.hasMedia, isTrue);
      expect(
        rig.transport.notifying,
        isNot(contains(AppleCharacteristic.notificationSource)),
      );

      rig.feature.settings.setShowNotifications(true);
      async.flushMicrotasks();

      expect(rig.feature.link.hasNotifications, isTrue);
    }, settings: pairedSettings({IphoneSettings.showNotificationsKey: false}));
  });

  test('says Bluetooth is off, and connects once it is back on', () {
    withRig(
      (async, rig) {
        expect(rig.feature.link.phase, LinkPhase.bluetoothOff);
        expect(rig.transport.connects, isEmpty);

        rig.transport.statusNow = .ready;
        async.elapse(delays.first);

        expect(rig.feature.link.phase, LinkPhase.connected);
      },
      settings: pairedSettings(),
      transport: FakeAppleTransport(statusNow: .off),
    );
  });

  test('a denied permission waits for the person, without retrying', () {
    withRig(
      (async, rig) {
        expect(rig.feature.link.phase, LinkPhase.unauthorized);
        expect(async.pendingTimers, isEmpty);

        rig.transport.statusNow = .ready;
        rig.feature.refresh();
        async.flushMicrotasks();

        expect(rig.feature.link.phase, LinkPhase.connected);
      },
      settings: pairedSettings(),
      transport: FakeAppleTransport(statusNow: .unauthorized),
    );
  });

  test('reports a computer without Bluetooth and a build without access', () {
    withRig(
      (async, rig) => expect(rig.feature.link.phase, LinkPhase.unsupported),
      settings: pairedSettings(),
      transport: FakeAppleTransport(statusNow: .unsupported),
    );
    withRig(
      (async, rig) => expect(rig.feature.link.phase, LinkPhase.notConfigured),
      settings: pairedSettings(),
      transport: FakeAppleTransport(statusNow: .notConfigured),
    );
  });

  test('keeps trying an iPhone that is out of reach, with longer waits', () {
    withRig(
      (async, rig) {
        expect(rig.feature.link.phase, LinkPhase.outOfReach);
        expect(rig.transport.connects, hasLength(1));

        async.elapse(const Duration(seconds: 5));
        expect(rig.transport.connects, hasLength(2));

        async.elapse(const Duration(seconds: 9));
        expect(rig.transport.connects, hasLength(2));

        async.elapse(const Duration(seconds: 1));
        expect(rig.transport.connects, hasLength(3));

        rig.transport.connectError = null;
        async.elapse(const Duration(seconds: 10));

        expect(rig.feature.link.phase, LinkPhase.connected);
      },
      settings: pairedSettings(),
      transport: FakeAppleTransport()
        ..connectError = const GattException(.notConnected),
    );
  });

  test('gives up on an attempt the iPhone never answers', () {
    final never = Completer<void>();
    withRig(
      (async, rig) {
        expect(rig.feature.link.phase, LinkPhase.connecting);

        async.elapse(const Duration(seconds: 3));

        expect(rig.feature.link.phase, LinkPhase.outOfReach);
        expect(rig.transport.disconnectCount, greaterThan(0));
      },
      settings: pairedSettings(),
      transport: FakeAppleTransport()..connectHold = never.future,
      connectTimeout: const Duration(seconds: 3),
    );
  });

  test('an iPhone that refuses to subscribe is not sharing', () {
    withRig(
      (async, rig) {
        expect(rig.feature.link.phase, LinkPhase.notShared);
        expect(rig.feature.link.needsAttention, isTrue);
        expect(rig.transport.connectedTo, isNull);
      },
      settings: pairedSettings(),
      transport: FakeAppleTransport()
        ..notifyError = const GattException(.notBonded),
    );
  });

  test('a device without the Apple services is not sharing', () {
    withRig(
      (async, rig) => expect(rig.feature.link.phase, LinkPhase.notShared),
      settings: pairedSettings(),
      transport: FakeAppleTransport(services: const AppleServices()),
    );
  });

  test('connects with media only when notifications are held back', () {
    withRig(
      (async, rig) {
        expect(rig.feature.link.phase, LinkPhase.connected);
        expect(rig.feature.link.hasNotifications, isFalse);
        expect(rig.feature.link.hasMedia, isTrue);
      },
      settings: pairedSettings(),
      transport: FakeAppleTransport(
        services: const AppleServices(hasAms: true),
      ),
    );
  });

  test('comes back by itself after the iPhone was away', () {
    withRig((async, rig) {
      rig.iphone.play(title: 'Song');
      expect(rig.feature.media.hasTrack, isTrue);

      rig.transport.drop();
      async.flushMicrotasks();

      expect(rig.feature.link.phase, LinkPhase.outOfReach);
      expect(rig.feature.media.hasTrack, isFalse);

      async.elapse(delays.first);

      expect(rig.feature.link.phase, LinkPhase.connected);
      expect(rig.transport.connects, hasLength(2));
    }, settings: pairedSettings());
  });

  test('coming back to the app leaves a working link alone', () {
    withRig((async, rig) {
      rig.feature.refresh();
      async.flushMicrotasks();

      expect(rig.transport.connects, hasLength(1));
    }, settings: pairedSettings());
  });

  test('turning it off closes the link', () {
    withRig((async, rig) {
      rig.feature.settings.setEnabled(false);
      async.flushMicrotasks();

      expect(rig.feature.link.phase, LinkPhase.off);
      expect(rig.transport.connectedTo, isNull);
    }, settings: pairedSettings());
  });

  test('on Linux, invites the iPhone only while waiting for it', () {
    withRig(
      (async, rig) {
        expect(rig.transport.inviting, isTrue);
        expect(rig.feature.invitesIphone, isTrue);

        rig.feature.chooseDevice(iphoneDevice);
        async.flushMicrotasks();

        expect(rig.feature.link.phase, LinkPhase.connected);
        expect(rig.transport.inviting, isFalse);

        rig.transport.drop();
        async.flushMicrotasks();

        expect(rig.transport.inviting, isTrue);

        rig.feature.settings.setEnabled(false);
        async.flushMicrotasks();

        expect(rig.transport.inviting, isFalse);
      },
      settings: {IphoneSettings.enabledKey: true},
      transport: FakeAppleTransport(canInvite: true),
    );
  });

  test('stopping disposes the transport', () {
    late FakeAppleTransport transport;
    withRig(
      (async, rig) => transport = rig.transport,
      settings: pairedSettings(),
    );

    expect(transport.disposed, isTrue);
  });
}
