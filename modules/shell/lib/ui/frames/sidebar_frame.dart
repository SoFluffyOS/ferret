import 'dart:async';

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
import 'package:shell/ui/frames/sidebar_nearby_frame.dart';
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
      (viewModel) => viewModel.selection,
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
                if (isPaused) const _PausedLine(),
                Expanded(
                  child: _DropOnAll(
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
                            onTap: () => nav.show(const PairPage()),
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
                            builder: (context) => _DeviceGroup(
                              status: status,
                              selection: selection,
                              onSelect: nav.select,
                            ),
                          ),
                        SidebarNearbyFrame(
                          onPair: () => nav.show(const PairPage()),
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

/// Files dropped on the list but on no device in particular go to every
/// connected device.
class _DropOnAll extends StatelessWidget {
  const _DropOnAll({required this.devices, required this.child});

  final List<DeviceStatus> devices;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final target = WindowDropTargets.everyone(devices);
    if (target == null) {
      return child;
    }

    return DropTargetRegion(target: target, child: child);
  }
}

/// Shown only while Ferret is paused, with the way out next to it.
class _PausedLine extends StatelessWidget {
  const _PausedLine();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    // The link's target is the line's height.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.d16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.homeStatusPaused,
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
          ),
          TextLink(
            label: l10n.resume,
            onTap: () => unawaited(context.read<PauseController>().resume()),
            style: typography.base2,
          ),
        ],
      ),
    );
  }
}

/// One device and, while it is the open one, its sections under it.
class _DeviceGroup extends StatelessWidget {
  const _DeviceGroup({
    required this.status,
    required this.selection,
    required this.onSelect,
  });

  final DeviceStatus status;
  final WindowDestination? selection;
  final void Function(WindowDestination destination) onSelect;

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);
    final deviceId = status.device.id;
    final sections = DeviceSections.of(
      context,
      scope.features,
      scope.featureContext,
      status,
    );
    final openSectionId = switch (selection) {
      DeviceDestination(deviceId: final selected, :final sectionId)
          when selected == deviceId =>
        sectionId,
      _ => null,
    };
    final isOpen = openSectionId != null;
    final showsFeatureSection = sections.any(
      (section) => section.id == openSectionId,
    );
    final waiting = sections.fold(
      0,
      (count, section) => count + (section.badge ?? 0),
    );
    final isPinned = context.select<EngineHost, bool>(
      (host) => host.preferences.isPinned(deviceId),
    );
    final dropTarget = WindowDropTargets.device(status);
    final isDropHovered = context.select<OsDropViewModel, bool>(
      (drop) => drop.hovered == dropTarget,
    );

    return DropTargetRegion(
      target: dropTarget,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          ContextMenuRegion(
            entries: _menu(context, scope, sections),
            child: DropSpringOpen(
              active: isDropHovered && status.isConnected && !isOpen,
              onOpen: () => onSelect(DeviceDestination(deviceId)),
              child: SidebarDeviceRow(
                status: status,
                isSelected: isOpen && sections.isEmpty,
                needsAttention: _needsAttention(scope),
                isDropHovered: isDropHovered,
                isPinned: isPinned,
                badge: switch (isOpen) {
                  true => 0,
                  false => waiting,
                },
                onTap: () => onSelect(DeviceDestination(deviceId)),
              ),
            ),
          ),
          if (isOpen && sections.isNotEmpty) ...[
            SidebarRow(
              label: context.shellL10n.sectionOverview,
              icon: LucideIcons.layoutDashboard,
              tooltip: _sectionHint(context.shellL10n.sectionOverview, 0),
              isIndented: true,
              isSelected: !showsFeatureSection,
              onTap: () => onSelect(DeviceDestination(deviceId)),
            ),
            for (final (index, section) in sections.indexed)
              SidebarRow(
                key: ValueKey(section.id),
                label: section.title,
                icon: section.icon,
                tooltip: _sectionHint(section.title, index + 1),
                isIndented: true,
                isDimmed: !section.isSetUp,
                isSelected: section.id == openSectionId,
                trailing: switch (section.badge) {
                  final badge? when badge > 0 => SidebarBadge(badge),
                  _ => null,
                },
                onTap: () => onSelect(
                  DeviceDestination(deviceId, sectionId: section.id),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// The section's name with its digit key, for the ones that have one.
  String _sectionHint(String title, int index) {
    if (index >= WindowShortcuts.sectionCount) {
      return title;
    }

    return WindowShortcuts.hint(
      title,
      WindowShortcuts.sectionActivator(index, defaultTargetPlatform),
      defaultTargetPlatform,
    );
  }

  /// A right-click on the device: what its Overview offers, without
  /// opening it first.
  List<MenuEntry> _menu(
    BuildContext context,
    ShellScope scope,
    List<FeatureSection> sections,
  ) {
    final l10n = context.shellL10n;
    final nav = context.read<WindowNavViewModel>();
    final deviceId = status.device.id;
    final preferences = context.read<EngineHost>().preferences;
    final isPinned = preferences.isPinned(deviceId);
    final actions = switch (status.isConnected) {
      true => DeviceActionUsage(scope.featureContext.engine.settings).arrange(
        deviceId,
        DeviceActionOrder.of(
          [
            for (final feature in scope.features)
              ...feature.deviceActions(context, scope.featureContext, status),
          ],
          listedSections: {for (final section in sections) section.id},
        ),
      ),
      false => const <FeatureAction>[],
    };

    return [
      for (final action in actions)
        if (action.onPressed case final onPressed?)
          MenuEntry(
            label: action.label,
            icon: action.icon,
            onSelected: onPressed,
          ),
      MenuEntry(
        label: switch (isPinned) {
          true => l10n.devicesUnpin,
          false => l10n.devicesPin,
        },
        icon: switch (isPinned) {
          true => LucideIcons.pinOff,
          false => LucideIcons.pin,
        },
        startsGroup: actions.isNotEmpty,
        onSelected: () =>
            unawaited(preferences.setPinned(deviceId, pinned: !isPinned)),
      ),
      MenuEntry(
        label: l10n.menuFixConnection,
        icon: LucideIcons.wrench,
        onSelected: () => nav.show(DoctorPage(deviceId: deviceId)),
      ),
      MenuEntry(
        label: l10n.menuForgetDevice,
        icon: LucideIcons.trash2,
        onSelected: () => onSelect(DeviceDestination(deviceId)),
      ),
    ];
  }

  /// Whether a feature that is on isn't working with this device.
  bool _needsAttention(ShellScope scope) {
    for (final feature in scope.features) {
      final health = feature.healthFor(scope.featureContext, status);
      final isBroken = switch (health?.state) {
        .needsAttention || .failing => true,
        _ => false,
      };
      if (isBroken) {
        return true;
      }
    }

    return false;
  }
}
