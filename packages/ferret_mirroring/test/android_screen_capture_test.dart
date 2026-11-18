import 'dart:typed_data';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCaptureApi implements MirrorCaptureHostApi {
  NativeConsentResult consent = .granted;
  NativeConsentTexts? texts;
  int? timeoutSeconds;
  NativeCaptureOptions? options;
  final List<String> calls = [];

  @override
  Future<NativeCaptureSupport> support() async =>
      NativeCaptureSupport(h264: true, jpeg: true);

  @override
  Future<NativeConsentResult> requestConsent(
    NativeConsentTexts texts,
    int timeoutSeconds,
  ) async {
    this.texts = texts;
    this.timeoutSeconds = timeoutSeconds;
    return consent;
  }

  @override
  Future<void> cancelConsent() async => calls.add('cancel');

  @override
  Future<bool> start(NativeCaptureOptions options) async {
    this.options = options;
    return true;
  }

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> requestKeyframe() async => calls.add('keyframe');

  @override
  Future<void> setBitrate(int bitrate) async => calls.add('bitrate $bitrate');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const texts = ConsentTexts(
  askTitle: 'MacBook wants to see this screen',
  askBody: 'Tap to answer',
  askChannelName: 'Requests',
  sharingTitle: 'Sharing screen with MacBook',
  sharingBody: 'Visible there',
  stopLabel: 'Stop',
  sharingChannelName: 'Sharing',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCaptureApi api;
  late AndroidScreenCapture capture;

  setUp(() {
    api = FakeCaptureApi();
    capture = AndroidScreenCapture(api: api);
  });

  tearDown(() => capture.dispose());

  test('the prompt gets the words and the timeout, and every answer maps '
      'over', () async {
    for (final (native, result) in [
      (NativeConsentResult.granted, ConsentResult.granted),
      (NativeConsentResult.denied, ConsentResult.denied),
      (NativeConsentResult.timedOut, ConsentResult.timedOut),
      (NativeConsentResult.cannotAsk, ConsentResult.cannotAsk),
      (NativeConsentResult.failed, ConsentResult.failed),
    ]) {
      api.consent = native;
      expect(
        await capture.requestConsent(texts, const Duration(seconds: 60)),
        result,
      );
    }

    expect(api.timeoutSeconds, 60);
    expect(api.texts?.askTitle, 'MacBook wants to see this screen');
    expect(api.texts?.sharingTitle, 'Sharing screen with MacBook');
    expect(api.texts?.stopLabel, 'Stop');
  });

  test('start passes the limits to the encoder', () async {
    final started = await capture.start(
      const CaptureOptions(
        codec: .h264,
        maxLongSide: 1920,
        maxShortSide: 1080,
        fps: 60,
        bitrate: 4000000,
      ),
    );

    expect(started, isTrue);
    expect(api.options?.codec, NativeCodec.h264);
    expect((api.options?.maxLongSide, api.options?.maxShortSide), (1920, 1080));
    expect((api.options?.fps, api.options?.bitrate), (60, 4000000));
  });

  test('what the service reports arrives as events, in order', () async {
    final events = <CaptureEvent>[];
    capture.events.listen(events.add);

    capture
      ..onConfig(
        NativeStreamConfig(
          codec: .h264,
          width: 1080,
          height: 2400,
          rotation: 90,
          fps: 60,
          sps: Uint8List.fromList([0x67]),
          pps: Uint8List.fromList([0x68]),
        ),
      )
      ..onFrame(
        NativeFrame(data: Uint8List.fromList([1, 2]), ptsUs: 7, keyframe: true),
      )
      ..onScreenOff(true)
      ..onEnded(.endedBySystem);

    expect(events, hasLength(4));
    final config = (events[0] as CaptureConfigured).config;
    expect(
      (config.codec, config.width, config.rotation),
      (
        MirrorCodec.h264,
        1080,
        90,
      ),
    );
    expect(config.sps, [0x67]);
    final frame = (events[1] as CaptureFrame).frame;
    expect(frame.data, [1, 2]);
    expect((frame.ptsUs, frame.keyframe), (7, true));
    expect((events[2] as CaptureScreenOff).off, isTrue);
    expect((events[3] as CaptureEnded).end, CaptureEnd.endedBySystem);
  });

  test('keyframes, bitrate and stop reach the service', () async {
    await capture.requestKeyframe();
    await capture.setBitrate(2800000);
    await capture.cancelConsent();
    await capture.stop();

    expect(api.calls, ['keyframe', 'bitrate 2800000', 'cancel', 'stop']);
  });

  test('other platforms can\'t capture', () async {
    const capture = UnsupportedScreenCapture();

    expect((await capture.support()).canCapture, isFalse);
    expect(
      await capture.start(
        const CaptureOptions(
          codec: .jpeg,
          maxLongSide: 1,
          maxShortSide: 1,
          fps: 1,
          bitrate: 1,
        ),
      ),
      isFalse,
    );
  });
}
