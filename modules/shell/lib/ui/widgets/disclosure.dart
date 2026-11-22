import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A line that opens to show [children]: for what few people need, such as
/// a device's ID.
class Disclosure extends StatefulWidget {
  const Disclosure({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  State<Disclosure> createState() => _DisclosureState();
}

class _DisclosureState extends State<Disclosure> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Semantics(
          expanded: _open,
          child: Tappable(
            semanticButton: true,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: PageInsets.row,
                vertical: Spacing.d12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: typography.base2.copyWith(color: palette.text),
                    ),
                  ),
                  Icon(
                    switch (_open) {
                      true => LucideIcons.chevronUp,
                      false => LucideIcons.chevronDown,
                    },
                    size: Spacing.d16,
                    color: palette.mutedText,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: Spacing.d4,
              end: Spacing.d4,
              bottom: Spacing.d8,
            ),
            child: Column(
              crossAxisAlignment: .start,
              children: widget.children,
            ),
          ),
      ],
    );
  }
}
