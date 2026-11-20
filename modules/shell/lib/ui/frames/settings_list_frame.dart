import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The rows of Settings: a row per group of features with its state, then
/// Advanced and About. The same rows in the popover, on a phone and next
/// to the open page in a window; only what a tap does differs.
class SettingsListFrame extends StatelessWidget {
  const SettingsListFrame({
    super.key,
    required this.onPick,
    this.picked,
    this.showsThisDevice = false,
    this.between = const [],
  });

  final void Function(SettingsPick pick) onPick;

  /// The row whose page is open next to the list. Null where a row opens
  /// its page over the list, and the rows show a chevron instead.
  final SettingsPick? picked;

  /// Whether this device is a row too, where its settings have a page of
  /// their own.
  final bool showsThisDevice;

  /// What sits between the groups and Advanced.
  final List<Widget> between;

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final l10n = context.shellL10n;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (showsThisDevice) ...[
          GroupedCard(
            separatorIndent: NavRow.placeIndent,
            children: [
              _row(
                l10n.settingsThisDevice,
                const ThisDevicePick(),
                icon: deviceIconFor(
                  scope.featureContext.engine.device.formFactor,
                  scope.featureContext.engine.device.platform,
                ),
              ),
            ],
          ),
          Spacing.v24,
        ],
        FeatureChangesListener(features: scope.features, builder: _groups),
        ...between,
        Spacing.v24,
        GroupedCard(
          separatorIndent: NavRow.placeIndent,
          children: [
            _row(l10n.settingsAdvanced, const AdvancedPick()),
            _row(l10n.settingsAbout, const AboutPick()),
          ],
        ),
      ],
    );
  }

  Widget _groups(BuildContext context) {
    final scope = ShellScope.of(context);
    final l10n = context.shellL10n;
    final local = scope.featureContext.engine.device;
    final rows = SettingsRow.from([
      for (final feature in scope.features)
        ...feature.settingsSections(context, scope.featureContext),
    ]);
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return GroupedCard(
      separatorIndent: NavRow.placeIndent,
      children: [
        for (final row in rows)
          _row(
            l10n.settingsGroupTitle(row.group, local),
            GroupPick(row.group),
            value: l10n.settingsRowValue(row),
            attentionLabel: switch (row.needsAttention) {
              true => l10n.settingsNeedsAttention,
              false => null,
            },
          ),
      ],
    );
  }

  Widget _row(
    String title,
    SettingsPick pick, {
    String value = '',
    String? attentionLabel,
    IconData? icon,
  }) => NavRow(
    title: title,
    value: value,
    attentionLabel: attentionLabel,
    place: switch (icon) {
      final icon? => (icon: icon, color: pick.place.color),
      null => pick.place,
    },
    isSelected: pick == picked,
    showsChevron: picked == null,
    onTap: () => onPick(pick),
  );
}
