import 'package:ferret_camera/src/camera_abilities.dart';
import 'package:ferret_camera/src/camera_capture.dart';
import 'package:ferret_camera/src/phone_camera.dart';

/// Computers: no camera screen to open.
class UnsupportedPhoneCamera implements PhoneCamera {
  const UnsupportedPhoneCamera();

  @override
  bool get isSupported => false;

  @override
  bool get scansDocuments => false;

  @override
  Future<CameraAbilities> abilities() async => const .none();

  @override
  Future<CameraCapture> takePhoto() async => const CameraCapture(.unavailable);

  @override
  Future<CameraCapture> scanDocument() async =>
      const CameraCapture(.unavailable);
}
