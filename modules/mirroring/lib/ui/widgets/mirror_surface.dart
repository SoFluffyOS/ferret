import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';

/// Draws a mirrored screen: fitted to the space it gets, or one phone pixel
/// per screen pixel with scrolling when it doesn't fit.
class MirrorSurface extends StatelessWidget {
  const MirrorSurface({
    super.key,
    required this.picture,
    required this.actualSize,
  });

  final MirrorPicture picture;
  final bool actualSize;

  @override
  Widget build(BuildContext context) {
    final content = switch (picture) {
      TexturePicture(:final textureId) => Texture(textureId: textureId),
      ImagePicture(:final image) => RawImage(image: image, fit: .fill),
    };
    if (!actualSize) {
      return Center(
        child: AspectRatio(
          aspectRatio: picture.width / picture.height,
          child: content,
        ),
      );
    }

    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return Center(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: .horizontal,
          child: SizedBox(
            width: picture.width / pixelRatio,
            height: picture.height / pixelRatio,
            child: content,
          ),
        ),
      ),
    );
  }
}
