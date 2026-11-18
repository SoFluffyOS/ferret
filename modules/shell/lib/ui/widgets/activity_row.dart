import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/row_action_button.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One line of Activity: what happened and with which device, when, a
/// second line with the detail, and what to do about it.
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.item, required this.now});

  final ActivityItem item;

  /// The moment "2 min" is counted from.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final iconActions = [
      for (final action in item.actions)
        if (action.icon != null) action,
    ];
    final textActions = [
      for (final action in item.actions)
        if (action.icon == null) action,
    ];
    final detail = item.detail;
    final time = _time(context.shellL10n);

    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.d4,
        vertical: Spacing.d6,
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: Spacing.d2),
            child: Icon(
              item.icon,
              size: Spacing.d16,
              color: _toneColor(palette),
            ),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: typography.base2.copyWith(color: palette.text),
                      ),
                    ),
                    if (time != null && iconActions.isEmpty) ...[
                      Spacing.h8,
                      Text(
                        time,
                        style: typography.caption1.copyWith(
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                    for (final action in iconActions)
                      _IconAction(action: action),
                  ],
                ),
                if (detail != null || textActions.isNotEmpty) ...[
                  Spacing.vertical(Spacing.d2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          detail ?? '',
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: typography.caption1.copyWith(
                            color: palette.mutedText,
                          ),
                        ),
                      ),
                      for (final action in textActions) ...[
                        Spacing.h8,
                        _TextAction(action: action),
                      ],
                    ],
                  ),
                ],
                if (item.progress case final progress?) ...[
                  Spacing.v6,
                  _ProgressBar(progress: progress),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final onTap = item.onTap;
    if (onTap == null) {
      return row;
    }

    return Tappable(onTap: onTap, child: row);
  }

  String? _time(ShellLocalizations l10n) {
    final at = item.at;
    if (at == null || item.pinned) {
      return null;
    }

    final elapsed = now.difference(at);
    return switch (elapsed) {
      Duration(inMinutes: < 1) => l10n.activityNow,
      Duration(inHours: < 1) => l10n.activityMinutes(elapsed.inMinutes),
      Duration(inDays: < 1) => l10n.activityHours(elapsed.inHours),
      _ => l10n.activityDays(elapsed.inDays),
    };
  }

  Color _toneColor(FerretPalette palette) => switch (item.tone) {
    .normal || .muted => palette.mutedText,
    .accent => palette.accent,
    .success => palette.success,
    .warning => palette.warning,
    .danger => palette.danger,
  };
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.action});

  final ActivityAction action;

  @override
  Widget build(BuildContext context) {
    if (action.primary) {
      return RowActionButton(
        label: action.label,
        isPrimary: true,
        onPressed: action.onPressed,
      );
    }

    return Tappable(
      onTap: action.onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.d4,
          vertical: Spacing.d2,
        ),
        child: Text(
          action.label,
          style: context.fluffyTheme.typography.caption1.copyWith(
            color: context.palette.accent,
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.action});

  final ActivityAction action;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      tooltip: action.label,
      onTap: action.onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Spacing.d6),
        child: Icon(
          action.icon,
          size: Spacing.d16,
          color: context.palette.text,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Spacing.d2),
      child: ColoredBox(
        color: palette.surface,
        child: Align(
          alignment: .centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0, 1).toDouble(),
            child: ColoredBox(
              color: palette.accent,
              child: SizedBox(height: Spacing.d4),
            ),
          ),
        ),
      ),
    );
  }
}
