import 'dart:async';
import 'dart:io';

import 'package:ferret_menubar/src/messages.g.dart';

/// The menubar icon and popover on macOS. Elsewhere every call does nothing
/// and [isSupported] is false.
class FerretMenubar implements MenubarFlutterApi {
  FerretMenubar({MenubarHostApi? api}) : _api = api ?? MenubarHostApi() {
    if (isSupported) {
      MenubarFlutterApi.setUp(this);
    }
  }

  final MenubarHostApi _api;
  final StreamController<String> _menuSelections = .broadcast();
  final StreamController<bool> _visibility = .broadcast();
  final StreamController<List<String>> _drops = .broadcast();

  bool get isSupported => Platform.isMacOS;

  /// Ids of menu items people pick.
  Stream<String> get menuSelections => _menuSelections.stream;

  /// Whether the popover is showing, each time it changes.
  Stream<bool> get visibility => _visibility.stream;

  /// Paths of files dropped on the menubar icon.
  Stream<List<String>> get drops => _drops.stream;

  Future<void> setIcon(String symbolName, {String? tooltip}) =>
      _call(() => _api.setIcon(symbolName, tooltip));

  Future<void> setPopoverSize(double width, double height) =>
      _call(() => _api.setPopoverSize(width, height));

  Future<void> show() => _call(_api.showPopover);

  Future<void> hide() => _call(_api.hidePopover);

  Future<void> setMenu(List<MenubarMenuItem> items) =>
      _call(() => _api.setMenu(items));

  Future<void> setShowsInDock(bool shows) =>
      _call(() => _api.setShowsInDock(shows));

  Future<void> setDetachable(bool detachable) =>
      _call(() => _api.setDetachable(detachable));

  Future<void> _call(Future<void> Function() call) async {
    if (!isSupported) {
      return;
    }

    await call();
  }

  @override
  void onMenuItemSelected(String id) => _menuSelections.add(id);

  @override
  void onPopoverVisibilityChanged(bool shown) => _visibility.add(shown);

  @override
  void onFilesDropped(List<String> paths) => _drops.add(paths);
}
