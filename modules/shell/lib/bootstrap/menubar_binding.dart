import 'dart:async';
import 'dart:ui';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/pages/pages.dart';

/// Connects the macOS menubar icon to the app: its menu and its icon state.
/// Files dragged onto it are the app's `FileDropZone`'s. Start [views]
/// first, so the menu knows whether there is a desktop window to offer.
class MenubarBinding {
  MenubarBinding({
    required this.host,
    required this.pause,
    required this.features,
    required this.featureContext,
    required this.views,
    required this.navigation,
    required FerretMenubar menubar,
  }) : _menubar = menubar;

  final EngineHost host;
  final PauseController pause;
  final List<FeatureUi> features;
  final FeatureContext featureContext;
  final AppViews views;

  /// Where the view in front is, so Settings is selected in a window and
  /// pushed in the popover.
  final WindowNavRegistry navigation;
  final FerretMenubar _menubar;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<Listenable> _listened = [];
  late final ShellLocalizations _l10n = lookupShellLocalizations(
    _supportedLocale(),
  );
  late final MenubarIconResolver _resolver = MenubarIconResolver(
    onHoldEnded: _onChanged,
  );
  (MenubarIconState, int, String)? _shown;

  /// Settings key that says the first launch already happened.
  static const firstLaunchDoneKey = 'onboarding.done';

  static const _open = 'open';
  static const _window = 'window';
  static const _pair = 'pair';
  static const _settings = 'settings';
  static const _quit = 'quit';

  Future<void> start() async {
    if (!_menubar.isSupported) {
      return;
    }

    final l10n = _l10n;
    await _menubar.setMenu([
      MenubarMenuItem(id: _open, title: l10n.menuOpen),
      if (views.canOpenWindow)
        MenubarMenuItem(id: _window, title: l10n.menuOpenWindow),
      MenubarMenuItem(id: _pair, title: l10n.menuPair),
      MenubarMenuItem(
        id: _settings,
        title: l10n.menuSettings,
        keyEquivalent: ',',
      ),
      MenubarMenuItem(id: '', title: '', separator: true),
      MenubarMenuItem(id: _quit, title: l10n.menuQuit, keyEquivalent: 'q'),
    ]);
    await _updateIcon();
    await _menubar.setGlobalShortcut(
      GlobalShortcut.read(featureContext.engine.settings),
    );

    _subscriptions.add(_menubar.menuSelections.listen(_onMenu));
    _listened
      ..add(host)
      ..add(pause)
      ..addAll([for (final feature in features) ?feature.uiChanges]);
    for (final listenable in _listened) {
      listenable.addListener(_onChanged);
    }

    await _showOnFirstLaunch();
  }

  /// The first launch opens the popover by itself, once, so nobody has to
  /// be told where Ferret lives.
  Future<void> _showOnFirstLaunch() async {
    final settings = featureContext.engine.settings;
    if (settings.get<bool>(firstLaunchDoneKey) ?? false) {
      return;
    }

    await settings.set(firstLaunchDoneKey, true);
    await _menubar.show();
  }

  /// The menubar, for the app's drop targets; null where there is none.
  FerretMenubar? get menubar => switch (_menubar.isSupported) {
    true => _menubar,
    false => null,
  };

  Future<void> dispose() async {
    for (final listenable in _listened) {
      listenable.removeListener(_onChanged);
    }
    _listened.clear();
    _resolver.dispose();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }

  void _onChanged() => unawaited(_updateIcon());

  /// Features fire for many reasons and transfers report often, so the Mac
  /// hears only when what the icon shows really changed, a whole percent
  /// at a time.
  Future<void> _updateIcon() async {
    final inputs = _readInputs();
    final state = _resolver.resolve(inputs);
    final progress = inputs.progress ?? 0;
    final tooltip = MenubarTooltips(_l10n).of(state, inputs);
    final shown = (state, (progress * 100).round(), tooltip);
    if (shown == _shown) {
      return;
    }

    _shown = shown;
    await _menubar.setIconState(state, progress: progress, tooltip: tooltip);
  }

  MenubarIconInputs _readInputs() => .gather(
    connectedNames: [
      for (final status in host.devices)
        if (status.isConnected) status.device.name,
    ],
    isPaused: pause.isPaused,
    pairingName: host.pendingPrompt?.device.name,
    busy: [
      for (final feature in features) ?feature.busyState(featureContext),
    ],
  );

  Future<void> _onMenu(String id) async {
    switch (id) {
      case _open:
        await _menubar.show();
      case _window:
        await views.openWindow();
      case _pair:
        await views.reveal();
        await featureContext.push<void>(const PairPage());
      case _settings:
        if (!views.canOpenWindow) {
          await views.reveal();
        }
        navigation.open(const SettingsDestination());
      case _quit:
        await SystemNavigator.pop();
    }
  }

  Locale _supportedLocale() {
    final wanted = PlatformDispatcher.instance.locale;
    for (final locale in ShellLocalizations.supportedLocales) {
      if (locale.languageCode == wanted.languageCode) {
        return locale;
      }
    }

    return ShellLocalizations.supportedLocales.first;
  }
}
