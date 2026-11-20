import 'dart:async';

import 'package:ferret_mirroring/src/decoder/jpeg_mirror_decoder.dart';
import 'package:ferret_mirroring/src/decoder/mirror_decoder.dart';
import 'package:ferret_mirroring/src/decoder/mirror_picture.dart';
import 'package:ferret_mirroring/src/messages.g.dart';
import 'package:ferret_mirroring/src/stream/mirror_codec.dart';
import 'package:ferret_mirroring/src/stream/mirror_frame.dart';
import 'package:ferret_mirroring/src/stream/mirror_stream_config.dart';
import 'package:flutter/foundation.dart';

/// H.264 decoded by the platform's own (hardware) decoder into a texture
/// Flutter draws without copying pixels: [VideoToolboxDecoder] on macOS,
/// [MediaCodecDecoder] on Android. JPEG streams go to [JpegMirrorDecoder].
class NativeH264Decoder implements MirrorDecoder, MirrorDecoderFlutterApi {
  NativeH264Decoder({MirrorDecoderHostApi? api, JpegMirrorDecoder? jpeg})
    : _api = api ?? MirrorDecoderHostApi(),
      _jpeg = jpeg ?? JpegMirrorDecoder() {
    MirrorDecoderFlutterApi.setUp(this);
    _jpeg.picture.addListener(_onJpegPicture);
    _subscriptions
      ..add(_jpeg.decoded.listen(_decoded.add))
      ..add(_jpeg.errors.listen(_errors.add));
  }

  final MirrorDecoderHostApi _api;
  final JpegMirrorDecoder _jpeg;
  final ValueNotifier<MirrorPicture?> _picture = .new(null);
  final StreamController<DecodedFrame> _decoded = .broadcast();
  final StreamController<void> _errors = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  MirrorCodec _codec = .h264;
  int? _textureId;

  /// The texture's buffers and where the picture starts in them, when
  /// the platform said they are bigger than the picture.
  ({int width, int height, int left, int top})? _buffer;
  bool _disposed = false;

  @override
  ValueListenable<MirrorPicture?> get picture => _picture;

  @override
  Stream<DecodedFrame> get decoded => _decoded.stream;

  @override
  Stream<void> get errors => _errors.stream;

  @override
  Future<void> configure(MirrorStreamConfig config) async {
    _codec = config.codec;
    if (config.codec == .jpeg) {
      return _jpeg.configure(config);
    }

    final sps = config.sps;
    final pps = config.pps;
    if (sps == null || pps == null || sps.isEmpty || pps.isEmpty) {
      throw ArgumentError('An H.264 stream needs its parameter sets');
    }

    _textureId ??= await _api.create();
    _buffer = null;
    await _api.configure(sps, pps);
  }

  @override
  void decode(MirrorFrame frame) {
    if (_disposed) {
      return;
    }

    if (_codec == .jpeg) {
      _jpeg.decode(frame);
      return;
    }

    unawaited(
      _api
          .decode(frame.data, frame.ptsUs, frame.keyframe)
          .catchError((Object _) => _reportError()),
    );
  }

  @override
  Future<bool> savePicture(String path) async {
    if (_codec == .jpeg) {
      return _jpeg.savePicture(path);
    }

    if (_disposed || _textureId == null) {
      return false;
    }

    try {
      return await _api.savePicture(path);
    } on Object {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    MirrorDecoderFlutterApi.setUp(null);
    _jpeg.picture.removeListener(_onJpegPicture);
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _picture.value = null;
    await _jpeg.dispose();
    if (_textureId != null) {
      _textureId = null;
      await _api.dispose().catchError((Object _) {});
    }

    _picture.dispose();
    await _decoded.close();
    await _errors.close();
  }

  @override
  void onDecoded(int ptsUs, int width, int height) {
    final textureId = _textureId;
    if (_disposed || textureId == null || _codec != .h264) {
      return;
    }

    final buffer = _buffer;
    final picture = TexturePicture(
      textureId: textureId,
      width: width,
      height: height,
      bufferWidth: buffer?.width,
      bufferHeight: buffer?.height,
      cropLeft: buffer?.left ?? 0,
      cropTop: buffer?.top ?? 0,
    );
    if (_picture.value != picture) {
      _picture.value = picture;
    }

    _decoded.add(DecodedFrame(ptsUs: ptsUs, width: width, height: height));
  }

  @override
  void onDecodeError(int status) => _reportError();

  @override
  void onBufferSize(
    int bufferWidth,
    int bufferHeight,
    int cropLeft,
    int cropTop,
  ) {
    _buffer = (
      width: bufferWidth,
      height: bufferHeight,
      left: cropLeft,
      top: cropTop,
    );
  }

  void _onJpegPicture() {
    if (_disposed || _codec != .jpeg) {
      return;
    }

    _picture.value = _jpeg.picture.value;
  }

  void _reportError() {
    if (!_disposed) {
      _errors.add(null);
    }
  }
}

/// macOS: H.264 decoded by VideoToolbox (the Mac's hardware decoder).
class VideoToolboxDecoder extends NativeH264Decoder {
  VideoToolboxDecoder({super.api, super.jpeg});
}

/// Android: H.264 decoded by MediaCodec, low latency where the decoder
/// has it, onto a SurfaceProducer texture.
class MediaCodecDecoder extends NativeH264Decoder {
  MediaCodecDecoder({super.api, super.jpeg});
}
