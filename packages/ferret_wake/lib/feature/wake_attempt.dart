/// Where waking a device stands.
enum WakePhase {
  /// The magic packet went out; waiting for the device to connect.
  waking,

  /// It didn't connect in time: Wake-on-LAN is likely off, or it is on
  /// Wi-Fi only.
  didntWake,

  /// Nothing could send the packet: no card known, no network, or an
  /// iPhone with no other device on to send it.
  couldntSend,
}

/// One try at waking a paired device. It ends when the device connects.
class WakeAttempt {
  const WakeAttempt({
    required this.deviceId,
    required this.phase,
    required this.startedAt,
    this.broadcastHere = false,
    this.relayedBy = const [],
  });

  final String deviceId;
  final WakePhase phase;
  final DateTime startedAt;

  /// Whether this device got a broadcast out itself. An iPhone usually
  /// can't, and a phone on mobile data reaches the wrong network.
  final bool broadcastHere;

  /// The paired devices that sent the packet on this one's behalf.
  final List<String> relayedBy;

  /// Whether this device had to lean on others and none was there, such as
  /// an iPhone with every computer off.
  bool get hadNoWayOut => !broadcastHere && relayedBy.isEmpty;

  WakeAttempt withPhase(WakePhase phase) => WakeAttempt(
    deviceId: deviceId,
    phase: phase,
    startedAt: startedAt,
    broadcastHere: broadcastHere,
    relayedBy: relayedBy,
  );
}
