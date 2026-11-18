import 'package:ferret_mirroring/src/capture/capture_event.dart';
import 'package:ferret_mirroring/src/capture/capture_options.dart';
import 'package:ferret_mirroring/src/capture/screen_capture.dart';

/// For platforms whose screen Ferret can't capture.
class UnsupportedScreenCapture implements ScreenCapture {
  const UnsupportedScreenCapture();

  @override
  Future<CaptureSupport> support() async => const .none();

  @override
  Future<ConsentResult> requestConsent(
    ConsentTexts texts,
    Duration timeout,
  ) async => .failed;

  @override
  Future<void> cancelConsent() async {}

  @override
  Future<bool> start(CaptureOptions options) async => false;

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
