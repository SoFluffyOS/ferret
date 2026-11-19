import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The privacy promise, a way to see the tips again, the sponsor page, the
/// version and the licence.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = ShellScope.of(context).featureContext.engine;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final muted = typography.caption1.copyWith(color: palette.mutedText);

    return FerretPage(
      title: l10n.settingsAbout,
      backLabel: l10n.back,
      children: [
        SectionTitle(l10n.settingsPrivacy),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Text(
                l10n.settingsPrivacyBody,
                style: typography.body2.copyWith(color: palette.text),
              ),
              Spacing.v8,
              Text(l10n.settingsPrivacyPerDevice, style: muted),
            ],
          ),
        ),
        Spacing.v24,
        const GroupedCard(children: [TipsAgainRow(), SponsorRow()]),
        Spacing.v16,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PageInsets.row),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                l10n.settingsVersion(engine.device.appVersion),
                style: muted,
              ),
              Spacing.v4,
              Text(l10n.settingsLicense, style: muted),
              Spacing.v4,
              Wrap(
                crossAxisAlignment: .center,
                children: [
                  Text(l10n.settingsOpenSource, style: muted),
                  TextLink(
                    label: l10n.settingsSponsorLink,
                    onTap: () => unawaited(Sponsor.open()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
