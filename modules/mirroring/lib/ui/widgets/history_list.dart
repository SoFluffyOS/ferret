import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/widgets/mirroring_labels.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The audit lines of past mirroring, newest first, with Clear.
class HistoryList extends StatelessWidget {
  const HistoryList({
    super.key,
    required this.history,
    required this.emptyText,
    required this.onClear,
  });

  /// How many past times are shown.
  static const shown = 5;

  final List<MirrorRecord> history;
  final String emptyText;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.mirroringL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.settingsHistoryTitle),
        if (history.isEmpty)
          Text(
            emptyText,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
        for (final record in history.take(shown))
          Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.d2),
            child: Text(
              l10n.audit(record),
              style: typography.body2.copyWith(color: palette.text),
            ),
          ),
        if (history.isNotEmpty) ...[
          Spacing.v8,
          Button(
            variant: .secondary,
            label: l10n.clearHistory,
            onPressed: onClear,
          ),
        ],
      ],
    );
  }
}
