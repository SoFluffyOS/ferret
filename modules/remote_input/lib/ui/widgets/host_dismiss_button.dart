import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class HostDismissButton extends StatelessWidget {
  const HostDismissButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tappable(
    tooltip: label,
    onTap: onTap,
    child: Icon(
      LucideIcons.x,
      size: Spacing.d16,
      color: context.palette.mutedText,
    ),
  );
}
