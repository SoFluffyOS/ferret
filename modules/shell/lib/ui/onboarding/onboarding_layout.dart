import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One onboarding step: a big title, a short line, the step's content, and
/// the buttons at the bottom where thumbs reach them.
class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    required this.body,
    required this.child,
    required this.actions,
    this.icon,
  });

  final int step;
  final int total;
  final String title;
  final String body;
  final Widget child;
  final List<Widget> actions;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return ColoredBox(
      color: palette.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Spacing.d20,
            Spacing.d16,
            Spacing.d20,
            Spacing.d16,
          ),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Text(
                context.shellL10n.onboardStep(step, total),
                style: typography.caption1.copyWith(color: palette.mutedText),
              ),
              Spacing.v16,
              if (icon case final icon?) ...[
                Icon(icon, size: Spacing.d36, color: palette.accent),
                Spacing.v12,
              ],
              Text(
                title,
                style: typography.title1.copyWith(color: palette.text),
              ),
              Spacing.v8,
              Text(
                body,
                style: typography.body1.copyWith(color: palette.mutedText),
              ),
              Spacing.vertical(Spacing.d20),
              Expanded(child: SingleChildScrollView(child: child)),
              Spacing.v12,
              for (final (index, action) in actions.indexed) ...[
                if (index > 0) Spacing.v8,
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
