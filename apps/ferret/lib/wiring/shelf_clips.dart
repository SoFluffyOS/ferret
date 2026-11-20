import 'dart:async';
import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:engine/engine.dart';
import 'package:local_shelf/local_shelf.dart';

/// Puts each copy the clipboard takes on the shelf, through the
/// clipboard's own watcher, while the shelf keeps copies. Clipboard and
/// the shelf never import each other, so the app joins them here. Only on
/// a Mac for now, where the shelf has its bar.
///
/// The clipboard watches this computer's clipboard only while someone
/// listens or copies go out on their own, so with Keep copies off and
/// Send automatically off nothing watches it.
class ShelfClips {
  ShelfClips._(this._shelf, this._copies) {
    _update();
    _settings = _shelf.settings.changes
        .where((key) => key == ShelfSettings.keepCopiesKey)
        .listen((_) => _update());
  }

  /// Joins them on a Mac, or null elsewhere.
  static ShelfClips? attach(FerretEngine engine) {
    if (!Platform.isMacOS) {
      return null;
    }

    final shelf = engine.feature<ShelfFeature>();
    final clipboard = engine.feature<ClipboardFeature>();
    if (shelf == null || clipboard == null) {
      return null;
    }

    return follow(shelf, clipboard.copies);
  }

  /// Listens to [copies] while [shelf] keeps them, and stops when it
  /// doesn't.
  static ShelfClips follow(ShelfFeature shelf, Stream<ClipCopy> copies) =>
      ShelfClips._(shelf, copies);

  final ShelfFeature _shelf;
  final Stream<ClipCopy> _copies;
  late final StreamSubscription<String> _settings;
  StreamSubscription<ClipCopy>? _listening;

  /// Whether copies are being listened to now.
  bool get isListening => _listening != null;

  Future<void> cancel() async {
    await _settings.cancel();
    await _listening?.cancel();
    _listening = null;
  }

  void _update() {
    switch ((_shelf.settings.keepCopies, _listening)) {
      case (true, null):
        _listening = _copies.listen((copy) => unawaited(keep(_shelf, copy)));
      case (false, final listening?):
        _listening = null;
        unawaited(listening.cancel());
      default:
        break;
    }
  }

  static Future<void> keep(ShelfFeature shelf, ClipCopy copy) {
    final content = copy.content;

    return shelf.keepCopy(
      text: content.text,
      files: content.files,
      image: content.image,
      imageMime: content.imageMime,
      fromDeviceId: copy.fromDeviceId,
    );
  }
}
