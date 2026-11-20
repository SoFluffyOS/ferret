import 'package:ferret_mirroring/src/capture/capture_event.dart';
import 'package:ferret_mirroring/src/display/display_capture.dart';
import 'package:ferret_mirroring/src/route/mirror_control.dart';

/// Platforms that can't lend their desktop yet.
class UnsupportedDisplayCapture implements DisplayCapture {
  const UnsupportedDisplayCapture();

  @override
  Stream<CaptureEvent> get events => const Stream.empty();

  @override
  Future<DisplaySupport> support() async => const .none();

  @override
  Future<ScreenPanel?> screen() async => null;

  @override
  Future<bool> requestScreenRecording() async => false;

  @override
  Future<bool> requestInput() async => false;

  @override
  Future<void> openScreenRecordingSettings() async {}

  @override
  Future<bool> start(DisplayCaptureOptions options) async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> requestKeyframe() async {}

  @override
  Future<void> setBitrate(int bitrate) async {}

  @override
  Future<void> pointer(MirrorPointer event) async {}

  @override
  Future<void> dispose() async {}
}
