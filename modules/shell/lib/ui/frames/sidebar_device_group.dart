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
import 'package:shell/ui/pages/pages.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One device and, while it is the open one, its sections under it.
class SidebarDeviceGroup extends StatelessWidget {
  const SidebarDeviceGroup({
    super.key,
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
        label: WindowCommands.inCase(l10n, l10n.menuFixConnection),
        icon: LucideIcons.wrench,
        onSelected: () => nav.show(DoctorPage(deviceId: deviceId)),
      ),
      MenuEntry(
        label: WindowCommands.inCase(l10n, l10n.menuForgetDevice),
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
