import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:ferret_menubar/src/messages.g.dart';
import 'package:ferret_menubar/src/popover_drag.dart';

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
  final StreamController<PopoverDrag> _drags = .broadcast();

  bool get isSupported => Platform.isMacOS;

  /// Ids of menu items people pick.
  Stream<String> get menuSelections => _menuSelections.stream;

  /// Whether the popover is showing, each time it changes.
  Stream<bool> get visibility => _visibility.stream;

  /// Paths of files dropped on the menubar icon.
  Stream<List<String>> get drops => _drops.stream;

  /// Files dragged over and dropped on the popover, docked or detached.
  Stream<PopoverDrag> get drags => _drags.stream;

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

  Future<void> setDropAllowed(bool allowed) =>
      _call(() => _api.setDropAllowed(allowed));

  /// Closes the popover if a file drag over the icon sprang it open.
  Future<void> closeIfOpenedByDrag() => _call(_api.closeIfOpenedByDrag);

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

  @override
  void onDragEntered(double x, double y, int fileCount) =>
      _drags.add(PopoverDragEntered(Offset(x, y), fileCount));

  @override
  void onDragUpdated(double x, double y) =>
      _drags.add(PopoverDragMoved(Offset(x, y)));

  @override
  void onDragExited() => _drags.add(const PopoverDragExited());

  @override
  void onDragPerformed(List<String> paths, double x, double y) =>
      _drags.add(PopoverDragDropped(paths, Offset(x, y)));
}
