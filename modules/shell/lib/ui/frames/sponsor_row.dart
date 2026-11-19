import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Settings → About: opens the sponsor page in the browser.
class SponsorRow extends StatelessWidget {
  const SponsorRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;

    return GroupedRow(
      title: l10n.settingsSponsor,
      subtitle: l10n.settingsSponsorDetail,
      leading: const IconTile(icon: LucideIcons.heart, color: .pink),
      trailing: Icon(
        LucideIcons.externalLink,
        size: Spacing.d16,
        color: context.palette.mutedText,
      ),
      onTap: () => unawaited(Sponsor.open()),
    );
  }
}
