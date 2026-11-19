import 'package:calls/l10n/l10n.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/calls.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One recent call: who, what kind, when and how long. Tapping it picks its
/// number.
class CallLogRow extends StatelessWidget {
  const CallLogRow({super.key, required this.entry, required this.onTap});

  final CallLogEntry entry;

  /// Null when the entry has no number to call back.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.callsL10n;
    final missed = entry.type == CallLogType.CALL_LOG_TYPE_MISSED;
    final icon = switch (entry.type) {
      .CALL_LOG_TYPE_OUTGOING => LucideIcons.phoneOutgoing,
      .CALL_LOG_TYPE_MISSED => LucideIcons.phoneMissed,
      .CALL_LOG_TYPE_REJECTED => LucideIcons.phoneOff,
      _ => LucideIcons.phoneIncoming,
    };
    final accent = switch (missed) {
      true => palette.danger,
      false => palette.mutedText,
    };
    final details = [
      l10n.logTypeOf(entry.type),
      if (entry.name.isNotEmpty && entry.number.isNotEmpty) entry.number,
      _when(context),
      if (entry.durationS > 0)
        ClockText.duration(Duration(seconds: entry.durationS.toInt())),
    ].join(' · ');

    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d8),
      child: Row(
        children: [
          Icon(icon, size: Spacing.d16, color: accent),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  l10n.logCallerOf(entry),
                  style: typography.base1.copyWith(color: palette.text),
                  overflow: .ellipsis,
                ),
                Spacing.vertical(Spacing.d2),
                Text(
                  details,
                  style: typography.caption1.copyWith(color: palette.mutedText),
                  overflow: .ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return row;
    }

    return Tappable(onTap: onTap, child: row);
  }

  String _when(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateTime.fromMillisecondsSinceEpoch(entry.dateMs.toInt());

    return _formatFor(locale).format(date);
  }

  /// intl throws for a locale whose date symbols were never loaded; the
  /// default format is better than no row.
  DateFormat _formatFor(String locale) {
    try {
      return DateFormat.MMMd(locale).add_jm();
    } on Object {
      return DateFormat.MMMd().add_jm();
    }
  }
}
