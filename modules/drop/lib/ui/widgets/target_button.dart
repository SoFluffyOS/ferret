import 'package:drop/models/models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One device in the picker. Tapping it closes the picker with [target],
/// to open a shared link there when [opens].
class TargetButton extends StatelessWidget {
  const TargetButton({
    super.key,
    required this.target,
    this.caption,
    this.opens = false,
    this.label,
  });

  final DropTarget target;
  final bool opens;

  /// What the row says instead of the device's name, such as "Open on
  /// MacBook Pro".
  final String? label;

  /// What kind of device it is when it isn't a paired one, such as
  /// "LocalSend · iPhone".
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d8),
      child: Tappable(
        semanticButton: true,
        onTap: () => Navigator.of(context).pop(DropPick(target, opens: opens)),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: palette.background,
            shape: Corners.shape(Corners.row),
          ),
          child: Padding(
            padding: EdgeInsets.all(Spacing.d12),
            child: Row(
              children: [
                Icon(
                  switch (opens) {
                    true => LucideIcons.externalLink,
                    false => deviceIconFor(target.formFactor, target.platform),
                  },
                  size: Spacing.d16,
                  color: palette.text,
                ),
                Spacing.h8,
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        label ?? target.name,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: typography.base1.copyWith(color: palette.text),
                      ),
                      if (caption case final line?)
                        Text(
                          line,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: typography.caption1.copyWith(
                            color: palette.mutedText,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
