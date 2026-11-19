import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A count at the end of a line in the device list, such as unread texts.
class SidebarBadge extends StatelessWidget {
  const SidebarBadge(this.count, {super.key});

  final int count;

  /// Past this the badge says "99+": the exact number stops mattering.
  static const _most = 99;

  @override
  Widget build(BuildContext context) {
    final label = switch (count > _most) {
      true => '$_most+',
      false => '$count',
    };

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: context.palette.accent,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.d6,
          vertical: Spacing.d1,
        ),
        child: Text(
          label,
          style: context.fluffyTheme.typography.caption1.copyWith(
            color: const Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }
}
