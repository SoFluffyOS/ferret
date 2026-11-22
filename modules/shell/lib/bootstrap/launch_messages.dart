import 'dart:ui' as ui;

/// Messages the system can send while Ferret is still getting ready, on
/// channels whose Dart side is set up only once the engine runs. Flutter
/// keeps one waiting message per channel and drops older ones; these keep
/// more, so a second tap during a slow start isn't lost.
abstract final class LaunchMessages {
  /// A notice's button (Accept, Decline, Take photo), which the Android
  /// receiver hands to the notifications plugin's channel.
  static const notices = 'dexterous.com/flutter/local_notifications';

  static const channels = [notices];

  /// How many messages each channel keeps until its handler comes.
  static const capacity = 16;

  static void hold() {
    for (final channel in channels) {
      ui.channelBuffers.resize(channel, capacity);
    }
  }
}
