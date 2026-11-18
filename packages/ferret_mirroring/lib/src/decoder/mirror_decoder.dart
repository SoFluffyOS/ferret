import 'dart:io';

import 'package:ferret_mirroring/src/decoder/jpeg_mirror_decoder.dart';
import 'package:ferret_mirroring/src/decoder/mirror_picture.dart';
import 'package:ferret_mirroring/src/decoder/video_toolbox_decoder.dart';
import 'package:ferret_mirroring/src/stream/mirror_codec.dart';
import 'package:ferret_mirroring/src/stream/mirror_frame.dart';
import 'package:ferret_mirroring/src/stream/mirror_stream_config.dart';
import 'package:flutter/foundation.dart';

/// Turns a mirrored screen's frames into something to draw.
abstract interface class MirrorDecoder {
  /// The best decoder here: VideoToolbox on macOS, JPEG pictures decoded
  /// by Flutter itself everywhere else.
  static MirrorDecoder current() {
    if (Platform.isMacOS) {
      return VideoToolboxDecoder();
    }

    return JpegMirrorDecoder();
  }

  /// What [current] can decode on this platform, best first, without
  /// creating a decoder.
  static List<MirrorCodec> get platformCodecs {
    if (Platform.isMacOS) {
      return const [.h264, .jpeg];
    }

    return const [.jpeg];
  }

  /// The picture to draw, or null before the first frame.
  ValueListenable<MirrorPicture?> get picture;

  /// One event per frame that reached [picture].
  Stream<DecodedFrame> get decoded;

  /// A frame couldn't be decoded: the next one must be a keyframe.
  Stream<void> get errors;

  /// Sets up for [config]. Throws when the stream can't be decoded here.
  Future<void> configure(MirrorStreamConfig config);

  void decode(MirrorFrame frame);

  Future<void> dispose();
}
