import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';

/// Draws a mirrored screen, fitted to the space it gets. [builder] wraps
/// the picture itself, so what it adds (input, a dimmed layer) covers the
/// picture and nothing around it.
class MirrorSurface extends StatelessWidget {
  const MirrorSurface({super.key, required this.picture, this.builder});

  final MirrorPicture picture;

  final Widget Function(BuildContext context, Widget picture)? builder;

  @override
  Widget build(BuildContext context) {
    final content = _draw(picture);

    return Center(
      child: AspectRatio(
        aspectRatio: picture.width / picture.height,
        child: builder?.call(context, content) ?? content,
      ),
    );
  }

  Widget _draw(MirrorPicture picture) => switch (picture) {
    TexturePicture(isCropped: true) => _cropped(picture),
    TexturePicture(:final textureId) => Texture(textureId: textureId),
    ImagePicture(:final image) => RawImage(image: image, fit: .fill),
    TurnedPicture(:final picture, :final quarterTurns) => RotatedBox(
      quarterTurns: quarterTurns,
      child: _draw(picture),
    ),
  };

  /// Only the picture's part of buffers bigger than it, stretched by as
  /// much as the picture is.
  Widget _cropped(TexturePicture picture) => LayoutBuilder(
    builder: (context, constraints) {
      final scaleX = constraints.maxWidth / picture.width;
      final scaleY = constraints.maxHeight / picture.height;

      return Stack(
        clipBehavior: .hardEdge,
        children: [
          Positioned(
            left: -picture.cropLeft * scaleX,
            top: -picture.cropTop * scaleY,
            width: picture.bufferWidth * scaleX,
            height: picture.bufferHeight * scaleY,
            child: Texture(textureId: picture.textureId),
          ),
        ],
      );
    },
  );
}
