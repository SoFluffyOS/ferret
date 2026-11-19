import 'package:feature_kit/feature_kit.dart';

/// Everything the menubar icon is picked from, read at one moment.
class MenubarIconInputs {
  const MenubarIconInputs({
    this.connectedCount = 0,
    this.connectedName = '',
    this.isPaused = false,
    this.waitingCount = 0,
    this.waitingName = '',
    this.isPairingWaiting = false,
    this.progress,
    this.peerName = '',
    this.isSending = true,
    this.finishedCount = 0,
    this.screenSeenBy = '',
    this.controlledBy = '',
  });

  /// Sums up the app: [connectedNames] of the devices connected now,
  /// [pairingName] of the device whose pairing request waits (null when
  /// none does), and what each feature is [busy] with. A pairing request
  /// is named before a feature's request, since it runs out.
  factory MenubarIconInputs.gather({
    required List<String> connectedNames,
    required bool isPaused,
    required String? pairingName,
    required List<FeatureBusy> busy,
  }) {
    final running = [
      for (final feature in busy)
        if (feature.progress != null) feature,
    ];
    final waiting = [
      for (final feature in busy)
        if (feature.waitingCount > 0) feature,
    ];
    final pairingCount = switch (pairingName) {
      null => 0,
      _ => 1,
    };

    return MenubarIconInputs(
      connectedCount: connectedNames.length,
      connectedName: switch (connectedNames) {
        [final only] => only,
        _ => '',
      },
      isPaused: isPaused,
      waitingCount: waiting.fold(
        pairingCount,
        (sum, feature) => sum + feature.waitingCount,
      ),
      waitingName: pairingName ?? waiting.firstOrNull?.waitingName ?? '',
      isPairingWaiting: pairingName != null,
      progress: _average([for (final feature in running) ?feature.progress]),
      peerName: running.firstOrNull?.peerName ?? '',
      isSending: running.firstOrNull?.isSending ?? true,
      finishedCount: busy.fold(
        0,
        (sum, feature) => sum + feature.finishedCount,
      ),
      screenSeenBy: busy
          .map((feature) => feature.screenSeenBy)
          .firstWhere((name) => name.isNotEmpty, orElse: () => ''),
      controlledBy: busy
          .map((feature) => feature.controlledBy)
          .firstWhere((name) => name.isNotEmpty, orElse: () => ''),
    );
  }

  final int connectedCount;

  /// The connected device when there is exactly one, otherwise empty.
  final String connectedName;

  final bool isPaused;

  /// Pairing and file requests waiting for the person.
  final int waitingCount;

  /// Who sent the request shown first, or empty when unknown.
  final String waitingName;

  /// Whether the request shown first is a pairing request.
  final bool isPairingWaiting;

  /// How far the running transfers got, 0 to 1, or null when none runs.
  final double? progress;

  /// The device the running transfer is with, or empty when unknown.
  final String peerName;

  /// Whether the running transfer leaves this device (true) or arrives.
  final bool isSending;

  /// Transfers that went through since the app started. Only goes up.
  final int finishedCount;

  /// The device that sees this screen right now, or empty.
  final String screenSeenBy;

  /// The device that controls this computer right now, or empty.
  final String controlledBy;

  /// Whether another device sees or controls this one right now.
  bool get isWatched => screenSeenBy.isNotEmpty || controlledBy.isNotEmpty;

  static double? _average(List<double> fractions) {
    if (fractions.isEmpty) {
      return null;
    }

    final sum = fractions.fold(0.0, (sum, fraction) => sum + fraction);
    return sum / fractions.length;
  }
}
