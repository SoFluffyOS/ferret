/// What the platform shows and plays while ringing.
class RingAlert {
  const RingAlert({
    required this.title,
    required this.body,
    required this.foundItLabel,
    required this.maxDuration,
    this.silent = false,
    this.vibrate = true,
    this.flashTorch = false,
  });

  /// Such as "Ferret is ringing".
  final String title;

  /// Such as "MacBook is looking for this phone".
  final String body;
  final String foundItLabel;

  /// Stops on its own after this long, even if the app never asks.
  final Duration maxDuration;

  /// Vibrate and show the notice, without sound.
  final bool silent;
  final bool vibrate;
  final bool flashTorch;
}
