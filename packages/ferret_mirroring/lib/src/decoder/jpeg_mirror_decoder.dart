import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ferret_mirroring/src/decoder/mirror_decoder.dart';
import 'package:ferret_mirroring/src/decoder/mirror_picture.dart';
import 'package:ferret_mirroring/src/stream/mirror_frame.dart';
import 'package:ferret_mirroring/src/stream/mirror_stream_config.dart';
import 'package:flutter/foundation.dart';

/// Decodes one JPEG per frame with Flutter's own image codecs, so it works
/// on every platform with no native code. When pictures arrive faster than
/// they decode, only the newest waits.
class JpegMirrorDecoder implements MirrorDecoder {
  JpegMirrorDecoder({Future<ui.Image> Function(Uint8List bytes)? decodeImage})
    : _decodeImage = decodeImage ?? _decodeWithEngine;

  final Future<ui.Image> Function(Uint8List bytes) _decodeImage;
  final ValueNotifier<MirrorPicture?> _picture = .new(null);
  final StreamController<DecodedFrame> _decoded = .broadcast();
  final StreamController<void> _errors = .broadcast();

  MirrorFrame? _waiting;
  bool _decoding = false;
  bool _disposed = false;

  /// The image shown before the current one. It is let go one frame late,
  /// so a widget still painting it never holds a disposed image.
  ui.Image? _previous;

  @override
  ValueListenable<MirrorPicture?> get picture => _picture;

  @override
  Stream<DecodedFrame> get decoded => _decoded.stream;

  @override
  Stream<void> get errors => _errors.stream;

  @override
  Future<void> configure(MirrorStreamConfig config) async {
    if (config.codec != .jpeg) {
      throw UnsupportedError('This decoder only shows JPEG pictures');
    }
  }

  @override
  void decode(MirrorFrame frame) {
    if (_disposed) {
      return;
    }

    if (_decoding) {
      _waiting = frame;
      return;
    }

    unawaited(_decode(frame));
  }

  @override
  Future<bool> savePicture(String path) async {
    final shown = _picture.value;
    if (shown is! ImagePicture) {
      return false;
    }

    // A copy of its own, because the next frame disposes the one shown.
    final image = shown.image.clone();
    try {
      final png = await image.toByteData(format: .png);
      if (png == null) {
        return false;
      }

      final file = await File(path).create(recursive: true);
      await file.writeAsBytes(png.buffer.asUint8List(), flush: true);
      return true;
    } on Object {
      return false;
    } finally {
      image.dispose();
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _waiting = null;
    final shown = _picture.value;
    _picture.value = null;
    _previous?.dispose();
    _previous = null;
    if (shown case ImagePicture(:final image)) {
      image.dispose();
    }

    _picture.dispose();
    await _decoded.close();
    await _errors.close();
  }

  Future<void> _decode(MirrorFrame frame) async {
    _decoding = true;
    MirrorFrame? next = frame;
    while (next != null && !_disposed) {
      await _show(next);
      next = _waiting;
      _waiting = null;
    }

    _decoding = false;
  }

  Future<void> _show(MirrorFrame frame) async {
    final ui.Image image;
    try {
      image = await _decodeImage(frame.data);
    } on Object {
      if (!_disposed) {
        _errors.add(null);
      }

      return;
    }

    if (_disposed) {
      image.dispose();
      return;
    }

    final replaced = _picture.value;
    _picture.value = ImagePicture(image);
    _previous?.dispose();
    _previous = switch (replaced) {
      ImagePicture(image: final old) => old,
      _ => null,
    };
    _decoded.add(
      DecodedFrame(
        ptsUs: frame.ptsUs,
        width: image.width,
        height: image.height,
      ),
    );
  }

  static Future<ui.Image> _decodeWithEngine(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final codec = await ui.instantiateImageCodecFromBuffer(buffer);
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }
}
