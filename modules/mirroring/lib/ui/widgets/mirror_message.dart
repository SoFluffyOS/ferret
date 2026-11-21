import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A button under a [MirrorMessage].
class MessageAction {
  const MessageAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;

  /// Null draws the button but leaves it off, such as while a wait runs.
  final VoidCallback? onPressed;

  /// The real next step. One per message.
  final bool primary;
}

/// What the mirror stage says when there is no picture: where things
/// stand in plain words, what else there is to know, and the buttons for
/// what to do next.
class MirrorMessage extends StatelessWidget {
  const MirrorMessage({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.tone = .muted,
    this.children = const [],
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String? body;
  final FeatureTone tone;

  /// What goes between the words and the buttons, such as a countdown.
  final List<Widget> children;
  final List<MessageAction> actions;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final iconColor = switch (tone) {
      .accent => palette.link,
      .danger => palette.danger,
      .warning => palette.warning,
      .success => palette.success,
      .normal => palette.text,
      .muted => palette.mutedText,
    };

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(Spacing.d24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Spacing.d360),
          child: Column(
            mainAxisSize: .min,
            children: [
              Icon(icon, size: Spacing.d32, color: iconColor),
              Spacing.v12,
              Text(
                title,
                textAlign: .center,
                style: typography.base1.copyWith(color: palette.text),
              ),
              if (body case final body?) ...[
                Spacing.v4,
                Text(
                  body,
                  textAlign: .center,
                  style: typography.caption1.copyWith(color: palette.mutedText),
                ),
              ],
              ...children,
              if (actions.isNotEmpty) ...[
                Spacing.v16,
                Wrap(
                  alignment: .center,
                  spacing: Spacing.d8,
                  runSpacing: Spacing.d8,
                  children: [
                    for (final action in actions)
                      GhostFill(
                        applies: !action.primary,
                        child: ButtonFocusRing(
                          builder: (context, keyboardFocused) => Button(
                            variant: switch (action.primary) {
                              true => .primary,
                              false => .ghost,
                            },
                            borderWidth: switch (keyboardFocused) {
                              true => 0,
                              false => null,
                            },
                            mainAxisSize: .min,
                            enable: action.onPressed != null,
                            label: action.label,
                            onPressed: action.onPressed,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
