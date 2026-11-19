import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/row_action_button.dart';

class ActivityTextAction extends StatelessWidget {
  const ActivityTextAction({
    super.key,
    required this.action,
    required this.filled,
    required this.isShown,
    this.reachesDown = false,
    this.subject,
  });

  final ActivityAction action;
  final bool filled;

  /// A link that isn't shown keeps its place and can still be reached.
  final bool isShown;

  /// Next to the detail, the link's words line up with it and its target
  /// goes on below them. Among buttons it is centred like they are.
  final bool reachesDown;

  /// The line's title, so a screen reader tells this line's "Open" from
  /// another's.
  final String? subject;

  @override
  Widget build(BuildContext context) {
    final spoken = switch (subject) {
      final subject? => context.shellL10n.activityActionFor(
        action.label,
        subject,
      ),
      null => null,
    };
    if (action.primary) {
      return RowActionButton(
        label: action.label,
        semanticLabel: spoken,
        isPrimary: filled,
        onPressed: action.onPressed,
      );
    }

    return Opacity(
      opacity: switch (isShown) {
        true => 1,
        false => 0,
      },
      alwaysIncludeSemantics: true,
      child: TextLink(
        label: action.label,
        semanticLabel: spoken,
        onTap: action.onPressed,
        alignment: switch (reachesDown) {
          true => Alignment.topCenter,
          false => Alignment.center,
        },
      ),
    );
  }
}
