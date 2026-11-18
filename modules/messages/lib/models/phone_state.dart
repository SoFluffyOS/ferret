import 'package:messages/models/phone_readiness.dart';
import 'package:messages/models/round_trip.dart';
import 'package:protocol/messages.dart';

/// One phone that shares its texts, as a computer sees it.
class PhoneState {
  const PhoneState({
    required this.deviceId,
    this.connected = false,
    this.status,
    this.lastRoundTrip,
    this.syncing = false,
  });

  final String deviceId;
  final bool connected;

  /// What the phone said about itself, null until it answered.
  final MessagesStatus? status;
  final RoundTrip? lastRoundTrip;

  /// The first page of conversations is on its way.
  final bool syncing;

  PhoneReadiness get readiness {
    if (!connected) {
      return .offline;
    }

    if (lastRoundTrip case RoundTrip(ok: false)) {
      return .unreachable;
    }

    final current = status;
    if (current == null) {
      return .checking;
    }

    if (!current.enabled) {
      return .off;
    }

    if (!current.smsAccess) {
      return .noAccess;
    }

    return .ready;
  }

  /// Replies can be sent from here right now.
  bool get canSend => readiness == .ready && (status?.sendAccess ?? false);

  PhoneState copyWith({
    bool? connected,
    MessagesStatus? status,
    bool clearStatus = false,
    RoundTrip? lastRoundTrip,
    bool? syncing,
  }) => PhoneState(
    deviceId: deviceId,
    connected: connected ?? this.connected,
    status: switch (clearStatus) {
      true => null,
      false => status ?? this.status,
    },
    lastRoundTrip: lastRoundTrip ?? this.lastRoundTrip,
    syncing: syncing ?? this.syncing,
  );
}
