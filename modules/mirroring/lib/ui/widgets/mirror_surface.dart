import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/ui/widgets/mirror_input.dart';

/// Draws a mirrored screen: fitted to the space it gets, or one phone pixel
/// per screen pixel with scrolling when it doesn't fit.
class MirrorSurface extends StatelessWidget {
  const MirrorSurface({
    super.key,
    required this.picture,
    required this.actualSize,
    this.onPointer,
    this.onKey,
  });

  final MirrorPicture picture;
  final bool actualSize;

  /// Clicks and scrolling on the picture, for a device that takes them.
  final ValueChanged<MirrorPointer>? onPointer;

  /// Typing while the picture has the focus, for a device that takes it.
  final ValueChanged<MirrorKey>? onKey;

  @override
  Widget build(BuildContext context) {
    final content = MirrorInput(
      onPointer: onPointer,
      onKey: onKey,
      child: switch (picture) {
        TexturePicture(:final textureId) => Texture(textureId: textureId),
        ImagePicture(:final image) => RawImage(image: image, fit: .fill),
      },
    );
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
