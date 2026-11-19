import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// An emoji in front of a heading or a list item. Screen readers skip it; the
/// words next to it carry the meaning.
class Marker extends StatelessComponent {
  const Marker(this.emoji);

  final String emoji;

  @override
  Component build(BuildContext context) => span(
    classes: 'marker',
    attributes: {'aria-hidden': 'true'},
    [Component.text(emoji)],
  );
}
