import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:shell/ui/pages/about_page.dart';
import 'package:shell/ui/pages/advanced_settings_page.dart';
import 'package:shell/ui/pages/settings_group_page.dart';
import 'package:shell/ui/pages/this_device_settings_page.dart';
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
        Spacing.v24,
        SettingsListFrame(
          onPick: (pick) => _open(context, switch (pick) {
            ThisDevicePick() => const ThisDeviceSettingsPage(),
            GroupPick(:final group) => SettingsGroupPage(group: group),
            AdvancedPick() => const AdvancedSettingsPage(),
            AboutPick() => const AboutPage(),
          }),
          between: [
            BackgroundSettings(settings: engine.settings),
            const DockSettings(),
          ],
        ),
      ],
    );
  }
}

void _open(BuildContext context, Widget page) {
  Navigator.of(
    context,
  ).push(ferretRoute<void>(page));
}
