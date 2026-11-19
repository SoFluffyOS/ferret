/// Reads a phone's recent photos and screenshots: pages newest first, small
/// JPEG thumbnails, a copy of one photo to send, and new screenshots as they
/// are taken. MediaStore on Android, PhotoKit on iOS; nothing on computers.
library;

export 'package:ferret_photos/src/channel_photo_library.dart';
export 'package:ferret_photos/src/photo_entry.dart';
export 'package:ferret_photos/src/photo_entry_kind.dart';
export 'package:ferret_photos/src/photo_library.dart';
export 'package:ferret_photos/src/photo_library_access.dart';
export 'package:ferret_photos/src/photo_page.dart';
export 'package:ferret_photos/src/unsupported_photo_library.dart';
