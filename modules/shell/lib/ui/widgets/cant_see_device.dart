import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The way out when the device to pair isn't listed: closed, one quiet
/// button; open, what to check first and then [children], the other ways
/// to pair.
class CantSeeDevice extends StatefulWidget {
  const CantSeeDevice({super.key, required this.children, this.onOpened});

  final List<Widget> children;

  /// Called the first time it opens, to prepare what [children] show.
  final VoidCallback? onOpened;

  @override
  State<CantSeeDevice> createState() => _CantSeeDeviceState();
}

class _CantSeeDeviceState extends State<CantSeeDevice> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Spacing.v16,
        if (!_open)
          Button(
            variant: .ghost,
            label: l10n.pairCantSee,
            titleExpand: .shrink,
            onPressed: _reveal,
          ),
        if (_open) ...[
          SectionTitle(l10n.pairCantSee),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.d4),
            child: Text(
              l10n.pairCantSeeSteps,
              style: context.fluffyTheme.typography.base2.copyWith(
                color: context.palette.mutedText,
              ),
            ),
          ),
          ...widget.children,
        ],
      ],
    );
  }

  void _reveal() {
    setState(() => _open = true);
    widget.onOpened?.call();
  }
}
