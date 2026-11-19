import 'package:ferret_camera/src/camera_abilities.dart';
import 'package:ferret_camera/src/camera_capture.dart';
import 'package:ferret_camera/src/channel_phone_camera.dart';
import 'package:ferret_camera/src/unsupported_phone_camera.dart';
import 'package:flutter/foundation.dart';

/// The phone's camera, through its own camera screen: the person always
/// sees it and presses the shutter. The app never captures by itself.
abstract interface class PhoneCamera {
  /// Android's camera app and the iPhone's camera, nothing elsewhere.
  factory PhoneCamera.current() => switch (defaultTargetPlatform) {
    .android || .iOS when !kIsWeb => ChannelPhoneCamera(),
    _ => const UnsupportedPhoneCamera(),
  };

  /// Whether this platform has a camera screen to open at all.
  bool get isSupported;

  /// Whether this platform can scan documents, such as an iPhone.
  bool get scansDocuments;

  Future<CameraAbilities> abilities();

  /// Opens the camera, only while the app is on screen, and waits for the
  /// person. The photo comes back as a JPEG, turned the right way up and
  /// without its location.
  Future<CameraCapture> takePhoto();

  /// Opens the document scanner: a JPEG for one page, a PDF for several.
  Future<CameraCapture> scanDocument();
}
