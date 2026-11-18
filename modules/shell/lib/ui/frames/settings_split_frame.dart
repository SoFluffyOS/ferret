import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/pages/about_page.dart';
import 'package:shell/ui/pages/advanced_settings_page.dart';
import 'package:shell/ui/pages/settings_group_page.dart';
import 'package:shell/ui/pages/this_device_settings_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Settings where there is room for two columns: the rows on the left, each
/// with its state, and the one that is picked open next to them. It starts
/// on the first row, so the right side is never empty.
class SettingsSplitFrame extends StatefulWidget {
  const SettingsSplitFrame({super.key});

  /// How wide the rows are.
  static const double listWidth = 280;

  @override
  State<SettingsSplitFrame> createState() => _SettingsSplitFrameState();
}

class _SettingsSplitFrameState extends State<SettingsSplitFrame> {
  SettingsPick _pick = const ThisDevicePick();

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final palette = context.palette;
    final l10n = context.shellL10n;

    return ColoredBox(
      color: palette.background,
      child: Row(
        crossAxisAlignment: .stretch,
        children: [
          SizedBox(
            width: SettingsSplitFrame.listWidth,
            child: SafeArea(
              right: false,
              child: FocusTraversalGroup(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: Spacing.d12),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        Spacing.d16,
                        Spacing.d0,
                        Spacing.d16,
                        Spacing.d8,
                      ),
                      child: Text(
                        l10n.settingsTitle,
                        style: context.fluffyTheme.typography.title2.copyWith(
                          color: palette.text,
                        ),
                      ),
                    ),
                    _row(l10n.settingsThisDevice, const ThisDevicePick()),
                    FeatureChangesListener(
                      features: scope.features,
                      builder: _groupRows,
                    ),
                    Spacing.v8,
                    _row(l10n.settingsAdvanced, const AdvancedPick()),
                    _row(l10n.settingsAbout, const AboutPick()),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: FocusTraversalGroup(
              child: KeyedSubtree(
                key: ValueKey(_pick),
                child: switch (_pick) {
                  ThisDevicePick() => const ThisDeviceSettingsPage(),
                  GroupPick(:final group) => SettingsGroupPage(group: group),
                  AdvancedPick() => const AdvancedSettingsPage(),
                  AboutPick() => const AboutPage(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupRows(BuildContext context) {
    final scope = ShellScope.of(context);
    final l10n = context.shellL10n;
    final local = scope.featureContext.engine.device;
    final rows = SettingsRow.from([
      for (final feature in scope.features)
        ...feature.settingsSections(context, scope.featureContext),
    ]);

    return Column(
      crossAxisAlignment: .stretch,
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
    String label,
    SettingsPick pick, {
    String value = '',
    String? attentionLabel,
  }) => SidebarRow(
    label: label,
    isSelected: pick == _pick,
    trailing: _RowState(value: value, attentionLabel: attentionLabel),
    onTap: () => setState(() => _pick = pick),
  );
}

/// A row's state at its end: a few words, and a dot when something the
/// person turned on isn't working.
class _RowState extends StatelessWidget {
  const _RowState({required this.value, required this.attentionLabel});

  final String value;
  final String? attentionLabel;

  /// The most of the row the state may take, so the name stays readable.
  static const double _maxWidth = 120;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      mainAxisSize: .min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Text(
            value,
            maxLines: 1,
            overflow: .ellipsis,
            style: context.fluffyTheme.typography.caption1.copyWith(
              color: palette.mutedText,
            ),
          ),
        ),
        if (attentionLabel case final label?) ...[
          Spacing.h6,
          Semantics(
            label: label,
            child: DecoratedBox(
              decoration: BoxDecoration(color: palette.warning, shape: .circle),
              child: SizedBox.square(dimension: Spacing.d8),
            ),
          ),
        ],
      ],
    );
  }
}
