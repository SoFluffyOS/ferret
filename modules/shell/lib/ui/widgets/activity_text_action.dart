import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/row_action_button.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

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
    final spoken = switch ((action.tooltip, subject)) {
      (final tooltip?, _) => tooltip,
      (null, final subject?) => context.shellL10n.activityActionFor(
        action.label,
        subject,
      ),
      (null, null) => null,
    };
    if (action.primary) {
      return RowActionButton(
        label: action.label,
        semanticLabel: spoken,
        tooltip: action.tooltip,
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
      child: _withTooltip(
        TextLink(
          label: action.label,
          semanticLabel: spoken,
          onTap: action.onPressed,
          alignment: switch (reachesDown) {
            true => Alignment.topCenter,
            false => Alignment.center,
          },
        ),
      ),
    );
  }

  Widget _withTooltip(Widget child) => switch (action.tooltip) {
    final tooltip? => FluffyTooltip(message: tooltip, child: child),
    null => child,
  };
}
