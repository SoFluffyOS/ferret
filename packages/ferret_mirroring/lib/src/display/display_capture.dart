import 'dart:io';

import 'package:ferret_mirroring/src/capture/capture_event.dart';
import 'package:ferret_mirroring/src/display/mac_display_capture.dart';
import 'package:ferret_mirroring/src/display/unsupported_display_capture.dart';
import 'package:ferret_mirroring/src/route/mirror_control.dart';

/// What this computer can do as the source of an extra display, as things
/// stand.
class DisplaySupport {
  const DisplaySupport({
    required this.canExtend,
    required this.screenRecordingGranted,
    required this.inputGranted,
  });

  const DisplaySupport.none()
    : canExtend = false,
      screenRecordingGranted = false,
      inputGranted = false;

  /// The system lets an app make a display, capture it and encode it.
  final bool canExtend;

  /// The system lets this app see what is on its screens.
  final bool screenRecordingGranted;

  /// The system lets this app move the pointer and press keys.
  final bool inputGranted;
}

/// A screen as another computer sizes its display to fill it.
class ScreenPanel {
  const ScreenPanel({
    required this.width,
    required this.height,
    this.scale = 1,
    this.refreshHz = 60,
  });

  /// In pixels.
  final int width;
  final int height;

  /// Pixels per point: 2 for a sharp (Retina) screen.
  final int scale;
  final int refreshHz;
}

class DisplayCaptureOptions {
  const DisplayCaptureOptions({
    required this.name,
    required this.serial,
    required this.width,
    required this.height,
    required this.scale,
    required this.refreshHz,
    required this.bitrate,
  });

  /// What the display is called in the system's display settings.
  final String name;

  /// The same for the same viewer every time, so the system keeps where
  /// its owner put the display.
  final int serial;

  /// The viewer's screen in pixels.
  final int width;
  final int height;

  /// Pixels per point: 1 or 2.
  final int scale;
  final int refreshHz;

  /// Bits per second the encoder starts with.
  final int bitrate;
}

/// Lends this computer's desktop to another device: makes a display that
/// only exists in software, sends what is on it as H.264, and puts the
/// other device's pointer on it. The display goes away on [stop], when
/// the capture ends, and when the app quits.
abstract interface class DisplayCapture {
  /// The capture for this platform: macOS only, for now.
  static DisplayCapture current() {
    if (Platform.isMacOS) {
      return MacDisplayCapture();
    }

    return const UnsupportedDisplayCapture();
  }

  static bool get isSupportedPlatform => Platform.isMacOS;

  Future<DisplaySupport> support();

  /// This computer's own screen, the one Ferret's window is on, for being
  /// another computer's display. Null where it can't say.
  Future<ScreenPanel?> screen();

  /// Asks for the system's screen recording permission, with its own
  /// prompt the first time. Answers whether it is granted now.
  Future<bool> requestScreenRecording();

  /// Asks for the permission to move the pointer and press keys.
  Future<bool> requestInput();

  /// Opens the system page where screen recording is allowed.
  Future<void> openScreenRecordingSettings();

  /// Makes the display and starts sending it. False when it couldn't.
  Future<bool> start(DisplayCaptureOptions options);

  /// Stops sending and takes the display away.
  Future<void> stop();

  Future<void> requestKeyframe();

  Future<void> setBitrate(int bitrate);

  /// The other device's pointer, at fractions of the display. A press and
  /// its release are for the button in [MirrorPointer.buttons]; a scroll
  /// is in points.
  Future<void> pointer(MirrorPointer event);

  /// Configs, frames, and how the capture ended.
  Stream<CaptureEvent> get events;

  Future<void> dispose();
}
