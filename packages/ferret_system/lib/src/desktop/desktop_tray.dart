import 'dart:io';

import 'package:ferret_system/src/desktop/desktop_window.dart';
import 'package:ferret_system/src/desktop/linux/linux.dart';
import 'package:ferret_system/src/desktop/tray_menu_item.dart';

/// The icon next to the clock on Windows and Linux, with its menu.
abstract interface class DesktopTray {
  /// Windows: the runner's notification-area icon. Linux: a
  /// StatusNotifierItem, which KDE Plasma, Xfce, Cinnamon and most panels
  /// show, and GNOME only with the AppIndicator extension. Elsewhere none.
  factory DesktopTray.current() {
    if (Platform.isWindows) {
      return ChannelTray(DesktopWindow());
    }

    if (Platform.isLinux) {
      return LinuxTray();
    }

    return const NoTray();
  }

  /// Shows the icon, or updates it. False when this desktop has nowhere to
  /// show one, so closing the window should not hide Ferret.
  Future<bool> show({
    required String tooltip,
    required List<TrayMenuItem> items,
  });

  /// The icon itself was clicked.
  Stream<void> get activations;

  /// A menu line was picked, by its id.
  Stream<String> get selections;

  Future<void> dispose();
}

/// The Windows runner's icon, through [DesktopWindow]'s channel.
class ChannelTray implements DesktopTray {
  const ChannelTray(this._window);

  final DesktopWindow _window;

  @override
  Future<bool> show({
    required String tooltip,
    required List<TrayMenuItem> items,
  }) => _window.setTray(tooltip, items);

  @override
  Stream<void> get activations => _window.trayActivations;

  @override
  Stream<String> get selections => _window.traySelections;

  @override
  Future<void> dispose() => _window.removeTray();
}

/// No tray here.
class NoTray implements DesktopTray {
  const NoTray();

  @override
  Future<bool> show({
    required String tooltip,
    required List<TrayMenuItem> items,
  }) async => false;

  @override
  Stream<void> get activations => const Stream.empty();

  @override
  Stream<String> get selections => const Stream.empty();

  @override
  Future<void> dispose() async {}
}
