import 'dart:async';
import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:local_shelf/services/services.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// The shelf: a place on this computer to keep files, pictures, text and
/// links for a moment, then drag them out again. It never talks to other
/// devices, so it is never offered to them.
class ShelfFeature extends Feature {
  static const featureId = 'shelf';

  final Completer<ShelfStore> _store = Completer();

  @override
  String get id => featureId;

  @override
  bool get isAvailable => false;

  /// The shelf, once [use] gave it one.
  ShelfStore? get store => _current;
  ShelfStore? _current;

  /// Fires when [store] arrives.
  final StreamController<void> _ready = .broadcast();
  Stream<void> get ready => _ready.stream;

  /// Gives the shelf its store, once its folder is known. Copies that
  /// came before wait for it.
  void use(ShelfStore store) {
    if (_store.isCompleted) {
      return;
    }

    _current = store;
    _store.complete(store);
    _ready.add(null);
  }

  /// Keeps a copy made on the clipboard: files copied in a file manager
  /// by where they are, a picture or text in a file of its own. A copy
  /// [fromDeviceId] came from another device.
  Future<void> keepCopy({
    String? text,
    List<String> files = const [],
    Uint8List? image,
    String? imageMime,
    String? fromDeviceId,
  }) async {
    final store = await _store.future;
    if (files.isNotEmpty && fromDeviceId == null) {
      await store.keepFiles(files, source: .copied);
      return;
    }

    if ((image, imageMime) case (final image?, final mime?)) {
      await store.keepImage(
        image,
        mime: mime,
        source: .copied,
        name: '',
        fromDeviceId: fromDeviceId,
      );
      return;
    }

    if (text case final text? when text.trim().isNotEmpty) {
      await store.keepText(
        text,
        isLink: ShelfNames.isWebAddress(text),
        source: .copied,
        fromDeviceId: fromDeviceId,
      );
    }
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async => null;
}
