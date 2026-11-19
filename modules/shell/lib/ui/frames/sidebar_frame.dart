import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/frames/sidebar_device_group.dart';
import 'package:shell/ui/frames/sidebar_nearby_frame.dart';
import 'package:shell/ui/frames/sidebar_paused_line.dart';
import 'package:shell/ui/frames/whats_new_frame.dart';
import 'package:shell/ui/pages/pages.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A window's device list: your devices, the selected one opened to its
/// sections, who is nearby, then Activity and Settings. What is selected
/// here is what the pane next to it shows. After an update, one line under
/// the list says so.
class SidebarFrame extends StatefulWidget {
  const SidebarFrame({super.key});

  /// From this many devices on, the list gets a search field.
  static const searchFrom = 9;

  @override
  State<SidebarFrame> createState() => _SidebarFrameState();
}

class _SidebarFrameState extends State<SidebarFrame> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Whether [status] matches what was typed, by the name shown here or
  /// the one the device gave itself.
  bool _matches(DeviceStatus status) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final device = status.device;
    return device.name.toLowerCase().contains(query) ||
        device.ownName.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final devices = context.select<EngineHost, List<DeviceStatus>>(
      (host) => host.devices,
    );
    final selection = context.select<WindowNavViewModel, WindowDestination?>(
      (viewModel) => switch (viewModel.shownTitle) {
        null => viewModel.selection,
        _ => null,
      },
    );
    final isPaused = context.select<PauseController, bool>(
      (controller) => controller.isPaused,
    );
    final nav = context.read<WindowNavViewModel>();
    final scope = ShellScope.of(context);
    final l10n = context.shellL10n;
    final platform = defaultTargetPlatform;
    final searches = devices.length >= SidebarFrame.searchFrom;
    final shown = switch (searches) {
      true => devices.where(_matches).toList(),
      false => devices,
    };

    return ColoredBox(
      color: context.palette.surface,
      child: SafeArea(
        right: false,
        child: FocusTraversalGroup(
          child: ArrowKeyStops(
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                if (isPaused) const SidebarPausedLine(),
                Expanded(
                  child: SidebarDropOnAll(
                    devices: devices,
                    child: ListView(
                      padding: EdgeInsets.only(bottom: Spacing.d16),
                      children: [
                        SidebarHeader(
                          title: l10n.homeYourDevices,
                          action: Tappable(
                            tooltip: WindowShortcuts.hint(
                              l10n.homePairDevice,
                              WindowShortcuts.activatorOf(.addDevice, platform),
                              platform,
                            ),
                            semanticLabel: l10n.homePairDevice,
                            hoverOverlayBorderRadius: Corners.tile,
                            onTap: () => nav.show(
                              const PairPage(),
                              title: l10n.pairTitle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(Spacing.d4),
                              child: Icon(
                                LucideIcons.plus,
                                size: Spacing.d16,
                                color: context.palette.mutedText,
                              ),
                            ),
                          ),
                        ),
                        if (searches)
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                              Spacing.d16,
                              0,
                              Spacing.d16,
                              Spacing.d8,
                            ),
                            child: InputText(
                              controller: _search,
                              hintText: l10n.sidebarFind,
                              onChanged: (query) =>
                                  setState(() => _query = query),
                            ),
                          ),
                        if (searches && shown.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: Spacing.d16,
                              vertical: Spacing.d8,
                            ),
                            child: Text(
                              l10n.sidebarNoMatch(_query.trim()),
                              style: context.fluffyTheme.typography.caption1
                                  .copyWith(color: context.palette.mutedText),
                            ),
                          ),
                        for (final status in shown)
                          FeatureChangesListener(
                            key: ValueKey(status.device.id),
                            features: scope.features,
                            builder: (context) => SidebarDeviceGroup(
                              status: status,
                              selection: selection,
                              onSelect: nav.select,
                            ),
                          ),
                        SidebarNearbyFrame(
                          onPair: () =>
                              nav.show(const PairPage(), title: l10n.pairTitle),
                        ),
                        Spacing.v16,
                        SidebarRow(
                          label: l10n.activityTitle,
                          icon: LucideIcons.history,
                          tooltip: WindowShortcuts.hint(
                            l10n.activityTitle,
                            WindowShortcuts.activatorOf(
                              .openActivity,
                              platform,
                            ),
                            platform,
                          ),
                          isSelected: selection is ActivityDestination,
                          onTap: () => nav.select(const ActivityDestination()),
                        ),
                        SidebarRow(
                          label: l10n.settingsTitle,
                          icon: LucideIcons.settings,
                          tooltip: WindowShortcuts.hint(
                            l10n.settingsTitle,
                            WindowShortcuts.activatorOf(
                              .openSettings,
                              platform,
                            ),
                            platform,
                          ),
                          isSelected: selection is SettingsDestination,
                          onTap: () => nav.select(const SettingsDestination()),
                        ),
                      ],
                    ),
                  ),
                ),
                const WhatsNewFrame(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
