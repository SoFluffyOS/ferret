import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One row of Settings, opened: the settings of every feature in [group],
/// each built by its own feature.
class SettingsGroupPage extends StatelessWidget {
  const SettingsGroupPage({super.key, required this.group});

  final SettingsGroup group;

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final l10n = context.shellL10n;
    final title = l10n.settingsGroupTitle(
      group,
      scope.featureContext.engine.device,
    );

    return FeatureChangesListener(
      features: scope.features,
      builder: (context) {
        final sections = [
          for (final feature in scope.features)
            for (final section in feature.settingsSections(
              context,
              scope.featureContext,
            ))
              if (section.group == group) section,
        ];

        return FerretPage(
          title: title,
          backLabel: l10n.back,
          children: [
            if (sections.isEmpty)
              Text(
                l10n.settingsNothingHere,
                style: context.fluffyTheme.typography.body2.copyWith(
                  color: context.palette.mutedText,
                ),
              ),
            for (final section in sections) ...[
              if (sections.length > 1 || section.title != title)
                SectionTitle(section.title),
              switch (sections.length > 1) {
                true => SharedPageScope(child: section.child),
                false => section.child,
              },
              Spacing.v8,
            ],
          ],
        );
      },
    );
  }
}
