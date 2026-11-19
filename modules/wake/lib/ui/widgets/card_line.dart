import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/protocol.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:wake/l10n/l10n.dart';

/// One network card and whether it can wake its computer, in words.
class CardLine extends StatelessWidget {
  const CardLine({super.key, required this.link, required this.setting});

  final WakeLink link;
  final WakeSetting setting;

  @override
  Widget build(BuildContext context) {
    final l10n = context.wakeL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final (text, color) = switch ((link, setting)) {
      (.WAKE_LINK_WIFI, _) => (l10n.cardWifi, palette.warning),
      (_, .WAKE_SETTING_ON) => (l10n.cardWiredOn, palette.success),
      (_, .WAKE_SETTING_OFF) => (l10n.cardWiredOff, palette.warning),
      _ => (l10n.cardWiredUnknown, palette.mutedText),
    };

    return Row(
      children: [
        Icon(
          switch (link) {
            .WAKE_LINK_WIFI => LucideIcons.wifi,
            _ => LucideIcons.ethernetPort,
          },
          size: Spacing.d16,
          color: color,
        ),
        Spacing.h8,
        Expanded(
          child: Text(
            text,
            style: typography.base2.copyWith(color: palette.text),
          ),
        ),
      ],
    );
  }
}
