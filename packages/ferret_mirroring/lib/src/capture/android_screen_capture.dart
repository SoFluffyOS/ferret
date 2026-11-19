import 'dart:async';
import 'dart:typed_data';

import 'package:ferret_mirroring/src/capture/capture_event.dart';
import 'package:ferret_mirroring/src/capture/capture_options.dart';
import 'package:ferret_mirroring/src/capture/screen_capture.dart';
import 'package:ferret_mirroring/src/messages.g.dart';
import 'package:ferret_mirroring/src/stream/mirror_audio.dart';
import 'package:ferret_mirroring/src/stream/mirror_codec.dart';
import 'package:ferret_mirroring/src/stream/mirror_frame.dart';
import 'package:ferret_mirroring/src/stream/mirror_stream_config.dart';

/// Android: MediaProjection into a MediaCodec H.264 encoder, or JPEG
/// pictures, inside a foreground service with an ongoing notice.
class AndroidScreenCapture implements ScreenCapture, MirrorCaptureFlutterApi {
  AndroidScreenCapture({MirrorCaptureHostApi? api})
    : _api = api ?? MirrorCaptureHostApi() {
    MirrorCaptureFlutterApi.setUp(this);
  }

  final MirrorCaptureHostApi _api;
  final StreamController<CaptureEvent> _events = .broadcast(sync: true);

  @override
  Stream<CaptureEvent> get events => _events.stream;

  @override
  Future<CaptureSupport> support() async {
    final support = await _api.support();
    return CaptureSupport(h264: support.h264, jpeg: support.jpeg);
  }

  @override
  Future<AudioCaptureSupport> audioSupport() async =>
      switch (await _api.audioSupport()) {
        .unsupported => .unsupported,
        .needsPermission => .needsPermission,
        .ready => .ready,
      };

  @override
  Future<bool> requestAudioPermission() => _api.requestAudioPermission();

  @override
  Future<ConsentResult> requestConsent(
    ConsentTexts texts,
    Duration timeout,
  ) async {
    final result = await _api.requestConsent(
      NativeConsentTexts(
        askTitle: texts.askTitle,
        askBody: texts.askBody,
        askChannelName: texts.askChannelName,
        sharingTitle: texts.sharingTitle,
        sharingBody: texts.sharingBody,
        stopLabel: texts.stopLabel,
        sharingChannelName: texts.sharingChannelName,
      ),
      timeout.inSeconds,
    );

    return switch (result) {
      .granted => .granted,
      .denied => .denied,
      .timedOut => .timedOut,
      .cannotAsk => .cannotAsk,
      .failed => .failed,
    };
  }

  @override
  Future<void> cancelConsent() => _api.cancelConsent();

  @override
  Future<bool> start(CaptureOptions options) => _api.start(
    NativeCaptureOptions(
      codec: switch (options.codec) {
        .h264 => .h264,
        .jpeg => .jpeg,
      },
      maxLongSide: options.maxLongSide,
      maxShortSide: options.maxShortSide,
      fps: options.fps,
      bitrate: options.bitrate,
      audioCodec: switch (options.audioCodec) {
        null => null,
        .opus => .opus,
        .pcm => .pcm,
      },
    ),
  );

  @override
  Future<void> stop() => _api.stop();

  @override
  Future<void> requestKeyframe() => _api.requestKeyframe();

  @override
  Future<void> setBitrate(int bitrate) => _api.setBitrate(bitrate);

  @override
  Future<void> dispose() async {
    MirrorCaptureFlutterApi.setUp(null);
    await _events.close();
  }

  @override
  void onConfig(NativeStreamConfig config) => _add(
    CaptureConfigured(
      MirrorStreamConfig(
        codec: _codecOf(config.codec),
        width: config.width,
        height: config.height,
        rotation: config.rotation,
        fps: config.fps,
        sps: config.sps,
        pps: config.pps,
      ),
    ),
  );

  @override
  void onFrame(NativeFrame frame) => _add(
    CaptureFrame(
      MirrorFrame(
        data: frame.data,
        ptsUs: frame.ptsUs,
        keyframe: frame.keyframe,
      ),
    ),
  );

  @override
  void onScreenOff(bool off) => _add(CaptureScreenOff(off: off));

  @override
  void onAudioConfig(NativeAudioCodec codec, int sampleRate, int channels) =>
      _add(
        CaptureAudioConfigured(
          MirrorAudioConfig(
            codec: switch (codec) {
              .opus => .opus,
              .pcm => .pcm,
            },
            sampleRate: sampleRate,
            channels: channels,
          ),
        ),
      );

  @override
  void onAudioFrame(Uint8List data, int ptsUs) =>
      _add(CaptureAudio(MirrorAudioPacket(data: data, ptsUs: ptsUs)));

  @override
  void onAudioEnded() => _add(const CaptureAudioEnded());

  @override
  void onEnded(NativeCaptureEnd end) => _add(
    CaptureEnded(switch (end) {
      .stoppedByUser => .stoppedByUser,
      .endedBySystem => .endedBySystem,
      .failed => .failed,
    }),
  );

  MirrorCodec _codecOf(NativeCodec codec) => switch (codec) {
    .h264 => .h264,
    .jpeg => .jpeg,
  };

  void _add(CaptureEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }
}
