import 'package:ferret_camera/ferret_camera.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CameraCapture.fromMap', () {
    test('reads a taken photo', () {
      final result = CameraCapture.fromMap({
        'outcome': 'taken',
        'path': '/tmp/photo.jpg',
        'mimeType': 'image/jpeg',
      });

      expect(result.outcome, CaptureOutcome.taken);
      expect(result.path, '/tmp/photo.jpg');
      expect(result.mimeType, 'image/jpeg');
    });

    test('a taken picture without a file failed', () {
      expect(
        CameraCapture.fromMap({'outcome': 'taken'}).outcome,
        CaptureOutcome.failed,
      );
    });

    test('reads the ways it ends without a picture', () {
      for (final outcome in [
        CaptureOutcome.cancelled,
        CaptureOutcome.noPermission,
        CaptureOutcome.unavailable,
      ]) {
        final result = CameraCapture.fromMap({'outcome': outcome.name});

        expect(result.outcome, outcome);
        expect(result.path, isNull);
      }
    });

    test('anything else failed', () {
      expect(CameraCapture.fromMap(null).outcome, CaptureOutcome.failed);
      expect(
        CameraCapture.fromMap({'outcome': 'exploded'}).outcome,
        CaptureOutcome.failed,
      );
    });
  });

  test('abilities default to none', () {
    final abilities = CameraAbilities.fromMap({'photo': true});

    expect(abilities.photo, isTrue);
    expect(abilities.document, isFalse);
    expect(CameraAbilities.fromMap(null).photo, isFalse);
  });

  test('computers have no camera to open', () async {
    const camera = UnsupportedPhoneCamera();

    expect(camera.isSupported, isFalse);
    expect((await camera.takePhoto()).outcome, CaptureOutcome.unavailable);
  });
}
