import 'package:ferret_photos/src/photo_entry.dart';
import 'package:ferret_photos/src/photo_library.dart';
import 'package:ferret_photos/src/photo_library_access.dart';
import 'package:ferret_photos/src/photo_page.dart';
import 'package:flutter/services.dart';

/// Android and iOS, through the plugin's channels.
class ChannelPhotoLibrary implements PhotoLibrary {
  static const _methods = MethodChannel('io.sofluffy.ferret_photos');
  static const _screenshots = EventChannel(
    'io.sofluffy.ferret_photos/screenshots',
  );

  @override
  bool get isSupported => true;

  @override
  Future<PhotoLibraryAccess> access() async =>
      PhotoLibraryAccess.byNameOr(await _invoke<String>('access'));

  @override
  Future<PhotoLibraryAccess> requestAccess() async =>
      PhotoLibraryAccess.byNameOr(await _invoke<String>('requestAccess'));

  @override
  Future<PhotoPage> list({String? cursor, int limit = 60}) async =>
      PhotoPage.fromMap(
        await _invoke<Object?>('list', {'cursor': cursor, 'limit': limit}),
      );

  @override
  Future<Uint8List?> thumbnail(String id, {required int maxPx}) =>
      _invoke<Uint8List>('thumbnail', {'id': id, 'maxPx': maxPx});

  @override
  Future<String?> export(String id) => _invoke<String>('export', {'id': id});

  @override
  Stream<PhotoEntry> get newScreenshots => _screenshots
      .receiveBroadcastStream()
      .map(PhotoEntry.fromMap)
      .where((entry) => entry != null)
      .cast<PhotoEntry>();

  @override
  Future<bool> openSettings() async =>
      await _invoke<bool>('openSettings') ?? false;

  static Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _methods.invokeMethod<T>(method, arguments);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
