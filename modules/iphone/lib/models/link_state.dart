/// Where the link to the iPhone stands.
enum LinkPhase {
  /// The person hasn't turned the feature on.
  off,

  /// This computer has no Bluetooth LE.
  unsupported,

  /// This build of the app isn't allowed to use Bluetooth.
  notConfigured,
  bluetoothOff,

  /// The person said no to Bluetooth for this app.
  unauthorized,

  /// No iPhone picked yet.
  noDevice,
  connecting,
  connected,

  /// The iPhone is away or its Bluetooth is off. Retrying.
  outOfReach,

  /// The iPhone is there but keeps its notifications and media to itself:
  /// it isn't paired with this computer, or sharing is off on the iPhone.
  notShared,

  /// Something else went wrong. Retrying.
  failed,
}

/// The link's real state, for the card and Settings.
class LinkState {
  const LinkState({
    this.phase = .off,
    this.deviceName = '',
    this.hasNotifications = false,
    this.hasMedia = false,
    this.connectedAt,
  });

  final LinkPhase phase;

  /// The chosen iPhone's name, or empty.
  final String deviceName;

  /// Notifications are being received (ANCS is subscribed).
  final bool hasNotifications;

  /// The player is being followed (AMS is subscribed).
  final bool hasMedia;
  final DateTime? connectedAt;

  bool get isConnected => phase == .connected;

  /// The person has to do something before it can work.
  bool get needsAttention => switch (phase) {
    .bluetoothOff || .unauthorized || .noDevice || .notShared => true,
    _ => false,
  };

  @override
  bool operator ==(Object other) =>
      other is LinkState &&
      other.phase == phase &&
      other.deviceName == deviceName &&
      other.hasNotifications == hasNotifications &&
      other.hasMedia == hasMedia &&
      other.connectedAt == connectedAt;

  @override
  int get hashCode =>
      Object.hash(phase, deviceName, hasNotifications, hasMedia, connectedAt);
}
