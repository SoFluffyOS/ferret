import 'dart:async';
import 'dart:ui';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/services.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/pages/pages.dart';

/// Connects the macOS menubar icon to the app: its menu, its icon state and
/// files dropped on it.
class MenubarBinding {
  MenubarBinding({
    required this.host,
    required this.features,
    required this.featureContext,
  });

  final EngineHost host;
  final List<FeatureUi> features;
  final FeatureContext featureContext;
  final FerretMenubar _menubar = FerretMenubar();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  static const _open = 'open';
  static const _pair = 'pair';
  static const _settings = 'settings';
  static const _quit = 'quit';

  Future<void> start() async {
    if (!_menubar.isSupported) {
      return;
    }

    final l10n = lookupShellLocalizations(_supportedLocale());
    await _menubar.setMenu([
      MenubarMenuItem(id: _open, title: l10n.menuOpen),
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

    _subscriptions
      ..add(_menubar.menuSelections.listen(_onMenu))
      ..add(_menubar.drops.listen(_onDrop));
    host.addListener(_onHostChanged);
  }

  Future<void> dispose() async {
    host.removeListener(_onHostChanged);
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }

  void _onHostChanged() => unawaited(_updateIcon());

  Future<void> _updateIcon() async {
    final symbol = switch (host.connectedCount) {
      0 => 'arrow.left.arrow.right',
      _ => 'arrow.left.arrow.right.circle.fill',
    };
    await _menubar.setIcon(symbol, tooltip: 'Ferret');
  }

  Future<void> _onMenu(String id) async {
    switch (id) {
      case _open:
        await _menubar.show();
      case _pair:
        await _menubar.show();
        await featureContext.push<void>(const PairPage());
      case _settings:
        await _menubar.show();
        await featureContext.push<void>(const SettingsPage());
      case _quit:
        await SystemNavigator.pop();
    }
  }

  Future<void> _onDrop(List<String> paths) async {
    for (final feature in features) {
      if (await feature.onFilesDropped(featureContext, paths)) {
        return;
      }
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
