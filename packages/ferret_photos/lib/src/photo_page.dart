import 'package:ferret_photos/src/photo_entry.dart';

/// One page of the library, newest first.
class PhotoPage {
  const PhotoPage(this.entries, {this.nextCursor});

  static const empty = PhotoPage([]);

  /// Reads `{entries: [...], nextCursor}` from the platform.
  static PhotoPage fromMap(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return empty;
    }

    final entries = switch (value['entries']) {
      final List<Object?> list => [
        for (final item in list) ?PhotoEntry.fromMap(item),
      ],
      _ => const <PhotoEntry>[],
    };
    final nextCursor = switch (value['nextCursor']) {
      final String cursor when cursor.isNotEmpty => cursor,
      _ => null,
    };

    return PhotoPage(entries, nextCursor: nextCursor);
  }

  final List<PhotoEntry> entries;

  /// Where the next page starts, or null after the last one.
  final String? nextCursor;
}
