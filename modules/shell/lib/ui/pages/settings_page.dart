import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// This device, each feature's settings, and the privacy promise.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final engine = scope.featureContext.engine;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final sections = [
      for (final feature in scope.features)
        if (feature.buildSettings(context, scope.featureContext)
            case final section?)
          (feature, section),
    ];

    return FerretPage(
      title: l10n.settingsTitle,
      backLabel: l10n.back,
      children: [
        SectionTitle(l10n.settingsThisDevice),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                engine.device.name,
                style: typography.base1.copyWith(color: palette.text),
              ),
              Spacing.v4,
              Text(
                l10n.settingsDeviceId(
                  DeviceIdentity.format(engine.identity.deviceId),
                ),
                style: typography.caption1.copyWith(color: palette.mutedText),
              ),
              Text(
                l10n.settingsPort(engine.port),
                style: typography.caption1.copyWith(color: palette.mutedText),
              ),
            ],
          ),
        ),
        BackgroundSettings(settings: engine.settings),
        for (final (feature, section) in sections) ...[
          SectionTitle(feature.title(context)),
          section,
        ],
        SectionTitle(l10n.settingsPrivacy),
        SurfaceCard(
          child: Text(
            l10n.settingsPrivacyBody,
            style: typography.body2.copyWith(color: palette.mutedText),
          ),
        ),
        Spacing.v24,
        Button(
          variant: .ghost,
          label: l10n.settingsQuit,
          onPressed: SystemNavigator.pop,
        ),
      ],
    );
  }
}
