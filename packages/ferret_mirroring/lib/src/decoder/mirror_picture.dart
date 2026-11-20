import 'dart:ui' as ui;

/// What to draw for a mirrored screen right now.
sealed class MirrorPicture {
  const MirrorPicture();

  int get width;

  int get height;
}

/// A platform texture the decoder keeps drawing into. Its buffers can be
/// bigger than the picture (H.264 codes whole 16-pixel blocks): then only
/// the [width] × [height] part from ([cropLeft], [cropTop]) is shown.
class TexturePicture extends MirrorPicture {
  const TexturePicture({
    required this.textureId,
    required this.width,
    required this.height,
    int? bufferWidth,
    int? bufferHeight,
    this.cropLeft = 0,
    this.cropTop = 0,
  }) : bufferWidth = bufferWidth ?? width,
       bufferHeight = bufferHeight ?? height;

  final int textureId;

  @override
  final int width;

  @override
  final int height;

  final int bufferWidth;
  final int bufferHeight;
  final int cropLeft;
  final int cropTop;

  /// The buffers hold more than the picture.
  bool get isCropped =>
      bufferWidth != width ||
      bufferHeight != height ||
      cropLeft != 0 ||
      cropTop != 0;

  @override
  bool operator ==(Object other) =>
      other is TexturePicture &&
      other.textureId == textureId &&
      other.width == width &&
      other.height == height &&
      other.bufferWidth == bufferWidth &&
      other.bufferHeight == bufferHeight &&
      other.cropLeft == cropLeft &&
      other.cropTop == cropTop;

  @override
  int get hashCode => Object.hash(
    textureId,
    width,
    height,
    bufferWidth,
    bufferHeight,
    cropLeft,
    cropTop,
  );
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

/// [picture] turned clockwise by [quarterTurns] to show upright, as a
/// camera's is when the phone is held another way than its sensor sits.
/// [width] and [height] are the picture's as it shows.
class TurnedPicture extends MirrorPicture {
  const TurnedPicture(this.picture, this.quarterTurns);

  /// [picture] turned by [degrees] clockwise, or as it is when that is
  /// no turn at all.
  static MirrorPicture of(MirrorPicture picture, int degrees) {
    final quarterTurns = (degrees ~/ 90) % 4;
    if (quarterTurns == 0) {
      return picture;
    }

    return TurnedPicture(picture, quarterTurns);
  }

  final MirrorPicture picture;
  final int quarterTurns;

  @override
  int get width => switch (quarterTurns.isOdd) {
    true => picture.height,
    false => picture.width,
  };

  @override
  int get height => switch (quarterTurns.isOdd) {
    true => picture.width,
    false => picture.height,
  };

  @override
  bool operator ==(Object other) =>
      other is TurnedPicture &&
      other.picture == picture &&
      other.quarterTurns == quarterTurns;

  @override
  int get hashCode => Object.hash(picture, quarterTurns);
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
