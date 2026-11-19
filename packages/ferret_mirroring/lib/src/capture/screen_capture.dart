import 'dart:io';

import 'package:ferret_mirroring/src/capture/android_screen_capture.dart';
import 'package:ferret_mirroring/src/capture/capture_event.dart';
import 'package:ferret_mirroring/src/capture/capture_options.dart';
import 'package:ferret_mirroring/src/capture/unsupported_screen_capture.dart';

/// Captures this device's screen as encoded frames, after its owner said
/// yes on the system's own prompt.
abstract interface class ScreenCapture {
  /// The capture for this platform: Android only.
  static ScreenCapture current() {
    if (Platform.isAndroid) {
      return AndroidScreenCapture();
    }

    return const UnsupportedScreenCapture();
  }

  static bool get isSupportedPlatform => Platform.isAndroid;

  Future<CaptureSupport> support();

  /// Whether what this device plays can be captured along with its
  /// screen, as things stand right now.
  Future<AudioCaptureSupport> audioSupport();

  /// Asks the owner for the permission [AudioCaptureSupport.needsPermission]
  /// is about. Call it from a switch the owner just flipped, after saying
  /// what it is for. False when they said no.
  Future<bool> requestAudioPermission();

  /// Shows the system prompt, every time; nothing is remembered. A yes puts
  /// up the ongoing "sharing" notice and must be followed by [start] or
  /// [stop].
  Future<ConsentResult> requestConsent(ConsentTexts texts, Duration timeout);

  /// Takes back a [requestConsent] nobody answered yet.
  Future<void> cancelConsent();

  /// Starts capturing with the consent just given. False when it couldn't.
  Future<bool> start(CaptureOptions options);

  Future<void> stop();

  /// Asks the encoder for a frame that decodes on its own.
  Future<void> requestKeyframe();

  Future<void> setBitrate(int bitrate);

  /// Configs, frames, and how the capture ended.
  Stream<CaptureEvent> get events;

  Future<void> dispose();
}
