import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The rounded box a text sits in, on the right for the phone's owner.
class Bubble extends StatelessWidget {
  const Bubble({
    super.key,
    required this.mine,
    required this.child,
    this.faded = false,
  });

  final bool mine;
  final bool faded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = Radius.circular(Spacing.d16);
    final tail = Radius.circular(Spacing.d4);

    return Align(
      alignment: switch (mine) {
        true => AlignmentDirectional.centerEnd,
        false => AlignmentDirectional.centerStart,
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Spacing.d440),
        child: Opacity(
          opacity: switch (faded) {
            true => 0.6,
            false => 1,
          },
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: switch (mine) {
                true => palette.accent,
                false => palette.surface,
              },
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadiusDirectional.only(
                  topStart: radius,
                  topEnd: radius,
                  bottomStart: switch (mine) {
                    true => radius,
                    false => tail,
                  },
                  bottomEnd: switch (mine) {
                    true => tail,
                    false => radius,
                  },
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Spacing.d12,
                vertical: Spacing.d8,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
