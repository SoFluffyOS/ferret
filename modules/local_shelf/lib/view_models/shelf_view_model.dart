import 'dart:async';
import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_shelf/models/models.dart';
import 'package:local_shelf/services/services.dart';

/// The shelf on screen: what is on it, what is selected, whether a drag
/// is over it, and whether its contents may show here. It takes what is
/// dropped on its bar or page.
class ShelfViewModel extends ChangeNotifier implements DropReceiver {
  ShelfViewModel({
    required this.localDeviceId,
    this.showsPreviewsFrom = _always,
    this.nameOf = _sameName,
    this.dragOut,
    this.quickLook,
    this.settings,
    this.reveal = _revealInFinder,
    this.copyText = _copyToClipboard,
  });

  /// This computer's device id: its own copies show as long as previews
  /// show from it.
  final String localDeviceId;

  /// Whether private things from a device may show on this screen now.
  final bool Function(String deviceId) showsPreviewsFrom;

  /// A device's name as this computer calls it.
  final String Function(String deviceId) nameOf;

  DragOut? dragOut;
  Future<void> Function(List<String> paths)? quickLook;

  /// Whether and how long copies are kept; none in tests that don't ask.
  final ShelfSettings? settings;

  /// Shows a file in Finder, selected.
  final Future<void> Function(String path) reveal;

  /// Puts text on the clipboard.
  final Future<void> Function(String text) copyText;

  ShelfStore? _store;
  StreamSubscription<void>? _changes;
  List<ShelfItem> _items = const [];
  Set<String> _selected = const {};
  bool _isDropOver = false;
  int _openLists = 0;

  static bool _always(String _) => true;
  static String _sameName(String deviceId) => deviceId;

  static Future<void> _revealInFinder(String path) async {
    if (!Platform.isMacOS) {
      return;
    }

    await Process.run('open', ['-R', path]);
  }

  static Future<void> _copyToClipboard(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  List<ShelfItem> get items => _items;

  Set<String> get selected => _selected;

  /// Whether the shelf's list page is open: the box steps aside for it.
  bool get isListOpen => _openLists > 0;

  void listOpened() {
    _openLists++;
    notifyListeners();
  }

  void listClosed() {
    _openLists = (_openLists - 1).clamp(0, _openLists);
    notifyListeners();
  }

  /// Whether a drag is over the shelf and would land on it.
  bool get isDropOver => _isDropOver;

  /// Whether the whole shelf hides what it holds, as while this screen is
  /// locked or other people use this computer.
  bool get isHidden => !showsPreviewsFrom(localDeviceId);

  /// Whether [item] hides what it is: the whole shelf does, or it came
  /// from a device whose previews are off here.
  bool hides(ShelfItem item) =>
      isHidden || !showsPreviewsFrom(item.fromDeviceId ?? localDeviceId);

  /// Whether what is copied goes on the shelf too.
  bool get keepsCopies => settings?.keepCopies ?? false;

  ShelfCopiesFor get copiesFor => settings?.copiesFor ?? .untilQuit;

  Future<void> setKeepCopies(bool value) async {
    await settings?.setKeepCopies(value);
    notifyListeners();
  }

  Future<void> setCopiesFor(ShelfCopiesFor value) async {
    await settings?.setCopiesFor(value);
    notifyListeners();
  }

  /// Shows [store]'s items from now on.
  void attach(ShelfStore store) {
    if (identical(_store, store)) {
      return;
    }

    unawaited(_changes?.cancel());
    _store = store;
    _changes = store.changes.listen((_) => _sync());
    _sync();
  }

  /// Checks again that every file is still there, such as when the
  /// popover opens.
  Future<void> refresh() async => _store?.refresh();

  /// Something changed that may hide or show contents, such as the
  /// previews setting.
  void previewsChanged() => notifyListeners();

  @override
  void hover({required bool over}) {
    if (_isDropOver == over) {
      return;
    }

    _isDropOver = over;
    notifyListeners();
  }

  @override
  Future<bool> takeFiles(List<String> paths) async {
    hover(over: false);
    final store = _store;
    if (store == null || paths.isEmpty) {
      return false;
    }

    await store.keepFiles(paths, source: .dropped);
    return true;
  }

  @override
  Future<bool> takeText(String text, {required bool isLink}) async {
    hover(over: false);
    final store = _store;
    if (store == null) {
      return false;
    }

    final item = await store.keepText(
      text,
      isLink: isLink || ShelfNames.isWebAddress(text),
      source: .dropped,
    );
    return item != null;
  }

  /// Selects [id]: alone, or added to the selection with [toggle] (⌘),
  /// or everything from the last pick to it with [extend] (⇧).
  void select(String id, {bool toggle = false, bool extend = false}) {
    if (extend && _selected.isNotEmpty) {
      final ids = [for (final item in _items) item.id];
      final anchor = ids.indexOf(_selected.last);
      final target = ids.indexOf(id);
      if (anchor >= 0 && target >= 0) {
        final (from, to) = switch (anchor <= target) {
          true => (anchor, target),
          false => (target, anchor),
        };
        _selected = {..._selected, ...ids.sublist(from, to + 1)};
        notifyListeners();
        return;
      }
    }

    if (toggle) {
      _selected = switch (_selected.contains(id)) {
        true => {..._selected}..remove(id),
        false => {..._selected, id},
      };
      notifyListeners();
      return;
    }

    _selected = {id};
    notifyListeners();
  }

  void selectAll() {
    _selected = {for (final item in _items) item.id};
    notifyListeners();
  }

  void clearSelection() {
    if (_selected.isEmpty) {
      return;
    }

    _selected = const {};
    notifyListeners();
  }

  Future<void> remove(Iterable<String> ids) async =>
      _store?.remove(ids.toList());

  Future<void> removeSelected() => remove(_selected);

  Future<void> clear() async => _store?.clear();

  /// What a drag that starts on [item] takes: the selection when [item]
  /// is in it, otherwise [item] alone.
  List<ShelfItem> dragged(ShelfItem item) {
    if (!_selected.contains(item.id)) {
      return [item];
    }

    return [
      for (final selected in _items)
        if (_selected.contains(selected.id)) selected,
    ];
  }

  /// Starts dragging [items] out of the view [viewId]: one text or link
  /// goes as text, anything else as files. Hidden or missing items stay.
  Future<bool> drag(int viewId, List<ShelfItem> items) async {
    final dragOut = this.dragOut;
    final shown = [
      for (final item in items)
        if (!item.isMissing && !hides(item)) item,
    ];
    if (dragOut == null || shown.isEmpty) {
      return false;
    }

    if (shown case [final only] when only.kind == .link) {
      return dragOut.text(viewId, only.text, isLink: true);
    }

    if (shown case [final only] when only.kind == .text) {
      final text = await _readText(only);
      if (text != null) {
        return dragOut.text(viewId, text);
      }
    }

    return dragOut.files(viewId, [for (final item in shown) item.path]);
  }

  /// Shows the selected files in a quick preview, or closes it.
  Future<void> previewSelected() => preview([
    for (final item in _items)
      if (_selected.contains(item.id)) item,
  ]);

  /// Shows [items] in a quick preview, or closes it. Hidden or missing
  /// items stay out.
  Future<void> preview(List<ShelfItem> items) async {
    final quickLook = this.quickLook;
    final paths = [
      for (final item in items)
        if (canPreview(item)) item.path,
    ];
    if (quickLook == null || paths.isEmpty) {
      return;
    }

    await quickLook(paths);
  }

  bool canPreview(ShelfItem item) => !item.isMissing && !hides(item);

  /// Whether [item] is a file of the person's own that Finder can show.
  bool canReveal(ShelfItem item) =>
      !item.isCached && !item.isMissing && !hides(item);

  /// Whether [item] is text or a link to put on the clipboard.
  bool canCopy(ShelfItem item) =>
      (item.kind == .text || item.kind == .link) && !hides(item);

  Future<void> showInFinder(ShelfItem item) async {
    if (!canReveal(item)) {
      return;
    }

    await reveal(item.path);
  }

  /// Puts [item]'s text or web address on the clipboard.
  Future<bool> copy(ShelfItem item) async {
    if (!canCopy(item)) {
      return false;
    }

    final text = switch (item.kind) {
      .link => item.text,
      _ => await _readText(item),
    };
    if (text == null || text.isEmpty) {
      return false;
    }

    await copyText(text);
    return true;
  }

  Future<String?> _readText(ShelfItem item) async {
    try {
      return await File(item.path).readAsString();
    } on Object {
      return null;
    }
  }

  void _sync() {
    final store = _store;
    if (store == null) {
      return;
    }

    _items = store.items;
    final ids = {for (final item in _items) item.id};
    _selected = _selected.where(ids.contains).toSet();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    super.dispose();
  }
}
