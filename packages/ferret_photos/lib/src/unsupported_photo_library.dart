import 'dart:typed_data';

import 'package:ferret_photos/src/photo_entry.dart';
import 'package:ferret_photos/src/photo_library.dart';
import 'package:ferret_photos/src/photo_library_access.dart';
import 'package:ferret_photos/src/photo_page.dart';

/// A device without a photo library Ferret reads, such as a computer.
class UnsupportedPhotoLibrary implements PhotoLibrary {
  const UnsupportedPhotoLibrary();

  @override
  bool get isSupported => false;

  @override
  Future<PhotoLibraryAccess> access() async => .unsupported;

  @override
  Future<PhotoLibraryAccess> requestAccess() async => .unsupported;

  @override
  Future<PhotoPage> list({String? cursor, int limit = 60}) async =>
      PhotoPage.empty;

  @override
  Future<Uint8List?> thumbnail(String id, {required int maxPx}) async => null;

  @override
  Future<String?> export(String id) async => null;

  @override
  Stream<PhotoEntry> get newScreenshots => const Stream.empty();

  @override
  Future<bool> openSettings() async => false;
}
