import 'dart:async';
import 'dart:typed_data';

import 'package:ferret_mirroring/src/capture/camera_capture.dart';
import 'package:ferret_mirroring/src/capture/capture_event.dart';
import 'package:ferret_mirroring/src/messages.g.dart';
import 'package:ferret_mirroring/src/stream/mirror_audio.dart';
import 'package:ferret_mirroring/src/stream/mirror_frame.dart';
import 'package:ferret_mirroring/src/stream/mirror_stream_config.dart';

/// Android: Camera2 into a MediaCodec H.264 encoder and the microphone
/// into Opus, inside a foreground service with an ongoing notice.
class AndroidCameraCapture implements CameraCapture, CameraCaptureFlutterApi {
  AndroidCameraCapture({CameraCaptureHostApi? api})
    : _api = api ?? CameraCaptureHostApi() {
    CameraCaptureFlutterApi.setUp(this);
  }

  final CameraCaptureHostApi _api;
  final StreamController<CaptureEvent> _events = .broadcast(sync: true);

  @override
  Stream<CaptureEvent> get events => _events.stream;

  @override
  Future<CameraSupport> support() async => _supportOf(await _api.support());

  @override
  Future<CameraSupport> requestAccess({required bool withMicrophone}) async =>
      _supportOf(await _api.requestAccess(withMicrophone));

  @override
  Future<MirrorLens?> start(
    CameraCaptureOptions options,
    CameraTexts texts,
  ) async {
    final lens = await _api.start(
      NativeCameraOptions(
        lens: _toNative(options.lens),
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
      NativeCameraTexts(
        title: texts.title,
        body: texts.body,
        stopLabel: texts.stopLabel,
        channelName: texts.channelName,
      ),
    );

    return _lensOf(lens);
  }

  @override
  Future<MirrorLens?> setLens(MirrorLens lens) async =>
      _lensOf(await _api.setLens(_toNative(lens)));

  @override
  Future<void> stop() => _api.stop();

  @override
  Future<void> requestKeyframe() => _api.requestKeyframe();

  @override
  Future<void> setBitrate(int bitrate) => _api.setBitrate(bitrate);

  @override
  Future<void> dispose() async {
    CameraCaptureFlutterApi.setUp(null);
    await _events.close();
  }

  @override
  void onConfig(NativeStreamConfig config) => _add(
    CaptureConfigured(
      MirrorStreamConfig(
        codec: switch (config.codec) {
          .h264 => .h264,
          .jpeg => .jpeg,
        },
        width: config.width,
        height: config.height,
        rotation: config.rotation,
        fps: config.fps,
        sps: config.sps,
        pps: config.pps,
        turn: config.turn ?? 0,
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

  CameraSupport _supportOf(NativeCameraSupport support) => CameraSupport(
    h264: support.h264,
    lenses: [for (final lens in support.lenses) ?_lensOf(lens)],
    cameraGranted: support.cameraGranted,
    microphoneGranted: support.microphoneGranted,
  );

  NativeCameraLens _toNative(MirrorLens lens) => switch (lens) {
    .back => .back,
    .front => .front,
  };

  MirrorLens? _lensOf(NativeCameraLens? lens) => switch (lens) {
    null => null,
    .back => .back,
    .front => .front,
  };

  void _add(CaptureEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }
}
