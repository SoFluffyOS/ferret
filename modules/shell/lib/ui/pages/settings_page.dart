import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:shell/ui/pages/about_page.dart';
import 'package:shell/ui/pages/advanced_settings_page.dart';
import 'package:shell/ui/pages/settings_group_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Settings as one short list: this device, then a row per group of
/// features that shows its current state and opens its own page. With room
/// for two columns, the list stays and the page opens next to it.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final engine = scope.featureContext.engine;
    final l10n = context.shellL10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= PaneWidths.content) {
          return const SettingsSplitFrame();
        }

        return _stacked(context, scope, engine, l10n);
      },
    );
  }

  Widget _stacked(
    BuildContext context,
    ShellScope scope,
    FerretEngine engine,
    ShellLocalizations l10n,
  ) {
    return FerretPage(
      title: l10n.settingsTitle,
      backLabel: l10n.back,
      children: [
        ThisDeviceCard(engine: engine),
        Spacing.v8,
        FeatureChangesListener(
          features: scope.features,
          builder: (context) => _GroupRows(local: engine.device),
        ),
        BackgroundSettings(settings: engine.settings),
        const DockSettings(),
        Spacing.v8,
        SurfaceCard(
          padding: EdgeInsets.symmetric(
            horizontal: Spacing.d8,
            vertical: Spacing.d4,
          ),
          child: Column(
            children: [
              NavRow(
                title: l10n.settingsAdvanced,
                onTap: () => _open(context, const AdvancedSettingsPage()),
              ),
              NavRow(
                title: l10n.settingsAbout,
                onTap: () => _open(context, const AboutPage()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupRows extends StatelessWidget {
  const _GroupRows({required this.local});

  final LocalDevice local;

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final l10n = context.shellL10n;
    final rows = SettingsRow.from([
      for (final feature in scope.features)
        ...feature.settingsSections(context, scope.featureContext),
    ]);
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return SurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.d8,
        vertical: Spacing.d4,
      ),
      child: Column(
        children: [
          for (final row in rows)
            NavRow(
              title: l10n.settingsGroupTitle(row.group, local),
              value: l10n.settingsRowValue(row),
              attentionLabel: switch (row.needsAttention) {
                true => l10n.settingsNeedsAttention,
                false => null,
              },
              onTap: () => _open(context, SettingsGroupPage(group: row.group)),
            ),
        ],
      ),
    );
  }
}

void _open(BuildContext context, Widget page) {
  Navigator.of(
    context,
  ).push(ferretRoute<void>(page));
}
