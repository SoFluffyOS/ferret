import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_notifications/ferret_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

/// A phone's notification listener driven by the test.
class FakeNotificationSource implements NotificationSource, NotificationAccess {
  final StreamController<NotificationEvent> _events = .broadcast(sync: true);

  bool accessGranted = true;
  bool restricted = false;
  bool deviceInUse = false;
  bool actionResult = true;
  int openedAccessSettings = 0;
  int openedAppInfo = 0;
  List<PlatformApp> apps = [];
  final List<String> cancelled = [];
  final List<(String, String, String?)> invoked = [];

  void post(PlatformNotification notification) =>
      _events.add(NotificationPostedEvent(notification));

  void remove(String key) => _events.add(NotificationRemovedEvent(key));

  @override
  Stream<NotificationEvent> get events => _events.stream;

  @override
  Future<bool> isAccessGranted() async => accessGranted;

  @override
  Future<bool> mayBeRestricted() async => restricted;

  @override
  Future<void> openAccessSettings() async => openedAccessSettings++;

  @override
  Future<void> openAppInfo() async => openedAppInfo++;

  @override
  Future<bool> isDeviceInUse() async => deviceInUse;

  @override
  Future<List<PlatformApp>> listApps() async => apps;

  @override
  Future<bool> invokeAction(
    String key,
    String actionId, {
    String? replyText,
  }) async {
    invoked.add((key, actionId, replyText));
    return actionResult;
  }

  @override
  Future<bool> cancel(String key) async {
    cancelled.add(key);
    remove(key);
    return true;
  }
}

/// A [LocalNotifier] that records what it was asked to show.
class FakeNotifier implements LocalNotifier {
  final Map<String, LocalNotice> shown = {};
  final List<LocalNotice> history = [];
  final List<String> cancelled = [];
  final StreamController<NoticeResponse> _responses = .broadcast(sync: true);

  void respond(NoticeResponse response) => _responses.add(response);

  @override
  Future<void> show(LocalNotice notice) async {
    shown[notice.id] = notice;
    history.add(notice);
  }

  @override
  Future<void> cancel(String id) async {
    shown.remove(id);
    cancelled.add(id);
  }

  @override
  Stream<NoticeResponse> get responses => _responses.stream;
}

/// A [MirrorControl] the test drives by hand.
class FakeMirrorControl implements MirrorControl {
  final StreamController<MirrorEvent> _events = .broadcast(sync: true);
  final List<(String, String)> dismissed = [];
  final List<(String, String, String, String?)> invoked = [];
  bool actionResult = true;

  void emit(MirrorEvent event) => _events.add(event);

  @override
  Stream<MirrorEvent> get mirrorEvents => _events.stream;

  @override
  Future<bool> dismiss(String deviceId, String key) async {
    dismissed.add((deviceId, key));
    return true;
  }

  @override
  Future<bool> invokeAction(
    String deviceId,
    String key,
    String actionId, {
    String? replyText,
  }) async {
    invoked.add((deviceId, key, actionId, replyText));
    return actionResult;
  }
}

/// A [FeatureHost] with only settings, for a feature with no sessions.
class SettingsOnlyHost implements FeatureHost {
  @override
  Presence get localPresence => Presence(batteryPercent: -1);

  @override
  Stream<Presence> get localPresenceChanges => const Stream.empty();

  SettingsOnlyHost([MemorySettingsStore? settings])
    : settings = settings ?? MemorySettingsStore();

  @override
  final MemorySettingsStore settings;

  @override
  List<Session> get sessions => const [];

  @override
  Session? sessionFor(String deviceId) => null;

  @override
  Stream<List<Session>> get sessionChanges => const Stream.empty();

  @override
  Future<void> broadcast(String featureId, GeneratedMessage message) async {}

  @override
  DeviceIdentity get identity => throw UnimplementedError();

  @override
  DeviceInfo get localDevice => throw UnimplementedError();

  @override
  final TrustStore trustStore = TrustStore.memory();
}

/// A [SettingsOnlyHost] where the devices in [connected] have a session that
/// doesn't offer mirroring.
class ConnectedHost extends SettingsOnlyHost {
  final Set<String> connected = {};

  @override
  Session? sessionFor(String deviceId) =>
      switch (connected.contains(deviceId)) {
        true => _IdleSession(),
        false => null,
      };
}

class _IdleSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const signal = 'org.thoughtcrime.securesms';
const game = 'com.example.game';

/// A notification as the Android listener reports it.
PlatformNotification phoneNotification({
  String key = 'k1',
  String packageName = signal,
  String appName = 'Signal',
  String title = 'Alex',
  String text = 'Are you coming?',
  int? postedAtMs,
  bool isOngoing = false,
  bool isForegroundService = false,
  bool isGroupSummary = false,
  bool isMedia = false,
  int importance = 4,
  bool replyable = true,
}) => PlatformNotification(
  key: key,
  packageName: packageName,
  appName: appName,
  title: title,
  text: text,
  postedAtMs: postedAtMs ?? DateTime.now().millisecondsSinceEpoch,
  appIcon: Uint8List.fromList([1, 2, 3]),
  isConversation: replyable,
  isOngoing: isOngoing,
  isForegroundService: isForegroundService,
  isGroupSummary: isGroupSummary,
  isMedia: isMedia,
  importance: importance,
  actions: [
    if (replyable)
      PlatformNotificationAction(id: '0', title: 'Reply', isReply: true),
    PlatformNotificationAction(id: '1', title: 'Mark as read', isReply: false),
  ],
);

/// A mirrored notification as a computer sees it.
MirroredNotification mirrored({
  String deviceId = 'phone',
  String key = 'k1',
  bool replyable = true,
  String title = 'Alex',
}) => MirroredNotification(
  deviceId: deviceId,
  key: key,
  appPackage: signal,
  appName: 'Signal',
  title: title,
  text: 'Are you coming?',
  postedAt: DateTime(2026, 11, 18, 9, 30),
  isConversation: replyable,
  actions: [
    if (replyable) const MirroredAction(id: '0', title: 'Reply', isReply: true),
    const MirroredAction(id: '1', title: 'Mark as read', isReply: false),
  ],
);

Future<void> until(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition not met within $timeout');
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Discovery over an in-memory bus, so tests don't need multicast.
class Bus {
  final List<BusDiscovery> members = [];

  Discovery join() {
    final member = BusDiscovery(this);
    members.add(member);
    return member;
  }
}

class BusDiscovery implements Discovery {
  BusDiscovery(this.bus);

  final Bus bus;
  final StreamController<DiscoveredPeer> _peers = .broadcast();
  Announce? self;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Future<void> start(Announce self) async {
    this.self = self;
    await announceNow();
  }

  @override
  Future<void> announceNow() async {
    final announce = self;
    if (announce == null) {
      return;
    }

    for (final member in bus.members) {
      if (member != this && member.self != null) {
        member._peers.add(
          DiscoveredPeer(announce: announce, host: '127.0.0.1'),
        );
      }
    }
  }

  @override
  Future<void> stop() async => self = null;
}
