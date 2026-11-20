import 'dart:async';
import 'dart:ui';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/foundation.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/pages/pages.dart';
import 'package:shell/view_models/view_models.dart';

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
    required AppQuit quit,
  }) : _menubar = menubar,
       _quitter = quit;

  final EngineHost host;
  final PauseController pause;
  final List<FeatureUi> features;
  final FeatureContext featureContext;
  final AppViews views;

  /// Where the view in front is, so Settings is selected in a window and
  /// pushed in the popover.
  final WindowNavRegistry navigation;
  final FerretMenubar _menubar;
  final AppQuit _quitter;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<Listenable> _listened = [];
  late final ShellLocalizations _l10n = lookupShellLocalizations(
    _supportedLocale(),
  );
  late final MenubarIconResolver _resolver = MenubarIconResolver(
    onHoldEnded: _onChanged,
  );
  (MenubarIconState, int, String)? _shown;
  (bool, bool, String?, String?)? _dropsShown;

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
    await _menubar.setClipsShortcut(
      GlobalShortcut.read(
        featureContext.engine.settings,
        key: GlobalShortcut.clipsKey,
        fallback: GlobalShortcut.recentClips,
      ),
    );

    await _updateIconDrops();
    _subscriptions
      ..add(_menubar.menuSelections.listen(_onMenu))
      ..add(
        featureContext.engine.settings.changes
            .where(
              (key) =>
                  MenubarDrops.owns(key) ||
                  key == OsDropViewModel.lastDeviceKey,
            )
            .listen((_) => unawaited(_updateIconDrops())),
      )
      ..add(
        _menubar.clipsShortcutPresses.listen(
          (_) => unawaited(_openRecentClips()),
        ),
      )
      ..add(
        _menubar.visibility
            .where((shown) => !shown)
            .listen((_) => host.settleOrder()),
      );
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

  void _onChanged() {
    unawaited(_updateIcon());
    unawaited(_updateIconDrops());
  }

  /// How the icon takes a drag, and what its label says while one rests
  /// there: where a quick drop would go.
  Future<void> _updateIconDrops() async {
    final settings = featureContext.engine.settings;
    final drops = MenubarDrops(settings);
    final mode = drops.iconDrop;
    final hasShelf = featureContext.dropKeeper != null;
    final target = OsDropViewModel.blindTargetOf([
      for (final status in host.devices)
        DeviceDropTarget(
          deviceId: status.device.id,
          name: status.device.name,
          isConnected: status.isConnected,
        ),
    ], settings.get<String>(OsDropViewModel.lastDeviceKey));
    final l10n = _l10n;
    final files = switch ((mode, hasShelf, target)) {
      (.ask, _, _) => null,
      (.shelf, true, _) => l10n.iconDropShelf,
      (_, _, final target?) => l10n.dropSendTo(target.name),
      _ => l10n.iconDropChoose,
    };
    final text = switch ((mode, hasShelf)) {
      (.ask, _) || (_, false) => null,
      _ => l10n.iconDropShelf,
    };
    final shown = (drops.springLoading, mode == .ask, files, text);
    if (shown == _dropsShown) {
      return;
    }

    _dropsShown = shown;
    await _menubar.setIconDragBehavior(
      springOnHover: drops.springLoading,
      opensAtOnce: mode == .ask,
    );
    await _menubar.setIconDropLabels(files: files, text: text);
  }

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
        await _quitter.quit();
    }
  }

  /// ⌃⌥V from any app: the popover, on Recent clips. The clipboard feature
  /// offers that page as an app action; the shell only finds it by id.
  Future<void> _openRecentClips() async {
    await views.reveal();
    final context = featureContext.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }

    final action = [
      for (final feature in features)
        ...feature.appActions(context, featureContext),
    ].where((action) => action.id == recentClipsAction).firstOrNull;
    action?.onPressed?.call();
  }

  /// The clipboard feature's "Recent clips…" app action.
  static const recentClipsAction = 'clipboard.recent';

  Locale _supportedLocale() =>
      AppLocale.pick(ShellLocalizations.supportedLocales);
}
