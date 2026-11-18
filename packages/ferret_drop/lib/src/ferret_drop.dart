import 'dart:async';

import 'package:ferret_drop/src/messages.g.dart';
import 'package:flutter/services.dart';

/// Talks to the drop plugin on each platform. Every call fails soft: when a
/// platform can't do something, it returns false or an empty result.
class FerretDrop implements FerretDropFlutterApi {
  FerretDrop({FerretDropHostApi? api}) : _api = api ?? FerretDropHostApi();

  final FerretDropHostApi _api;
  final StreamController<SharedItems> _shares = .broadcast();
  bool _listening = false;

  /// Files and text shared with "Send with Ferret", including the ones that
  /// arrived before anyone listened.
  Stream<SharedItems> get shares {
    if (!_listening) {
      _listening = true;
      FerretDropFlutterApi.setUp(this);
      unawaited(_takePending());
    }

    return _shares.stream;
  }

  @override
  void onShared(SharedItems items) => _shares.add(items);

  /// Whether received files can go to the shared Downloads collection.
  Future<bool> canSaveToDownloads() =>
      _soft(_api.canSaveToDownloads, fallback: false);

  /// Moves a finished file into Downloads/[folder], never overwriting.
  Future<SavedFile> saveToDownloads({
    required String sourcePath,
    required String fileName,
    required String mimeType,
    required String folder,
  }) => _api.saveToDownloads(sourcePath, fileName, mimeType, folder);

  /// Opens a received file in its default app.
  Future<bool> open(String location, {String mimeType = ''}) =>
      _soft(() => _api.open(location, mimeType), fallback: false);

  /// Shows a received file in the file manager.
  Future<bool> reveal(String location) =>
      _soft(() => _api.reveal(location), fallback: false);

  Future<void> _takePending() async {
    final pending = await _soft(
      _api.takePendingShares,
      fallback: const <SharedItems>[],
    );
    for (final items in pending) {
      _shares.add(items);
    }
  }

  Future<T> _soft<T>(Future<T> Function() call, {required T fallback}) async {
    try {
      return await call();
    } on PlatformException {
      return fallback;
    } on MissingPluginException {
      return fallback;
    }
  }
}
