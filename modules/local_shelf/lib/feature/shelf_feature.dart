import 'dart:async';
import 'dart:typed_data';

import 'package:engine/engine.dart';
import 'package:local_shelf/models/models.dart';
import 'package:local_shelf/services/services.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// The shelf: a place on this computer to keep files, pictures, text and
/// links for a moment, then drag them out again. It never talks to other
/// devices, so it is never offered to them.
class ShelfFeature extends Feature {
  ShelfFeature({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const featureId = 'shelf';

  /// How often copies kept for a day or a week are checked for age.
  static const expiryCheck = Duration(minutes: 15);

  final Completer<ShelfStore> _store = Completer();
  final DateTime Function() _clock;
  StreamSubscription<String>? _settingsChanges;
  Timer? _expiryTimer;

  @override
  String get id => featureId;

  @override
  bool get isAvailable => false;

  ShelfSettings get settings => ShelfSettings(host.settings);

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

  @override
  Future<void> onStart() async {
    _settingsChanges = settings.changes.listen(_onSettingChanged);
    _expiryTimer = Timer.periodic(expiryCheck, (_) => unawaited(expire()));
  }

  @override
  Future<void> stop() async {
    await _settingsChanges?.cancel();
    _settingsChanges = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    if (settings.copiesFor.keepsFor == null) {
      await _current?.forgetCopies();
    }
  }

  /// Once the shelf is loaded: copies from before that shouldn't be there
  /// anymore go, all of them when they were kept until Ferret quit or the
  /// shelf doesn't keep copies now.
  Future<void> tidyOnLaunch() async {
    final store = await _store.future;
    if (!settings.keepCopies || settings.copiesFor.keepsFor == null) {
      await store.forgetCopies();
      return;
    }

    await expire();
  }

  /// Takes off copies older than the shelf keeps them.
  Future<void> expire() async {
    final keepsFor = settings.copiesFor.keepsFor;
    final store = _current;
    if (keepsFor == null || store == null) {
      return;
    }

    await store.forgetCopies(addedBefore: _clock().subtract(keepsFor));
  }

  void _onSettingChanged(String key) {
    switch (key) {
      case ShelfSettings.keepCopiesKey when !settings.keepCopies:
        unawaited(_current?.forgetCopies());
      case ShelfSettings.copiesForKey:
        unawaited(expire());
    }
  }

  /// Keeps a copy made on the clipboard: files copied in a file manager
  /// by where they are, a picture or text in a file of its own. A copy
  /// [fromDeviceId] came from another device. Nothing, unless the shelf
  /// keeps copies.
  Future<void> keepCopy({
    String? text,
    List<String> files = const [],
    Uint8List? image,
    String? imageMime,
    String? fromDeviceId,
  }) async {
    if (!settings.keepCopies) {
      return;
    }

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
