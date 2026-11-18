import 'dart:async';

import 'package:ferret_mirroring/src/decoder/jpeg_mirror_decoder.dart';
import 'package:ferret_mirroring/src/decoder/mirror_decoder.dart';
import 'package:ferret_mirroring/src/decoder/mirror_picture.dart';
import 'package:ferret_mirroring/src/messages.g.dart';
import 'package:ferret_mirroring/src/stream/mirror_codec.dart';
import 'package:ferret_mirroring/src/stream/mirror_frame.dart';
import 'package:ferret_mirroring/src/stream/mirror_stream_config.dart';
import 'package:flutter/foundation.dart';

/// macOS: H.264 decoded by VideoToolbox (the Mac's hardware decoder) into
/// a texture Flutter draws without copying pixels. JPEG streams go to
/// [JpegMirrorDecoder].
class VideoToolboxDecoder implements MirrorDecoder, MirrorDecoderFlutterApi {
  VideoToolboxDecoder({MirrorDecoderHostApi? api, JpegMirrorDecoder? jpeg})
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

    final shown = _picture.value;
    final isSame =
        shown is TexturePicture &&
        shown.textureId == textureId &&
        shown.width == width &&
        shown.height == height;
    if (!isSame) {
      _picture.value = TexturePicture(
        textureId: textureId,
        width: width,
        height: height,
      );
    }

    _decoded.add(DecodedFrame(ptsUs: ptsUs, width: width, height: height));
  }

  @override
  void onDecodeError(int status) => _reportError();

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
