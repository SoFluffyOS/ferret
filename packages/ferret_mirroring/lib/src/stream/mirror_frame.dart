import 'dart:typed_data';

/// One encoded picture of a mirrored screen.
class MirrorFrame {
  const MirrorFrame({
    required this.data,
    required this.ptsUs,
    required this.keyframe,
  });

  /// H.264: one Annex-B access unit. JPEG: the picture.
  final Uint8List data;

  /// When it was captured, in microseconds on the capturing device's clock.
  final int ptsUs;

  /// Decodes without any frame before it.
  final bool keyframe;
}
