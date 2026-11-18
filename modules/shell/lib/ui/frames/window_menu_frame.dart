import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/pages/doctor_page.dart';
import 'package:shell/ui/pages/pair_page.dart';
import 'package:shell/view_models/view_models.dart';

/// The window's keyboard shortcuts and, on a Mac, its menu bar. Both run
/// the same commands as the buttons, so everything a button does has a key
/// and a menu entry.
class WindowMenuFrame extends StatelessWidget {
  const WindowMenuFrame({super.key, required this.child});

  final Widget child;

  /// Features give Send files and Send clipboard these places on a
  /// device's row (`FeatureAction.homeOrder`).
  static const _sendFilesOrder = 10;
  static const _sendClipboardOrder = 20;

  @override
  Widget build(BuildContext context) {
    final nav = context.read<WindowNavViewModel>();
    final selection = context.select<WindowNavViewModel, WindowDestination?>(
      (viewModel) => viewModel.selection,
    );
    final isSidebarHidden = context.select<WindowNavViewModel, bool>(
      (viewModel) => viewModel.isSidebarHidden,
    );
    final device = context.select<EngineHost, DeviceStatus?>(
      (host) => switch (selection) {
        DeviceDestination(:final deviceId) => host.statusOf(deviceId),
        _ => null,
      },
    );
    final scope = ShellScope.of(context);
    final sections = switch (device) {
      final DeviceStatus device => [
        (FeatureSection.overviewId, context.shellL10n.sectionOverview),
        for (final section in DeviceSections.of(
          context,
          scope.features,
          scope.featureContext,
          device,
        ))
          (section.id, section.title),
      ],
      null => const <(String, String)>[],
    };
    final commands = <WindowCommand, VoidCallback?>{
      .addDevice: () => nav.show(const PairPage()),
      .sendFiles: _actionAt(context, scope, device, _sendFilesOrder),
      .sendClipboard: _actionAt(context, scope, device, _sendClipboardOrder),
      .openSettings: () => nav.select(const SettingsDestination()),
      .openActivity: () => nav.select(const ActivityDestination()),
      .toggleSidebar: nav.toggleSidebar,
      .nextDevice: () => nav.selectDeviceBy(1),
      .previousDevice: () => nav.selectDeviceBy(-1),
      .back: () => unawaited(nav.navigatorKey.currentState?.maybePop()),
      .fixConnection: switch (device) {
        final DeviceStatus device => () => nav.show(
          DoctorPage(deviceId: device.device.id),
        ),
        null => null,
      },
    };
    void selectSection(int index) {
      if (device == null || index >= sections.length) {
        return;
      }

      nav.select(
        DeviceDestination(device.device.id, sectionId: sections[index].$1),
      );
    }

    final keyed = Shortcuts(
      shortcuts: WindowShortcuts.of(defaultTargetPlatform),
      child: Actions(
        actions: {
          WindowCommandIntent: CallbackAction<WindowCommandIntent>(
            onInvoke: (intent) => commands[intent.command]?.call(),
          ),
          SelectSectionIntent: CallbackAction<SelectSectionIntent>(
            onInvoke: (intent) => selectSection(intent.index),
          ),
        },
        child: Focus(autofocus: true, skipTraversal: true, child: child),
      ),
    );
    if (defaultTargetPlatform != .macOS) {
      return keyed;
    }

    return PlatformMenuBar(
      menus: _menus(
        context,
        commands: commands,
        sections: sections,
        onSection: selectSection,
        isSidebarHidden: isSidebarHidden,
      ),
      child: keyed,
    );
  }

  /// The device's action features placed at [order], while it is connected.
  VoidCallback? _actionAt(
    BuildContext context,
    ShellScope scope,
    DeviceStatus? device,
    int order,
  ) {
    if (device == null || !device.isConnected) {
      return null;
    }

    for (final feature in scope.features) {
      final actions = feature.deviceActions(
        context,
        scope.featureContext,
        device,
      );
      for (final action in actions) {
        if (action.homeOrder == order) {
          return action.onPressed;
        }
      }
    }

    return null;
  }

  /// Apple's order: the app, File, View, the app's own menu, Window. An
  /// entry that can't apply right now is greyed, not removed.
  List<PlatformMenuItem> _menus(
    BuildContext context, {
    required Map<WindowCommand, VoidCallback?> commands,
    required List<(String, String)> sections,
    required void Function(int index) onSection,
    required bool isSidebarHidden,
  }) {
    final l10n = context.shellL10n;
    final views = context.read<AppViews?>();
    PlatformMenuItem item(String label, WindowCommand command) =>
        PlatformMenuItem(
          label: label,
          shortcut: WindowShortcuts.activatorOf(command, .macOS),
          onSelected: commands[command],
        );

    return [
      PlatformMenu(
        label: l10n.appName,
        menus: [
          const PlatformMenuItemGroup(
            members: [PlatformProvidedMenuItem(type: .about)],
          ),
          PlatformMenuItemGroup(
            members: [item(l10n.menuSettings, .openSettings)],
          ),
          const PlatformMenuItemGroup(
            members: [
              PlatformProvidedMenuItem(type: .hide),
              PlatformProvidedMenuItem(type: .hideOtherApplications),
              PlatformProvidedMenuItem(type: .showAllApplications),
            ],
          ),
          const PlatformMenuItemGroup(
            members: [PlatformProvidedMenuItem(type: .quit)],
          ),
        ],
      ),
      PlatformMenu(
        label: l10n.menuFile,
        menus: [
          PlatformMenuItemGroup(members: [item(l10n.menuPair, .addDevice)]),
          PlatformMenuItemGroup(
            members: [
              item(l10n.menuSendFiles, .sendFiles),
              item(l10n.menuSendClipboard, .sendClipboard),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: l10n.menuCloseWindow,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyW,
                  meta: true,
                ),
                onSelected: switch (views) {
                  final AppViews views => () => unawaited(views.closeWindow()),
                  null => null,
                },
              ),
            ],
          ),
        ],
      ),
      PlatformMenu(
        label: l10n.menuView,
        menus: [
          PlatformMenuItemGroup(
            members: [
              item(switch (isSidebarHidden) {
                true => l10n.menuShowSidebar,
                false => l10n.menuHideSidebar,
              }, .toggleSidebar),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              for (final (index, (_, title)) in sections.indexed.take(
                WindowShortcuts.sectionCount,
              ))
                PlatformMenuItem(
                  label: title,
                  shortcut: WindowShortcuts.sectionActivator(index, .macOS),
                  onSelected: () => onSection(index),
                ),
              item(l10n.activityTitle, .openActivity),
            ],
          ),
          PlatformMenuItemGroup(members: [item(l10n.menuBack, .back)]),
          const PlatformMenuItemGroup(
            members: [PlatformProvidedMenuItem(type: .toggleFullScreen)],
          ),
        ],
      ),
      PlatformMenu(
        label: l10n.menuDevice,
        menus: [
          PlatformMenuItemGroup(
            members: [
              item(l10n.menuNextDevice, .nextDevice),
              item(l10n.menuPreviousDevice, .previousDevice),
            ],
          ),
          PlatformMenuItemGroup(
            members: [item(l10n.menuFixConnection, .fixConnection)],
          ),
        ],
      ),
      PlatformMenu(
        label: l10n.menuWindow,
        menus: const [
          PlatformMenuItemGroup(
            members: [
              PlatformProvidedMenuItem(type: .minimizeWindow),
              PlatformProvidedMenuItem(type: .zoomWindow),
            ],
          ),
          PlatformMenuItemGroup(
            members: [PlatformProvidedMenuItem(type: .arrangeWindowsInFront)],
          ),
        ],
      ),
    ];
  }
}
