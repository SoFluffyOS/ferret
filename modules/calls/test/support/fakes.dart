import 'dart:async';
import 'dart:typed_data';

import 'package:calls/calls.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_calls/ferret_calls.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/calls.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

/// A phone's telephony driven by the test.
class FakePhone implements PhoneCalls {
  final StreamController<PlatformPhoneEvent> _events = .broadcast(sync: true);

  PlatformCallPermissions granted = allPermissions();

  /// What the permission dialogs lead to; null keeps [granted].
  PlatformCallPermissions? afterRequest;
  PlatformCallResult result = .ok;
  PlatformContact? contact;
  List<PlatformCallLogEntry> log = [];
  bool monitoring = false;
  bool settingsOpen = true;
  int answered = 0;
  int ended = 0;
  int silenced = 0;
  int requested = 0;
  int openedSettings = 0;
  int? askedLogLimit;
  final List<String> dialed = [];
  final List<String> lookedUp = [];

  void ring([String? number]) =>
      _events.add(PlatformPhoneEvent(state: .ringing, number: number));

  void offHook([String? number]) =>
      _events.add(PlatformPhoneEvent(state: .offHook, number: number));

  void idle() => _events.add(PlatformPhoneEvent(state: .idle));

  @override
  Stream<PlatformPhoneEvent> get events => _events.stream;

  @override
  Future<PlatformCallPermissions> permissions() async => granted;

  @override
  Future<PlatformCallPermissions> requestPermissions() async {
    requested++;
    granted = afterRequest ?? granted;
    return granted;
  }

  @override
  Future<void> openAppSettings() async {
    if (!settingsOpen) {
      throw StateError('no settings page');
    }

    openedSettings++;
  }

  @override
  Future<bool> startMonitoring() async {
    monitoring = granted.phoneState;
    return monitoring;
  }

  @override
  Future<void> stopMonitoring() async => monitoring = false;

  @override
  Future<PlatformCallResult> answer() async {
    answered++;
    return result;
  }

  @override
  Future<PlatformCallResult> end() async {
    ended++;
    return result;
  }

  @override
  Future<PlatformCallResult> silenceRinger() async {
    silenced++;
    return result;
  }

  @override
  Future<PlatformCallResult> dial(String number) async {
    dialed.add(number);
    return result;
  }

  @override
  Future<List<PlatformCallLogEntry>> recentCalls(int limit) async {
    askedLogLimit = limit;
    return log.take(limit).toList();
  }

  @override
  Future<PlatformContact?> lookupContact(String number) async {
    lookedUp.add(number);
    return contact;
  }
}

PlatformCallPermissions allPermissions() => PlatformCallPermissions(
  phoneState: true,
  callLog: true,
  contacts: true,
  answerCalls: true,
  placeCalls: true,
  canAskAgain: true,
);

PlatformCallPermissions noPermissions({bool canAskAgain = true}) =>
    PlatformCallPermissions(
      phoneState: false,
      callLog: false,
      contacts: false,
      answerCalls: false,
      placeCalls: false,
      canAskAgain: canAskAgain,
    );

/// A connected device that records what it was sent.
class FakeSession implements Session {
  FakeSession(
    this.remoteDeviceId, {
    this.name = 'MacBook',
    this.flags = const [CallsFeature.viewFlag],
  });

  @override
  final String remoteDeviceId;
  final String name;
  final List<String> flags;
  final List<GeneratedMessage> sent = [];
  bool failSends = false;

  List<Call> get calls => [
    for (final update in sent.whereType<CallUpdate>()) update.call,
  ];

  List<CallsStatus> get statuses => sent.whereType<CallsStatus>().toList();

  @override
  DeviceInfo? get remoteDevice => DeviceInfo(id: remoteDeviceId, name: name);

  @override
  bool supports(String featureId) => featureId == CallsFeature.featureId;

  @override
  FeatureSupport? remoteFeature(String featureId) => switch (supports(
    featureId,
  )) {
    true => FeatureSupport(id: featureId, flags: flags),
    false => null,
  };

  @override
  Future<void> send(String feature, GeneratedMessage message) async {
    if (failSends) {
      throw StateError('send failed');
    }

    sent.add(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Just enough of the engine for the feature: settings and sessions.
class FakeHost implements FeatureHost {
  FakeHost({Map<String, Object?>? settings})
    : settings = MemorySettingsStore(settings);

  @override
  final MemorySettingsStore settings;

  @override
  List<Session> sessions = [];

  @override
  Session? sessionFor(String deviceId) {
    for (final session in sessions) {
      if (session.remoteDeviceId == deviceId) {
        return session;
      }
    }

    return null;
  }

  @override
  Stream<List<Session>> get sessionChanges => const Stream.empty();

  @override
  Future<void> broadcast(String featureId, GeneratedMessage message) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A [LocalNotifier] that records what it was asked to show.
class FakeNotifier implements LocalNotifier {
  final Map<String, LocalNotice> shown = {};
  final List<LocalNotice> history = [];
  final List<String> cancelled = [];
  final StreamController<NoticeResponse> _responses = .broadcast(sync: true);

  void respond(String noticeId, [String? actionId]) =>
      _responses.add(NoticeResponse(noticeId: noticeId, actionId: actionId));

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

/// A [CallsControl] the test drives by hand.
class FakeControl implements CallsControl {
  final StreamController<void> _changes = .broadcast(sync: true);
  final StreamController<RemoteCall> _events = .broadcast(sync: true);
  final Map<String, RemoteCall> _calls = {};

  CommandOutcome outcome = .ok;
  CallLogResult log = const CallLogResult([]);
  final List<String> answered = [];
  final List<String> endedCalls = [];
  final List<String> silencedCalls = [];
  final List<(String, String)> dialed = [];
  int logRequests = 0;

  @override
  bool showIncoming = true;

  /// A phone reported [call].
  void emit(RemoteCall call) {
    if (call.isEnded) {
      _calls.remove(call.key);
    }

    if (!call.isEnded) {
      _calls[call.key] = call;
    }

    _events.add(call);
    _changes.add(null);
  }

  @override
  List<RemoteCall> get remoteCalls => _calls.values.toList();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Stream<RemoteCall> get callEvents => _events.stream;

  @override
  Future<CommandOutcome> answer(RemoteCall call) async {
    answered.add(call.id);
    return outcome;
  }

  @override
  Future<CommandOutcome> end(RemoteCall call) async {
    endedCalls.add(call.id);
    return outcome;
  }

  @override
  Future<CommandOutcome> silence(RemoteCall call) async {
    silencedCalls.add(call.id);
    return outcome;
  }

  @override
  Future<CommandOutcome> dial(String deviceId, String number) async {
    dialed.add((deviceId, number));
    return outcome;
  }

  @override
  Future<CallLogResult> fetchCallLog(String deviceId, {int limit = 50}) async {
    logRequests++;
    return log;
  }
}

/// A call on the phone "Pixel" as a computer sees it.
RemoteCall remoteCall({
  String id = 'call-1',
  String deviceId = 'phone',
  CallState state = .CALL_STATE_RINGING,
  CallDirection direction = .CALL_DIRECTION_INCOMING,
  CallOutcome outcome = .CALL_OUTCOME_UNSPECIFIED,
  String number = '+15550100',
  String name = 'Alex',
  DateTime? startedAt,
  DateTime? connectedAt,
}) => RemoteCall(
  deviceId: deviceId,
  deviceName: 'Pixel',
  call: Call(
    id: id,
    number: number,
    contactName: name,
    direction: direction,
    state: state,
    outcome: outcome,
  ),
  startedAt: startedAt ?? DateTime.now(),
  connectedAt: connectedAt,
);

PlatformCallLogEntry platformLogEntry({
  String id = '7',
  String number = '+15550100',
  String name = 'Alex',
  PlatformCallLogType type = .missed,
  int dateMs = 1795000000000,
  int durationSeconds = 0,
}) => PlatformCallLogEntry(
  id: id,
  number: number,
  name: name,
  type: type,
  dateMs: dateMs,
  durationSeconds: durationSeconds,
);

PlatformContact alex() =>
    PlatformContact(name: 'Alex', photoJpeg: Uint8List.fromList([1, 2, 3]));

/// [message] as it arrives in an envelope.
Envelope envelopeOf(GeneratedMessage message, {bool expectsReply = false}) =>
    Envelope(
      id: Int64(1),
      feature: CallsFeature.featureId,
      type: message.payloadType,
      payload: message.toPayload(),
      expectsReply: expectsReply,
    );

/// Lets queued stream events and futures run.
Future<void> settle() async {
  for (var turn = 0; turn < 5; turn++) {
    await Future<void>.delayed(Duration.zero);
  }
}

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

/// Discovery over an in-memory bus, so loopback tests don't need multicast.
class MemoryDiscoveryBus {
  final List<_MemoryDiscovery> _members = [];

  Discovery join() {
    final member = _MemoryDiscovery(this);
    _members.add(member);
    return member;
  }
}

class _MemoryDiscovery implements Discovery {
  _MemoryDiscovery(this._bus);

  final MemoryDiscoveryBus _bus;
  final StreamController<DiscoveredPeer> _peers = .broadcast();
  Announce? _self;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Future<void> start(Announce self) async {
    _self = self;
    await announceNow();
  }

  @override
  Future<void> announceNow() async {
    final announce = _self;
    if (announce == null) {
      return;
    }

    for (final member in _bus._members) {
      if (member != this) {
        member._peers.add(
          DiscoveredPeer(announce: announce, host: '127.0.0.1'),
        );
      }
    }
  }

  @override
  Future<void> stop() async => _self = null;
}
