import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/ui/widgets/status_line.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Why the phone's texts can't be read or answered right now, with a fix.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.text,
    this.tone = .warning,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final StatusTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        StatusLine(text: text, tone: tone),
        if (actionLabel case final label?) ...[
          Spacing.v8,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GhostButton(
              mainAxisSize: .min,
              label: label,
              onPressed: onAction,
            ),
          ),
        ],
      ],
    ),
  );
}
