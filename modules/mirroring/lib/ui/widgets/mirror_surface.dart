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
    final content = switch (picture) {
      TexturePicture(:final textureId) => Texture(textureId: textureId),
      ImagePicture(:final image) => RawImage(image: image, fit: .fill),
    };

    return Center(
      child: AspectRatio(
        aspectRatio: picture.width / picture.height,
        child: builder?.call(context, content) ?? content,
      ),
    );
  }
}
