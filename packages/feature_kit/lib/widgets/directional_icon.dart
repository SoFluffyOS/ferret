import 'package:flutter/widgets.dart';

/// An icon that points along the reading direction, such as a back chevron
/// or a row's "opens a page" chevron. Lucide draws them for left-to-right
/// text; in Arabic or Hebrew this one is flipped, so back still points
/// back.
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon(this.icon, {super.key, this.size, this.color});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Transform.flip(
    flipX: Directionality.of(context) == TextDirection.rtl,
    child: Icon(icon, size: size, color: color),
  );
}
