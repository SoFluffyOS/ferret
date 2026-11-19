import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_wake/cards/cards.dart';
import 'package:ferret_wake/feature/wake_attempt.dart';
import 'package:ferret_wake/feature/wake_settings.dart';
import 'package:ferret_wake/packet/packet.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';
import 'package:protocol/wake.dart';

/// Wakes a sleeping computer with a Wake-on-LAN magic packet.
///
/// A computer tells its paired devices how to wake it (its cards' MAC and
/// broadcast addresses) when a session opens and when its cards change.
/// Any device can then wake it: it sends the packet itself and also asks
/// every connected computer to send it, for an iPhone that may not
/// broadcast or a phone on another network.
class WakeFeature extends Feature {
  WakeFeature({
    required this.isComputer,
    WakeSender sender = const UdpWakeSender(),
    Future<List<NetworkCard>> Function()? readCards,
    DateTime Function()? clock,
    this.wakeTimeout = const Duration(seconds: 90),
    this.relayTimeout = const Duration(seconds: 5),
  }) : _sender = sender,
       _readCards = readCards ?? const NetworkCards().read,
       _clock = clock ?? DateTime.now;

  static const featureId = 'wake';

  /// Flag in [FeatureSupport]: this device sends the magic packet when a
  /// paired device asks it to wake another.
  static const relayFlag = 'relay';

  /// Cards are read again at most this often, when a device connects.
  static const _rereadAfter = Duration(minutes: 1);

  /// A second request to wake the same device within this time is
  /// answered without sending again, so a burst of taps sends one burst.
  static const _relayGap = Duration(seconds: 5);

  /// Whether this is a computer, which can be woken and can wake others.
  final bool isComputer;

  /// How long to wait for a woken device to connect before saying it
  /// didn't wake.
  final Duration wakeTimeout;

  /// How long to wait for another device to say it sent the packet.
  final Duration relayTimeout;

  final WakeSender _sender;
  final Future<List<NetworkCard>> Function() _readCards;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final Map<String, WakeAttempt> _attempts = {};
  final Map<String, Timer> _timers = {};
  final Map<String, DateTime> _relayedAt = {};
  StreamSubscription<List<Session>>? _sessionWatch;
  List<NetworkCard> _cards = const [];
  DateTime? _readAt;
  Future<bool>? _reading;

  @override
  String get id => featureId;

  @override
  List<String> get flags => [
    if (isComputer && settings.relays) relayFlag,
  ];

  WakeSettings get settings => WakeSettings(host.settings);

  /// Fires when an attempt or this computer's cards changed.
  Stream<void> get changes => _changes.stream;

  /// This computer's wired and Wi-Fi cards, as last read.
  List<NetworkCard> get cards => _cards;

  /// What this computer tells paired devices: nothing while sharing is
  /// off or on a phone.
  WakeInfo get localWake => switch (isComputer && settings.shares) {
    true => NetworkCard.shareable(_cards),
    false => WakeInfo(),
  };

  WakeAttempt? attemptFor(String deviceId) => _attempts[deviceId];

  /// Whether [device] told this one how to wake it.
  bool canWake(TrustedDevice device) =>
      device.wake?.interfaces.any((card) => MacAddress.isUsable(card.mac)) ??
      false;

  @override
  Future<void> onStart() async {
    _sessionWatch = host.sessionChanges.listen(_onSessions);
    if (isComputer) {
      unawaited(refreshCards());
    }
  }

  @override
  Future<void> stop() async {
    await _sessionWatch?.cancel();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  @override
  void onSessionOpened(Session session) {
    _onConnected(session.remoteDeviceId);
    if (!isComputer) {
      return;
    }

    unawaited(_shareWith(session));
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    if (payloadOf(envelope, WakeInfo.new) case final wake?) {
      await host.trustStore.saveWake(session.remoteDeviceId, wake);
      _changes.add(null);
      return null;
    }

    if (payloadOf(envelope, WakeRequest.new) case final request?) {
      return WakeReply(result: await _relay(request));
    }

    return null;
  }

  /// Reads this computer's cards again and, when they changed, tells every
  /// connected device. Returns whether they changed.
  Future<bool> refreshCards() {
    if (_reading case final reading?) {
      return reading;
    }

    final reading = _read();
    _reading = reading;
    return reading.whenComplete(() => _reading = null);
  }

  /// Turns sharing this computer's MAC address on or off, and tells paired
  /// devices right away: off sends an empty answer, so they forget it.
  Future<void> setShares(bool shares) async {
    await settings.setShares(shares);
    await _tellEveryone();
    _changes.add(null);
  }

  Future<void> setRelays(bool relays) async {
    await settings.setRelays(relays);
    _changes.add(null);
  }

  /// Sends the magic packet for [deviceId] from here and through every
  /// connected computer, then waits up to [wakeTimeout] for it to connect.
  Future<WakeAttempt> wake(String deviceId) async {
    final device = host.trustStore[deviceId];
    final startedAt = _clock();
    if (device == null) {
      return WakeAttempt(
        deviceId: deviceId,
        phase: .couldntSend,
        startedAt: startedAt,
      );
    }

    final info = device.wake ?? WakeInfo();
    final packets = WakePackets.of(info, lastAddress: device.lastHost);
    final (sentHere, relayedBy) = await (
      _sender.send(packets),
      _askOthers(device, info),
    ).wait;

    final reached = sentHere.isNotEmpty || relayedBy.isNotEmpty;
    final attempt = WakeAttempt(
      deviceId: deviceId,
      phase: switch (reached) {
        true => .waking,
        false => .couldntSend,
      },
      startedAt: startedAt,
      broadcastHere: sentHere.any((packet) => packet.isBroadcast),
      relayedBy: relayedBy,
    );
    _attempts[deviceId] = attempt;
    _timers.remove(deviceId)?.cancel();
    if (reached) {
      _timers[deviceId] = Timer(wakeTimeout, () => _giveUp(deviceId));
    }

    printLog(
      'Wake-on-LAN: ${sentHere.length} packets here, '
      '${relayedBy.length} devices sent them too',
    );
    _changes.add(null);
    return attempt;
  }

  /// Forgets the last attempt for [deviceId], such as when the person
  /// closed its "didn't wake" line.
  void dismiss(String deviceId) {
    _timers.remove(deviceId)?.cancel();
    if (_attempts.remove(deviceId) == null) {
      return;
    }

    _changes.add(null);
  }

  Future<List<String>> _askOthers(TrustedDevice device, WakeInfo info) async {
    final relays = [
      for (final session in host.sessions)
        if (session.remoteDeviceId != device.id &&
            (session.remoteFeature(featureId)?.flags.contains(relayFlag) ??
                false))
          session,
    ];
    final request = WakeRequest(
      deviceId: device.id,
      info: info,
      lastAddress: device.lastHost,
    );

    final answers = await Future.wait([
      for (final session in relays) _askOne(session, request),
    ]);
    return [
      for (final (index, result) in answers.indexed)
        if (result == .WAKE_RESULT_SENT) relays[index].remoteDeviceId,
    ];
  }

  Future<WakeResult> _askOne(Session session, WakeRequest request) async {
    try {
      final reply = await session.call(
        featureId,
        request,
        WakeReply.new,
        timeout: relayTimeout,
      );
      return reply.result;
    } on Object {
      return .WAKE_RESULT_FAILED;
    }
  }

  /// Sends the packet for another device. Only for a device paired here
  /// too, so a paired phone can't make this computer wake strangers, and
  /// with this computer's own copy of its cards first.
  Future<WakeResult> _relay(WakeRequest request) async {
    if (!isComputer || !settings.relays) {
      return .WAKE_RESULT_RELAY_OFF;
    }

    final target = host.trustStore[request.deviceId];
    if (target == null || request.deviceId == host.identity.deviceId) {
      return .WAKE_RESULT_NOT_PAIRED;
    }

    final info = switch (target.wake) {
      final known? when canWake(target) => known,
      _ => request.info,
    };
    final lastAddress = switch (target.lastHost) {
      final known? => known,
      null when request.lastAddress.isNotEmpty => request.lastAddress,
      null => null,
    };
    final packets = WakePackets.of(info, lastAddress: lastAddress);
    if (packets.isEmpty) {
      return .WAKE_RESULT_NO_INFO;
    }

    final now = _clock();
    final last = _relayedAt[request.deviceId];
    if (last != null && now.difference(last) < _relayGap) {
      return .WAKE_RESULT_SENT;
    }

    _relayedAt[request.deviceId] = now;
    final sent = await _sender.send(packets);
    if (sent.isEmpty) {
      return .WAKE_RESULT_FAILED;
    }

    printLog('Wake-on-LAN: sent for a paired device on request');
    return .WAKE_RESULT_SENT;
  }

  void _onSessions(List<Session> sessions) {
    for (final session in sessions) {
      _onConnected(session.remoteDeviceId);
    }
  }

  /// A device being woken connected: the attempt worked, and its row shows
  /// it connected.
  void _onConnected(String deviceId) {
    if (_attempts.remove(deviceId) == null) {
      return;
    }

    _timers.remove(deviceId)?.cancel();
    _changes.add(null);
  }

  void _giveUp(String deviceId) {
    _timers.remove(deviceId);
    final attempt = _attempts[deviceId];
    if (attempt == null || attempt.phase != .waking) {
      return;
    }

    if (host.sessionFor(deviceId) != null) {
      _onConnected(deviceId);
      return;
    }

    _attempts[deviceId] = attempt.withPhase(.didntWake);
    _changes.add(null);
  }

  Future<bool> _read() async {
    final cards = await _readCards();
    _readAt = _clock();
    final before = NetworkCard.shareable(_cards);
    _cards = cards;
    if (NetworkCard.shareable(cards) == before) {
      return false;
    }

    _changes.add(null);
    await _tellEveryone();
    return true;
  }

  Future<void> _shareWith(Session session) async {
    final stale = switch (_readAt) {
      final readAt? => _clock().difference(readAt) > _rereadAfter,
      null => true,
    };
    if (stale && await refreshCards()) {
      return;
    }

    await _send(session, localWake);
  }

  Future<void> _tellEveryone() async {
    final wake = localWake;
    for (final session in host.sessions) {
      await _send(session, wake);
    }
  }

  Future<void> _send(Session session, WakeInfo wake) async {
    if (!session.supports(featureId)) {
      return;
    }

    try {
      await session.send(featureId, wake);
    } on Object {
      return;
    }
  }
}
