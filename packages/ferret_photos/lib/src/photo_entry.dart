import 'package:ferret_photos/src/photo_entry_kind.dart';

/// One photo or video in the library. [id] only means something to the
/// library that listed it.
class PhotoEntry {
  const PhotoEntry({
    required this.id,
    required this.takenAt,
    required this.kind,
    this.width = 0,
    this.height = 0,
    this.size = 0,
    this.name = '',
    this.duration = Duration.zero,
  });

  /// Reads `{id, takenAtMs, kind, width, height, size, name, durationMs}`
  /// from the platform, or null when it has no id.
  static PhotoEntry? fromMap(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }

    final id = value['id'];
    if (id is! String || id.isEmpty) {
      return null;
    }

    return PhotoEntry(
      id: id,
      takenAt: DateTime.fromMillisecondsSinceEpoch(_int(value['takenAtMs'])),
      kind: PhotoEntryKind.byNameOr(switch (value['kind']) {
        final String kind => kind,
        _ => null,
      }),
      width: _int(value['width']),
      height: _int(value['height']),
      size: _int(value['size']),
      name: switch (value['name']) {
        final String name => name,
        _ => '',
      },
      duration: Duration(milliseconds: _int(value['durationMs'])),
    );
  }

  final String id;
  final DateTime takenAt;
  final PhotoEntryKind kind;
  final int width;
  final int height;

  /// Bytes, or 0 when unknown.
  final int size;

  /// The file name, such as `IMG_2041.jpg`, or empty.
  final String name;

  /// Zero for anything but a video.
  final Duration duration;

  static int _int(Object? value) => switch (value) {
    final int number when number > 0 => number,
    _ => 0,
  };
}
