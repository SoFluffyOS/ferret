import 'dart:typed_data';

import 'package:ferret_mirroring/src/stream/mirror_codec.dart';

/// What a decoder needs before the first frame, and again whenever the
/// picture changes size, such as when the phone is rotated.
class MirrorStreamConfig {
  const MirrorStreamConfig({
    required this.codec,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.fps = 0,
    this.sps,
    this.pps,
    this.turn = 0,
  });

  final MirrorCodec codec;
  final int width;
  final int height;

  /// How the captured screen is rotated, in degrees clockwise.
  final int rotation;
  final int fps;

  /// H.264 parameter sets, each one NAL unit without a start code.
  final Uint8List? sps;
  final Uint8List? pps;

  /// A camera only: how far to turn the picture clockwise to show it
  /// upright, in degrees: 0, 90, 180 or 270. [width] and [height] are the
  /// picture's before it is turned.
  final int turn;
}
