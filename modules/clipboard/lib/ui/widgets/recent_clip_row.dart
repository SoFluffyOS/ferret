import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One clip in Recent clips: what it holds (or a cover when previews are
/// hidden), where it came from, and Copy.
class RecentClipRow extends StatelessWidget {
  const RecentClipRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.copyLabel,
    required this.isCopied,
    required this.onCopy,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// "Copy", or "Copied" once [isCopied].
  final String copyLabel;
  final bool isCopied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => GroupedRow(
    leading: IconTile(icon: icon, color: PlaceColor.blue),
    title: title,
    titleMaxLines: 2,
    subtitle: subtitle,
    trailing: Button(
      mainAxisSize: .min,
      variant: .ghost,
      label: copyLabel,
      enable: !isCopied,
      onPressed: onCopy,
    ),
  );
}
