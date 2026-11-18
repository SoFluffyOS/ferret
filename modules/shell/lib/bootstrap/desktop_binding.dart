import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';

/// Windows and Linux: the tray icon with its menu, and what closing the
/// window does. With a tray, closing hides Ferret there and says so once;
/// without one (GNOME without the AppIndicator extension), closing quits,
/// since a hidden window there could never be found again.
class DesktopBinding {
  DesktopBinding({
    required this.host,
    required this.pause,
    required this.settings,
    required this.notifier,
    DesktopTray? tray,
    DesktopWindow? window,
    FerretSystem? system,
    bool? isDesktop,
    Locale? locale,
  }) : _tray = tray ?? DesktopTray.current(),
       _window = window ?? DesktopWindow(),
       _system = system ?? FerretSystem(),
       _isDesktop = isDesktop ?? (Platform.isWindows || Platform.isLinux),
       _l10n = lookupShellLocalizations(_supported(locale));

  /// Settings key: the "still running in the tray" notice was shown.
  static const toldAboutTrayKey = 'desktop.told_about_tray';

  static const noticeId = 'shell.tray';
  static const openId = 'open';
  static const pauseId = 'pause';
  static const clipboardId = 'clipboard';
  static const quitId = 'quit';

  final EngineHost host;
  final PauseController pause;
  final SettingsStore settings;
  final LocalNotifier notifier;
  final DesktopTray _tray;
  final DesktopWindow _window;
  final FerretSystem _system;
  final bool _isDesktop;
  final ShellLocalizations _l10n;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  bool _hasTray = false;
  (String, List<TrayMenuItem>)? _shown;

  /// Whether a tray icon is showing, so closing the window hides Ferret.
  bool get hasTray => _hasTray;

  Future<void> start() async {
    if (!_isDesktop) {
      return;
    }

    final (tooltip, items) = _menu();
    _hasTray = await _tray.show(tooltip: tooltip, items: items);
    _shown = (tooltip, items);
    await _window.setHideOnClose(_hasTray);
    if (!_hasTray && await _window.startedHidden()) {
      await _window.show();
    }

    _subscriptions
      ..add(_tray.activations.listen((_) => unawaited(_window.toggle())))
      ..add(_tray.selections.listen((id) => unawaited(_onMenu(id))))
      ..add(_window.closedToTray.listen((_) => unawaited(_tellOnce())));
    host.addListener(_refresh);
    pause.addListener(_refresh);
  }

  Future<void> dispose() async {
    host.removeListener(_refresh);
    pause.removeListener(_refresh);
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _tray.dispose();
  }

  void _refresh() => unawaited(_update());

  Future<void> _update() async {
    if (!_hasTray) {
      return;
    }

    final menu = _menu();
    if (_shown case (final tooltip, final items)
        when tooltip == menu.$1 && _same(items, menu.$2)) {
      return;
    }

    _shown = menu;
    await _tray.show(tooltip: menu.$1, items: menu.$2);
  }

  (String, List<TrayMenuItem>) _menu() {
    final connected = [
      for (final status in host.devices)
        if (status.isConnected) status.device.name,
    ];
    final inputs = MenubarIconInputs.gather(
      connectedNames: connected,
      isPaused: pause.isPaused,
      pairingName: null,
      busy: const [],
    );
    final state = switch ((pause.isPaused, connected.isEmpty)) {
      (true, _) => MenubarIconState.paused,
      (false, true) => MenubarIconState.alone,
      (false, false) => MenubarIconState.normal,
    };

    return (
      MenubarTooltips(_l10n).of(state, inputs),
      [
        TrayMenuItem(id: openId, title: _l10n.menuOpen),
        const TrayMenuItem.separator(),
        TrayMenuItem(
          id: clipboardId,
          title: _l10n.traySendClipboard,
          enabled: connected.isNotEmpty && !pause.isPaused,
        ),
        TrayMenuItem(
          id: pauseId,
          title: switch (pause.isPaused) {
            true => _l10n.resume,
            false => _l10n.pauseOneHour,
          },
        ),
        const TrayMenuItem.separator(),
        TrayMenuItem(id: quitId, title: _l10n.menuQuit),
      ],
    );
  }

  Future<void> _onMenu(String id) async {
    switch (id) {
      case openId:
        await _window.show();
      case clipboardId:
        _system.emitAction(const SystemAction(SystemAction.clipboardSend));
      case pauseId when pause.isPaused:
        await pause.resume();
      case pauseId:
        await pause.pause(duration: const Duration(hours: 1));
      case quitId:
        await _window.quit();
    }
  }

  /// The first close only: after that, people know where Ferret went.
  Future<void> _tellOnce() async {
    if (settings.get<bool>(toldAboutTrayKey) ?? false) {
      return;
    }

    await settings.set(toldAboutTrayKey, true);
    await notifier.show(
      LocalNotice(
        id: noticeId,
        channel: .suggestions,
        title: _l10n.trayStillRunningTitle,
        body: _l10n.trayStillRunningBody,
      ),
    );
  }

  static bool _same(List<TrayMenuItem> left, List<TrayMenuItem> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }

  static Locale _supported(Locale? wanted) {
    final language =
        (wanted ?? PlatformDispatcher.instance.locale).languageCode;
    for (final locale in ShellLocalizations.supportedLocales) {
      if (locale.languageCode == language) {
        return locale;
      }
    }

    return ShellLocalizations.supportedLocales.first;
  }
}
