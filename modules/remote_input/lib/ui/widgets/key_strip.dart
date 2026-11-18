import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One line of keys that slides sideways when it doesn't fit, so the
/// touchpad keeps its height. It stops at the ends rather than bouncing.
class KeyStrip extends StatelessWidget {
  const KeyStrip({super.key, required this.keys});

  final List<Widget> keys;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: .horizontal,
    physics: const ClampingScrollPhysics(),
    child: Row(
      spacing: Spacing.d6,
      children: keys,
    ),
  );
}
