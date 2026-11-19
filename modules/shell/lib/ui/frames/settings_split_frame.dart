import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/models/models.dart';
import 'package:shell/ui/frames/settings_list_frame.dart';
import 'package:shell/ui/pages/about_page.dart';
import 'package:shell/ui/pages/advanced_settings_page.dart';
import 'package:shell/ui/pages/settings_group_page.dart';
import 'package:shell/ui/pages/this_device_settings_page.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Settings where there is room for two columns: the rows on the left, each
/// with its state, and the one that is picked open next to them. It starts
/// on the first row, so the right side is never empty.
class SettingsSplitFrame extends StatefulWidget {
  const SettingsSplitFrame({super.key});

  @override
  State<SettingsSplitFrame> createState() => _SettingsSplitFrameState();
}

class _SettingsSplitFrameState extends State<SettingsSplitFrame> {
  SettingsPick _pick = const ThisDevicePick();

  @override
  Widget build(BuildContext context) {
    final side = PageInsets.side(context.screenSize);

    return ColoredBox(
      color: context.palette.background,
      child: Row(
        crossAxisAlignment: .stretch,
        children: [
          SizedBox(
            width: PaneWidths.settingsList,
            child: SafeArea(
              right: false,
              child: FocusTraversalGroup(
                child: ListView(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    side,
                    Spacing.d12,
                    Spacing.d0,
                    Spacing.d24,
                  ),
                  children: [
                    SettingsListFrame(
                      picked: _pick,
                      showsThisDevice: true,
                      onPick: (pick) => setState(() => _pick = pick),
                    ),
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
}
