import 'dart:async';

import 'package:calls/models/models.dart';
import 'package:calls/services/services.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_calls/ferret_calls.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/calls.dart';
import 'package:protocol/protocol.dart';

/// Calls on the phone, shown and controlled from the person's other devices.
///
/// With a [phone], this device shares its calls: it watches the call state,
/// pushes every change, and runs the commands it is sent. Without one it
/// shows the calls of connected phones. Numbers and names are never logged.
class CallsFeature extends Feature implements CallsControl {
  CallsFeature({this.phone, DateTime Function()? clock, CallTracker? tracker})
    : _clock = clock ?? DateTime.now,
      _tracker = tracker ?? CallTracker(clock: clock);

  static const featureId = 'calls';

  /// Flags in [FeatureSupport]: this device has calls to share, or shows the
  /// calls of others.
  static const phoneFlag = 'phone';
  static const viewFlag = 'view';

  static const defaultLogLimit = 50;
  static const maxLogLimit = 200;
  static const _requestTimeout = Duration(seconds: 10);

  /// The phone's calls on this device, null on computers.
  final PhoneCalls? phone;

  final DateTime Function() _clock;
  final CallTracker _tracker;
  final StreamController<void> _changes = .broadcast();
  final StreamController<RemoteCall> _callEvents = .broadcast(sync: true);
  final StreamController<bool> _inCallChanges = .broadcast();
  final Map<String, Map<String, RemoteCall>> _remote = {};
  final Map<String, PhoneLink> _links = {};
  final Set<String> _unreached = {};

  StreamSubscription<String>? _settingsChanges;
  StreamSubscription<PlatformPhoneEvent>? _phoneEvents;
  PlatformCallPermissions? _permissions;
  CallsStatus? _pushedStatus;
  Future<void> _outbox = Future.value();
  bool _monitoring = false;
  bool _wasInCall = false;

  @override
  String get id => featureId;

  @override
  List<String> get flags => switch (isPhone) {
    true => const [phoneFlag],
    false => const [viewFlag],
  };

  /// This device has calls to share.
  bool get isPhone => phone != null;

  CallsSettings get settings => CallsSettings(host.settings);

  /// The phone's permissions as last read, null before the first read and on
  /// computers.
  PlatformCallPermissions? get permissions => _permissions;

  /// Whether this phone is watching its calls right now.
  bool get isMonitoring => _monitoring;

  /// What this phone can do for other devices right now.
  CallsStatus get localStatus =>
      CallCodec.status(enabled: settings.enabled, permissions: _permissions);

  /// Whether a call is ringing or going on: on this phone, or on a phone
  /// connected to this computer. Other parts of the app can pause media on
  /// it; see [inCallChanges].
  bool get inCall =>
      _tracker.hasCalls || _remote.values.any((calls) => calls.isNotEmpty);

  /// Fires with the new value when [inCall] changes.
  Stream<bool> get inCallChanges => _inCallChanges.stream;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Stream<RemoteCall> get callEvents => _callEvents.stream;

  @override
  bool get showIncoming => settings.showIncoming;

  @override
  List<RemoteCall> get remoteCalls => [
    for (final calls in _remote.values) ...calls.values,
  ];

  /// What this computer knows about calls on the phone [deviceId], or null
  /// when the phone has not answered yet.
  PhoneLink? linkOf(String deviceId) => _links[deviceId];

  /// Whether the last call update for [deviceId] could not be sent from this
  /// phone.
  bool pushFailedTo(String deviceId) => _unreached.contains(deviceId);

  @override
  Future<void> onStart() async {
    _settingsChanges = host.settings.changes
        .where(CallsSettings.owns)
        .listen(_onSettingChanged);

    final phone = this.phone;
    if (phone == null) {
      return;
    }

    _phoneEvents = phone.events.listen(_onPhoneEvent);
    await refreshPermissions();
  }

  @override
  Future<void> stop() async {
    await _settingsChanges?.cancel();
    await _phoneEvents?.cancel();
    _settingsChanges = null;
    _phoneEvents = null;

    final phone = this.phone;
    if (phone != null && _monitoring) {
      _monitoring = false;
      await _guard(phone.stopMonitoring);
    }
  }

  @override
  void onSessionOpened(Session session) {
    if (!isPhone) {
      if (_hasFlag(session, phoneFlag)) {
        unawaited(refreshStatus(session.remoteDeviceId));
      }

      return;
    }

    if (!_hasFlag(session, viewFlag)) {
      return;
    }

    _enqueue(() async {
      await _sendTo(session, localStatus);
      for (final call in _tracker.calls) {
        await _sendTo(session, _updateOf(call));
      }
    });
  }

  @override
  void onSessionClosed(Session session) {
    final deviceId = session.remoteDeviceId;
    _unreached.remove(deviceId);
    _links.remove(deviceId);

    final calls = _remote.remove(deviceId);
    for (final call in calls?.values ?? const <RemoteCall>[]) {
      _callEvents.add(
        call.withCall(call.call.deepCopy()..state = .CALL_STATE_ENDED),
      );
    }

    _changes.add(null);
    _announceInCall();
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    if (payloadOf(envelope, CallUpdate.new) case final update?) {
      _onRemoteUpdate(session, update);
      return null;
    }

    if (payloadOf(envelope, CallsStatus.new) case final status?) {
      _onRemoteStatus(session, status);
      return null;
    }

    if (payloadOf(envelope, GetCallsStatus.new) != null) {
      return localStatus;
    }

    if (payloadOf(envelope, CallCommand.new) case final command?) {
      return CallCommandResult(status: await _run(command));
    }

    if (payloadOf(envelope, GetCallLog.new) case final request?) {
      return _readLog(request);
    }

    return null;
  }

  /// Re-reads this phone's permissions, starts or stops watching calls to
  /// match, and tells connected computers when what it can do changed.
  Future<void> refreshPermissions() async {
    final phone = this.phone;
    if (phone == null) {
      return;
    }

    _permissions = await _guard(phone.permissions) ?? _permissions;
    await _syncMonitoring(phone);
  }

  /// Shows the system's permission dialogs on this phone.
  Future<void> requestPermissions() async {
    final phone = this.phone;
    if (phone == null) {
      return;
    }

    _permissions = await _guard(phone.requestPermissions) ?? _permissions;
    await _syncMonitoring(phone);
  }

  /// Opens this app's page in the phone's settings. False when it can't.
  Future<bool> openAppSettings() async {
    final phone = this.phone;
    if (phone == null) {
      return false;
    }

    try {
      await phone.openAppSettings();
      return true;
    } on Object catch (error) {
      printWarning('Opening the app settings failed', error);
      return false;
    }
  }

  /// Asks the phone [deviceId] what it can do. The answer, or the lack of
  /// one, is what the feature's health reports.
  Future<void> refreshStatus(String deviceId) async {
    final session = host.sessionFor(deviceId);
    if (session == null) {
      return;
    }

    try {
      final status = await session.call(
        featureId,
        GetCallsStatus(),
        CallsStatus.new,
        timeout: _requestTimeout,
      );
      _roundTrip(deviceId, answered: true, status: status);
    } on Object catch (error) {
      printWarning('Reading the calls status of $deviceId failed', error);
      _roundTrip(deviceId, answered: false);
    }

    _changes.add(null);
  }

  @override
  Future<CommandOutcome> answer(RemoteCall call) => _command(
    call.deviceId,
    CallCommand(action: .CALL_ACTION_ANSWER, callId: call.id),
  );

  @override
  Future<CommandOutcome> end(RemoteCall call) => _command(
    call.deviceId,
    CallCommand(action: .CALL_ACTION_END, callId: call.id),
  );

  @override
  Future<CommandOutcome> silence(RemoteCall call) => _command(
    call.deviceId,
    CallCommand(action: .CALL_ACTION_SILENCE, callId: call.id),
  );

  @override
  Future<CommandOutcome> dial(String deviceId, String number) async {
    final dialable = PhoneNumbers.dialable(number);
    if (dialable == null) {
      return .invalidNumber;
    }

    return _command(
      deviceId,
      CallCommand(action: .CALL_ACTION_DIAL, number: dialable),
    );
  }

  @override
  Future<CallLogResult> fetchCallLog(
    String deviceId, {
    int limit = defaultLogLimit,
  }) async {
    final session = host.sessionFor(deviceId);
    if (session == null) {
      return const .failed(.unreachable);
    }

    final CallLog log;
    try {
      log = await session.call(
        featureId,
        GetCallLog(limit: limit),
        CallLog.new,
        timeout: _requestTimeout,
      );
    } on Object catch (error) {
      printWarning('Reading the recent calls of $deviceId failed', error);
      _roundTrip(deviceId, answered: false);
      _changes.add(null);
      return const .failed(.unreachable);
    }

    _roundTrip(deviceId, answered: true);
    if (log.disabled) {
      return const .failed(.disabled);
    }

    if (log.permissionMissing) {
      return const .failed(.permissionMissing);
    }

    return CallLogResult(log.entries);
  }

  void _onSettingChanged(String key) {
    _changes.add(null);
    if (key == CallsSettings.enabledKey) {
      unawaited(refreshPermissions());
    }
  }

  Future<void> _syncMonitoring(PhoneCalls phone) async {
    final canSeeCalls = _permissions?.phoneState ?? false;
    final shouldMonitor = settings.enabled && canSeeCalls;

    if (shouldMonitor && !_monitoring) {
      // The platform reports the current state as soon as it starts, which
      // can be before the start call returns.
      _monitoring = true;
      _monitoring = await _guard(phone.startMonitoring) ?? false;
    }

    if (!shouldMonitor && _monitoring) {
      _monitoring = false;
      await _guard(phone.stopMonitoring);
      _publish(_tracker.reset());
    }

    _changes.add(null);
    _pushStatus();
  }

  void _onPhoneEvent(PlatformPhoneEvent event) {
    if (!_monitoring) {
      return;
    }

    final changed = _tracker.handle(event.state, number: event.number);
    _publish(changed);

    for (final call in changed) {
      if (call.state != CallState.CALL_STATE_ENDED &&
          call.number.isNotEmpty &&
          call.contactName.isEmpty) {
        unawaited(_addContact(call));
      }
    }
  }

  Future<void> _addContact(Call call) async {
    final phone = this.phone;
    if (phone == null || !(_permissions?.contacts ?? false)) {
      return;
    }

    final contact = await _guard(() => phone.lookupContact(call.number));
    if (contact == null) {
      return;
    }

    final updated = _tracker.setContact(
      call.id,
      name: contact.name,
      photo: contact.photoJpeg,
    );
    if (updated != null) {
      _publish([updated]);
    }
  }

  void _publish(List<Call> calls) {
    if (calls.isEmpty) {
      return;
    }

    _announceInCall();
    _enqueue(() async {
      for (final call in calls) {
        await _sendToViewers(_updateOf(call));
      }
    });
  }

  void _pushStatus() {
    final status = localStatus;
    if (status == _pushedStatus) {
      return;
    }

    _pushedStatus = status;
    _enqueue(() => _sendToViewers(status));
  }

  CallUpdate _updateOf(Call call) => CallUpdate(
    call: call,
    sentAtMs: Int64(_clock().millisecondsSinceEpoch),
  );

  /// Sends run one after the other, so updates arrive in the order the call
  /// changed.
  void _enqueue(Future<void> Function() send) {
    _outbox = _outbox.then((_) => send()).catchError((Object error) {
      printWarning('Sending a call update failed', error);
    });
  }

  Future<void> _sendToViewers(GeneratedMessage message) async {
    for (final session in host.sessions) {
      if (_hasFlag(session, viewFlag)) {
        await _sendTo(session, message);
      }
    }
  }

  Future<void> _sendTo(Session session, GeneratedMessage message) async {
    try {
      await session.send(featureId, message);
      _unreached.remove(session.remoteDeviceId);
    } on Object catch (error) {
      printWarning('Call update to ${session.remoteDeviceId} failed', error);
      _unreached.add(session.remoteDeviceId);
    }
  }

  Future<CallCommandStatus> _run(CallCommand command) async {
    final phone = this.phone;
    if (phone == null) {
      return .CALL_COMMAND_STATUS_UNSUPPORTED;
    }

    if (!settings.enabled) {
      return .CALL_COMMAND_STATUS_DISABLED;
    }

    return switch (command.action) {
      .CALL_ACTION_ANSWER => _answer(phone, command.callId),
      .CALL_ACTION_END => _end(phone, command.callId),
      .CALL_ACTION_SILENCE => _silence(phone, command.callId),
      .CALL_ACTION_DIAL => _dial(phone, command.number),
      _ => .CALL_COMMAND_STATUS_UNSUPPORTED,
    };
  }

  Future<CallCommandStatus> _answer(PhoneCalls phone, String callId) async {
    if (_tracker.ringing?.id != callId) {
      return .CALL_COMMAND_STATUS_NO_CALL;
    }

    return _platform(phone.answer);
  }

  Future<CallCommandStatus> _end(PhoneCalls phone, String callId) async {
    final call = _tracker.find(callId);
    if (call == null) {
      return .CALL_COMMAND_STATUS_NO_CALL;
    }

    // Android ends the ringing call first, so hanging up the ongoing call
    // while another one rings would decline the wrong one.
    final ringing = _tracker.ringing;
    if (ringing != null && ringing.id != callId) {
      return .CALL_COMMAND_STATUS_FAILED;
    }

    final declines = ringing != null;
    if (declines) {
      _tracker.markDeclined(callId);
    }

    final status = await _platform(phone.end);
    if (declines && status != CallCommandStatus.CALL_COMMAND_STATUS_OK) {
      _tracker.markDeclined(callId, declined: false);
    }

    return status;
  }

  Future<CallCommandStatus> _silence(PhoneCalls phone, String callId) async {
    if (_tracker.ringing?.id != callId) {
      return .CALL_COMMAND_STATUS_NO_CALL;
    }

    return _platform(phone.silenceRinger);
  }

  Future<CallCommandStatus> _dial(PhoneCalls phone, String number) async {
    final dialable = PhoneNumbers.dialable(number);
    if (dialable == null) {
      return .CALL_COMMAND_STATUS_INVALID_NUMBER;
    }

    _tracker.expectOutgoing(dialable);
    return _platform(() => phone.dial(dialable));
  }

  Future<CallCommandStatus> _platform(
    Future<PlatformCallResult> Function() command,
  ) async {
    final result = await _guard(command);
    if (result == null) {
      return .CALL_COMMAND_STATUS_FAILED;
    }

    return CallCodec.commandStatus(result);
  }

  Future<CallLog> _readLog(GetCallLog request) async {
    final phone = this.phone;
    if (phone == null || !settings.enabled) {
      return CallLog(disabled: true);
    }

    if (!(_permissions?.callLog ?? false)) {
      return CallLog(permissionMissing: true);
    }

    final limit = switch (request.limit) {
      0 => defaultLogLimit,
      final asked when asked > maxLogLimit => maxLogLimit,
      final asked => asked,
    };
    final entries = await _guard(() => phone.recentCalls(limit)) ?? const [];

    return CallLog(entries: entries.map(CallCodec.logEntry));
  }

  void _onRemoteUpdate(Session session, CallUpdate update) {
    final call = update.call;
    if (isPhone || call.id.isEmpty) {
      return;
    }

    final deviceId = session.remoteDeviceId;
    final calls = _remote.putIfAbsent(deviceId, () => {});
    final known = calls[call.id];

    if (call.state == CallState.CALL_STATE_ENDED) {
      if (known == null) {
        return;
      }

      calls.remove(call.id);
      _callEvents.add(known.withCall(call));
      _changes.add(null);
      _announceInCall();
      return;
    }

    final now = _clock();
    final skew = _skewOf(update, now);
    final connectedAt = switch (call.connectedAtMs.toInt()) {
      0 => null,
      final phoneTime => _localTime(phoneTime, skew, now),
    };
    final remote = RemoteCall(
      deviceId: deviceId,
      deviceName: session.remoteDevice?.name ?? deviceId,
      call: call,
      startedAt:
          known?.startedAt ?? _localTime(call.startedAtMs.toInt(), skew, now),
      connectedAt: known?.connectedAt ?? connectedAt,
    );

    calls[call.id] = remote;
    _callEvents.add(remote);
    _changes.add(null);
    _announceInCall();
  }

  /// How far this device's clock is ahead of the phone's, in milliseconds.
  int _skewOf(CallUpdate update, DateTime now) {
    final sentAt = update.sentAtMs.toInt();
    if (sentAt == 0) {
      return 0;
    }

    return now.millisecondsSinceEpoch - sentAt;
  }

  DateTime _localTime(int phoneTimeMs, int skewMs, DateTime now) {
    if (phoneTimeMs == 0) {
      return now;
    }

    final local = DateTime.fromMillisecondsSinceEpoch(phoneTimeMs + skewMs);
    if (local.isAfter(now)) {
      return now;
    }

    return local;
  }

  void _onRemoteStatus(Session session, CallsStatus status) {
    if (isPhone) {
      return;
    }

    _roundTrip(session.remoteDeviceId, answered: true, status: status);
    _changes.add(null);
  }

  Future<CommandOutcome> _command(String deviceId, CallCommand command) async {
    final session = host.sessionFor(deviceId);
    if (session == null) {
      return .unreachable;
    }

    try {
      final result = await session.call(
        featureId,
        command,
        CallCommandResult.new,
        timeout: _requestTimeout,
      );
      _roundTrip(deviceId, answered: true);
      return .fromStatus(result.status);
    } on Object catch (error) {
      printWarning('A call command to $deviceId failed', error);
      _roundTrip(deviceId, answered: false);
      _changes.add(null);
      return .unreachable;
    }
  }

  void _roundTrip(
    String deviceId, {
    required bool answered,
    CallsStatus? status,
  }) {
    final link = _links[deviceId] ?? const PhoneLink();
    _links[deviceId] = switch (answered) {
      true => link.answered(_clock(), status: status),
      false => link.unanswered(),
    };
  }

  void _announceInCall() {
    final now = inCall;
    if (now == _wasInCall) {
      return;
    }

    _wasInCall = now;
    _inCallChanges.add(now);
  }

  bool _hasFlag(Session session, String flag) =>
      session.remoteFeature(featureId)?.flags.contains(flag) ?? false;

  Future<T?> _guard<T>(Future<T> Function() platformCall) async {
    try {
      return await platformCall();
    } on Object catch (error) {
      printWarning('A phone call request to the platform failed', error);
      return null;
    }
  }
}
