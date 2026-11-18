import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/frames/sidebar_nearby_frame.dart';
import 'package:shell/ui/pages/doctor_page.dart';
import 'package:shell/ui/pages/pair_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A window's device list: your devices, the selected one opened to its
/// sections, who is nearby, then Activity and Settings. What is selected
/// here is what the pane next to it shows.
class SidebarFrame extends StatelessWidget {
  const SidebarFrame({super.key});

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

    return ColoredBox(
      color: context.palette.surface,
      child: SafeArea(
        right: false,
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              _Header(
                onHide: nav.toggleSidebar,
                onAdd: () => nav.show(const PairPage()),
              ),
              if (isPaused) const _PausedLine(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(bottom: Spacing.d16),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: Spacing.d12),
                      child: SectionTitle(l10n.homeYourDevices),
                    ),
                    for (final status in devices)
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
                      isSelected: selection is ActivityDestination,
                      onTap: () => nav.select(const ActivityDestination()),
                    ),
                    SidebarRow(
                      label: l10n.settingsTitle,
                      icon: LucideIcons.settings,
                      isSelected: selection is SettingsDestination,
                      onTap: () => nav.select(const SettingsDestination()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onHide, required this.onAdd});

  final VoidCallback onHide;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;
    final color = context.palette.text;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.d8,
        Spacing.d8,
        Spacing.d8,
        Spacing.d0,
      ),
      child: Row(
        mainAxisAlignment: .end,
        children: [
          Tappable(
            tooltip: l10n.sidebarHide,
            onTap: onHide,
            child: Padding(
              padding: EdgeInsets.all(Spacing.d6),
              child: Icon(
                LucideIcons.panelLeftClose,
                size: Spacing.d18,
                color: color,
              ),
            ),
          ),
          Tappable(
            tooltip: l10n.homePairDevice,
            onTap: onAdd,
            child: Padding(
              padding: EdgeInsets.all(Spacing.d6),
              child: Icon(LucideIcons.plus, size: Spacing.d18, color: color),
            ),
          ),
        ],
      ),
    );
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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.d16,
        vertical: Spacing.d4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.homeStatusPaused,
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
          ),
          Tappable(
            onTap: () => unawaited(context.read<PauseController>().resume()),
            child: Text(
              l10n.resume,
              style: typography.base2.copyWith(color: palette.link),
            ),
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

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        ContextMenuRegion(
          entries: _menu(context, scope, sections),
          child: SidebarDeviceRow(
            status: status,
            isSelected: isOpen && sections.isEmpty,
            needsAttention: _needsAttention(scope),
            badge: switch (isOpen) {
              true => 0,
              false => waiting,
            },
            onTap: () => onSelect(DeviceDestination(deviceId)),
          ),
        ),
        if (isOpen && sections.isNotEmpty) ...[
          SidebarRow(
            label: context.shellL10n.sectionOverview,
            icon: LucideIcons.layoutDashboard,
            isIndented: true,
            isSelected: !showsFeatureSection,
            onTap: () => onSelect(DeviceDestination(deviceId)),
          ),
          for (final section in sections)
            SidebarRow(
              key: ValueKey(section.id),
              label: section.title,
              icon: section.icon,
              isIndented: true,
              isDimmed: !section.isSetUp,
              isSelected: section.id == openSectionId,
              trailing: switch (section.badge) {
                final badge? when badge > 0 => SidebarBadge(badge),
                _ => null,
              },
              onTap: () =>
                  onSelect(DeviceDestination(deviceId, sectionId: section.id)),
            ),
        ],
      ],
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
    final actions = switch (status.isConnected) {
      true => DeviceActionOrder.of(
        [
          for (final feature in scope.features)
            ...feature.deviceActions(context, scope.featureContext, status),
        ],
        listedSections: {for (final section in sections) section.id},
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
        label: l10n.menuFixConnection,
        icon: LucideIcons.wrench,
        startsGroup: actions.isNotEmpty,
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
