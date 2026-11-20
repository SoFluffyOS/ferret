import 'dart:io';

import 'package:ferret_mirroring/src/capture/android_camera_capture.dart';
import 'package:ferret_mirroring/src/capture/capture_event.dart';
import 'package:ferret_mirroring/src/capture/unsupported_camera_capture.dart';
import 'package:ferret_mirroring/src/stream/mirror_audio.dart';

/// One of a device's cameras, by the way it faces.
enum MirrorLens {
  /// Faces away from the screen.
  back,

  /// Faces whoever looks at the screen.
  front,
}

/// What this device's cameras can do for a computer, as things stand.
class CameraSupport {
  const CameraSupport({
    required this.h264,
    required this.lenses,
    required this.cameraGranted,
    required this.microphoneGranted,
  });

  const CameraSupport.none()
    : h264 = false,
      lenses = const [],
      cameraGranted = false,
      microphoneGranted = false;

  /// The pictures can be encoded as H.264, the one way a camera is sent.
  final bool h264;

  /// The cameras there are. Empty on a device without one.
  final List<MirrorLens> lenses;

  /// The system lets this app open the camera.
  final bool cameraGranted;

  /// The system lets this app open the microphone.
  final bool microphoneGranted;

  bool get canCapture => h264 && lenses.isNotEmpty;
}

class CameraCaptureOptions {
  const CameraCaptureOptions({
    required this.lens,
    required this.maxLongSide,
    required this.maxShortSide,
    required this.fps,
    required this.bitrate,
    this.audioCodec,
  });

  /// The camera to start with. Another one is used when it isn't there.
  final MirrorLens lens;
  final int maxLongSide;
  final int maxShortSide;
  final int fps;

  /// Bits per second the video encoder starts with.
  final int bitrate;

  /// Capture the microphone too, encoded this way. Null for pictures
  /// only.
  final MirrorAudioCodec? audioCodec;
}

/// The words on the ongoing notice the platform shows while the camera is
/// on, in the owner's language.
class CameraTexts {
  const CameraTexts({
    required this.title,
    required this.body,
    required this.stopLabel,
    required this.channelName,
  });

  /// Such as "Camera on for MacBook".
  final String title;
  final String body;
  final String stopLabel;
  final String channelName;
}

/// Sends this device's camera and microphone as encoded frames, after its
/// owner said yes in the app. The system's own mark (Android's green dot)
/// and an ongoing notice with Stop show for as long as it is on.
abstract interface class CameraCapture {
  /// The capture for this platform: Android only.
  static CameraCapture current() {
    if (Platform.isAndroid) {
      return AndroidCameraCapture();
    }

    return const UnsupportedCameraCapture();
  }

  static bool get isSupportedPlatform => Platform.isAndroid;

  Future<CameraSupport> support();

  /// Asks the owner for the system's camera permission, and the
  /// microphone's with [withMicrophone], when they aren't granted yet.
  /// Call it right after the owner said yes to a computer. Answers with
  /// how things stand afterwards.
  Future<CameraSupport> requestAccess({required bool withMicrophone});

  /// Turns the camera on, with the ongoing notice [texts]. Answers with
  /// the camera that is on, or null when it couldn't start.
  Future<MirrorLens?> start(CameraCaptureOptions options, CameraTexts texts);

  /// Switches to another camera. Answers with the one that is on
  /// afterwards, or null when none is.
  Future<MirrorLens?> setLens(MirrorLens lens);

  Future<void> stop();

  /// Asks the encoder for a frame that decodes on its own.
  Future<void> requestKeyframe();

  Future<void> setBitrate(int bitrate);

  /// Configs, frames, the microphone's sound, and how the camera ended.
  Stream<CaptureEvent> get events;

  Future<void> dispose();
}
