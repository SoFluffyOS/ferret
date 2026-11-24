import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What the list of devices near you says when it is empty: still looking,
/// nothing found, or not allowed to look, with the one thing to do about it.
class NearbyNotice extends StatelessWidget {
  const NearbyNotice({
    super.key,
    required this.body,
    this.title,
    this.actionLabel,
    this.onAction,
    this.isPrimary = false,
    this.holdsRoomFor,
  });

  final String? title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Whether the action is the screen's one primary button.
  final bool isPrimary;

  /// What this notice turns into next, such as "No devices found yet" with
  /// Look again once looking ends. Its room is held from the start, so a
  /// link below never moves under the pointer.
  final ({String body, String actionLabel})? holdsRoomFor;

  @override
  Widget build(BuildContext context) {
    final content = _content(
      context,
      title: title,
      body: body,
      actionLabel: actionLabel,
      onAction: onAction,
    );

    return SurfaceCard(
      padding: EdgeInsets.all(Spacing.d16),
      child: switch (holdsRoomFor) {
        final next? => Stack(
          alignment: .center,
          children: [
            ExcludeSemantics(
              child: Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: _content(
                  context,
                  body: next.body,
                  actionLabel: next.actionLabel,
                ),
              ),
            ),
            content,
          ],
        ),
        null => content,
      },
    );
  }

  Widget _content(
    BuildContext context, {
    String? title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Column(
      mainAxisSize: .min,
      children: [
        if (title case final title?) ...[
          Text(
            title,
            textAlign: .center,
            style: typography.base1.copyWith(color: palette.text),
          ),
          Spacing.v4,
        ],
        Text(
          body,
          textAlign: .center,
          style: typography.base2.copyWith(color: palette.mutedText),
        ),
        if (actionLabel case final label?) ...[
          Spacing.v12,
          GhostFill(
            applies: !isPrimary,
            child: ButtonFocusRing(
              builder: (context, keyboardFocused) => Button(
                mainAxisSize: .min,
                variant: switch (isPrimary) {
                  true => .primary,
                  false => .ghost,
                },
                borderWidth: switch (keyboardFocused) {
                  true => 0,
                  false => null,
                },
                label: label,
                onPressed: onAction,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
