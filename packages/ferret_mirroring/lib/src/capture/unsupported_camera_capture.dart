import 'package:ferret_mirroring/src/capture/camera_capture.dart';
import 'package:ferret_mirroring/src/capture/capture_event.dart';

/// For platforms whose camera Ferret doesn't send.
class UnsupportedCameraCapture implements CameraCapture {
  const UnsupportedCameraCapture();

  @override
  Future<CameraSupport> support() async => const .none();

  @override
  Future<CameraSupport> requestAccess({required bool withMicrophone}) async =>
      const .none();

  @override
  Future<MirrorLens?> start(
    CameraCaptureOptions options,
    CameraTexts texts,
  ) async => null;

  @override
  Future<MirrorLens?> setLens(MirrorLens lens) async => null;

  @override
  Future<void> stop() async {}

  @override
  Future<void> requestKeyframe() async {}

  @override
  Future<void> setBitrate(int bitrate) async {}

  @override
  Stream<CaptureEvent> get events => const .empty();

  @override
  Future<void> dispose() async {}
}
