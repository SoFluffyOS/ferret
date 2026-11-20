import 'package:ferret_docs/landing/site_icons.g.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// An icon in front of a heading or a list item: a Lucide line icon by its
/// name, or a platform's mark (`android`, `apple`, `windows`, `linux`).
/// Screen readers skip it; the words next to it carry the meaning.
class Marker extends StatelessComponent {
  const Marker(this.icon);

  final String icon;

  @override
  Component build(BuildContext context) {
    final brand = brandIcons[icon];
    final svg = switch (brand) {
      final brand? =>
        '<svg class="icon icon-brand" viewBox="0 0 24 24" fill="currentColor" '
            'aria-hidden="true" focusable="false">$brand</svg>',
      null =>
        '<svg class="icon" viewBox="0 0 24 24" fill="none" '
            'stroke="currentColor" stroke-width="2" stroke-linecap="round" '
            'stroke-linejoin="round" aria-hidden="true" focusable="false">'
            '${lucideIcons[icon] ?? ''}</svg>',
    };

    return span(
      classes: 'marker',
      attributes: {'aria-hidden': 'true'},
      [
        RawText(svg),
      ],
    );
  }
}
