import 'package:ferret_photos/src/channel_photo_library.dart';
import 'package:ferret_photos/src/photo_entry.dart';
import 'package:ferret_photos/src/photo_library_access.dart';
import 'package:ferret_photos/src/photo_page.dart';
import 'package:ferret_photos/src/unsupported_photo_library.dart';
import 'package:flutter/foundation.dart';

/// This device's photo library, read only. Nothing here deletes or changes
/// a photo.
abstract interface class PhotoLibrary {
  /// MediaStore on Android, PhotoKit on iOS, nothing elsewhere.
  factory PhotoLibrary.current() => switch (defaultTargetPlatform) {
    .android || .iOS when !kIsWeb => ChannelPhotoLibrary(),
    _ => const UnsupportedPhotoLibrary(),
  };

  /// Whether this platform has a library to read at all.
  bool get isSupported;

  Future<PhotoLibraryAccess> access();

  /// Asks the system for access, only while the app is on screen. When
  /// access is [PhotoLibraryAccess.limited], lets the person pick more.
  Future<PhotoLibraryAccess> requestAccess();

  /// Up to [limit] photos and videos, newest first, from [cursor] (null for
  /// the first page).
  Future<PhotoPage> list({String? cursor, int limit = 60});

  /// A JPEG of [id] whose longest side is about [maxPx], or null when it is
  /// gone or can't be read.
  Future<Uint8List?> thumbnail(String id, {required int maxPx});

  /// Copies [id]'s full file to a temporary file and returns its path, or
  /// null when it is gone. Whoever sends it deletes it afterwards.
  Future<String?> export(String id);

  /// Screenshots taken from now on, while someone listens. Listening costs
  /// nothing until a photo is added.
  Stream<PhotoEntry> get newScreenshots;

  /// Opens this app's page in the system settings, such as after the
  /// person said no.
  Future<bool> openSettings();
}
