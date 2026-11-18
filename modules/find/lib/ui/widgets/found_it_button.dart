import 'package:find/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The big "Found it" button that stops this device ringing.
class FoundItButton extends StatelessWidget {
  const FoundItButton({super.key, required this.onPressed, this.large = false});

  final VoidCallback onPressed;

  /// Fills the bottom of the ringing screen, easy to hit in a hurry.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final height = switch (large) {
      true => Spacing.d80,
      false => Spacing.d48,
    };

    return Button(
      variant: .primary,
      label: context.findL10n.foundIt,
      icon: Icon(LucideIcons.circleCheck, size: Spacing.d20),
      height: height,
      onPressed: onPressed,
    );
  }
}
