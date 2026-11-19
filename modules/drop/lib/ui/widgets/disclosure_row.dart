import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A quiet row that opens in place to show [children]. Stays open while
/// [keepOpen] is true, such as while something inside is on.
class DisclosureRow extends StatefulWidget {
  const DisclosureRow({
    super.key,
    required this.title,
    required this.children,
    this.keepOpen = false,
  });

  final String title;
  final List<Widget> children;
  final bool keepOpen;

  @override
  State<DisclosureRow> createState() => _DisclosureRowState();
}

class _DisclosureRowState extends State<DisclosureRow> {
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.keepOpen;
  }

  /// Stays open once what kept it open stops, so the row doesn't jump away
  /// from under the button just pressed.
  @override
  void didUpdateWidget(DisclosureRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keepOpen && !widget.keepOpen) {
      _open = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final open = _open || widget.keepOpen;
    final chevron = switch (open) {
      true => LucideIcons.chevronDown,
      false => LucideIcons.chevronRight,
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Tappable(
          onTap: switch (widget.keepOpen) {
            true => null,
            false => () => setState(() => _open = !_open),
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.d4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: typography.base2.copyWith(color: palette.mutedText),
                  ),
                ),
                DirectionalIcon(
                  chevron,
                  size: Spacing.d16,
                  color: palette.mutedText,
                ),
              ],
            ),
          ),
        ),
        if (open)
          for (final child in widget.children) ...[Spacing.v12, child],
      ],
    );
  }
}
