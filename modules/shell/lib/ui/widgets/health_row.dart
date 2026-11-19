import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One feature under "What works" on a device's page: a check when it
/// works, a dash when it is off (with how to turn it on), a warning when it
/// is broken (with a fix).
class HealthRow extends StatefulWidget {
  const HealthRow({
    super.key,
    required this.title,
    required this.health,
    required this.howLabel,
    required this.fixLabel,
  });

  final String title;
  final FeatureHealth health;
  final String howLabel;
  final String fixLabel;

  @override
  State<HealthRow> createState() => _HealthRowState();
}

class _HealthRowState extends State<HealthRow> {
  bool _showsHelp = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final health = widget.health;
    final muted = typography.caption1.copyWith(color: palette.mutedText);
    final l10n = context.shellL10n;
    final (icon, color, spoken) = switch (health.state) {
      .ok => (LucideIcons.check, palette.success, l10n.spokenOk),
      .off => (LucideIcons.minus, palette.mutedText, l10n.spokenOff),
      .needsAttention || .failing => (
        LucideIcons.triangleAlert,
        palette.warning,
        l10n.spokenWarning,
      ),
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d6),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: Spacing.d2),
            child: Icon(
              icon,
              size: Spacing.d16,
              color: color,
              semanticLabel: spoken,
            ),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  widget.title,
                  style: typography.base2.copyWith(color: palette.text),
                ),
                if (health.reason.isNotEmpty) Text(health.reason, style: muted),
                if (_showsHelp) ...[
                  Spacing.v4,
                  Text(
                    health.help,
                    style: typography.caption1.copyWith(color: palette.text),
                  ),
                ],
              ],
            ),
          ),
          if (_action case (final label, final onTap)?)
            Tappable(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  Spacing.d12,
                  Spacing.d2,
                  Spacing.d4,
                  Spacing.d8,
                ),
                child: Text(
                  label,
                  style: typography.base2.copyWith(color: palette.link),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// A fix this device can do comes first; otherwise the steps, when the
  /// feature gave some. Something that works needs neither.
  (String, VoidCallback)? get _action {
    final health = widget.health;
    if (health.state == .ok) {
      return null;
    }

    if (health.onFix case final onFix?) {
      return (widget.fixLabel, onFix);
    }

    if (health.help.isEmpty) {
      return null;
    }

    return (widget.howLabel, () => setState(() => _showsHelp = !_showsHelp));
  }
}
