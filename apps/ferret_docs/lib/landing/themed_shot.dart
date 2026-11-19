import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// An app render that follows the reader's light or dark appearance:
/// `/assets/landing/<name>-light.webp` and `<name>-dark.webp`.
class ThemedShot extends StatelessComponent {
  const ThemedShot({
    required this.name,
    required this.alt,
    required this.width,
    required this.height,
    this.eager = false,
    this.classes = 'shot',
  });

  final String name;
  final String alt;
  final int width;
  final int height;
  final bool eager;
  final String classes;

  @override
  Component build(BuildContext context) {
    final loading = switch (eager) {
      true => MediaLoading.eager,
      false => MediaLoading.lazy,
    };

    return Component.element(
      tag: 'picture',
      classes: classes,
      children: [
        source(
          attributes: {
            'srcset': '/assets/landing/$name-dark.webp',
            'media': '(prefers-color-scheme: dark)',
          },
        ),
        img(
          src: '/assets/landing/$name-light.webp',
          alt: alt,
          width: width,
          height: height,
          loading: loading,
          attributes: {'decoding': 'async'},
        ),
      ],
    );
  }
}
