import 'dart:io';

import 'package:ferret_find/src/alert_stop.dart';
import 'package:ferret_find/src/audio_state.dart';
import 'package:ferret_find/src/desktop_find.dart';
import 'package:ferret_find/src/pigeon_find.dart';
import 'package:ferret_find/src/ring_abilities.dart';
import 'package:ferret_find/src/ring_alert.dart';

/// Rings this device: sound, vibration, torch and the platform's notice, and
/// the volume controls to make it loud and put it back.
abstract interface class FindPlatform {
  /// The implementation for the platform the app runs on.
  factory FindPlatform.current() {
    if (Platform.isWindows || Platform.isLinux) {
      return DesktopFind();
    }

    return PigeonFind();
  }

  Future<RingAbilities> abilities();

  /// The current output state, or null when the platform can't read it.
  Future<AudioState?> readAudio();

  /// Sets the volume, mute and Do Not Disturb filter to [state].
  Future<void> applyAudio(AudioState state);

  Future<void> startAlert(RingAlert alert);

  /// Stops sound, vibration, torch and notice. Safe to call when idle.
  Future<void> stopAlert();

  /// The platform stopped the alert itself, such as on "Found it".
  Stream<AlertStop> get stops;

  /// Opens the system page where people allow Do Not Disturb access.
  Future<void> openDndAccessSettings();

  /// Opens the system page where people allow full-screen notifications.
  Future<void> openFullScreenSettings();
}
