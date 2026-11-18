import 'dart:ui' as ui;

/// What to draw for a mirrored screen right now.
sealed class MirrorPicture {
  const MirrorPicture();

  int get width;

  int get height;
}

/// A platform texture the decoder keeps drawing into.
class TexturePicture extends MirrorPicture {
  const TexturePicture({
    required this.textureId,
    required this.width,
    required this.height,
  });

  final int textureId;

  @override
  final int width;

  @override
  final int height;
}

/// One decoded image, replaced with every frame.
class ImagePicture extends MirrorPicture {
  const ImagePicture(this.image);

  final ui.Image image;

  @override
  int get width => image.width;

  @override
  int get height => image.height;
}

/// A frame reached the screen.
class DecodedFrame {
  const DecodedFrame({
    required this.ptsUs,
    required this.width,
    required this.height,
  });

  final int ptsUs;
  final int width;
  final int height;
}
