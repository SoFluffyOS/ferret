import 'package:local_shelf/models/shelf_kind.dart';
import 'package:local_shelf/models/shelf_source.dart';

/// One thing on the shelf. Each has a file to drag out: a file of the
/// person's own where it is (never copied), or one Ferret keeps in its
/// cache for text, links, pictures and things dropped from a temporary
/// place.
class ShelfItem {
  const ShelfItem({
    required this.id,
    required this.kind,
    required this.path,
    required this.name,
    required this.key,
    required this.addedAt,
    required this.source,
    this.text = '',
    this.fromDeviceId,
    this.isCached = false,
    this.isMissing = false,
  });

  final String id;
  final ShelfKind kind;

  /// The file to drag out.
  final String path;

  /// What it is called on screen, such as the file's name or the start of
  /// the text.
  final String name;

  /// What makes two items the same, so the same thing is kept once.
  final String key;
  final DateTime addedAt;
  final ShelfSource source;

  /// The start of the text for text, the web address for a link.
  final String text;

  /// The device a copy came from; null when it came from this computer.
  final String? fromDeviceId;

  /// Whether [path] sits in Ferret's cache, to be deleted with the item.
  final bool isCached;

  /// Whether the file isn't at [path] anymore, moved or deleted.
  final bool isMissing;

  ShelfItem copyWith({
    DateTime? addedAt,
    ShelfSource? source,
    bool? isMissing,
  }) => ShelfItem(
    id: id,
    kind: kind,
    path: path,
    name: name,
    key: key,
    addedAt: addedAt ?? this.addedAt,
    source: source ?? this.source,
    text: text,
    fromDeviceId: fromDeviceId,
    isCached: isCached,
    isMissing: isMissing ?? this.isMissing,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'path': path,
    'name': name,
    'key': key,
    'addedAt': addedAt.millisecondsSinceEpoch,
    'source': source.name,
    'text': text,
    'fromDeviceId': ?fromDeviceId,
    'cached': isCached,
  };

  /// The item stored as [json], or null when it isn't one.
  static ShelfItem? fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'path': final String path,
      'name': final String name,
      'key': final String key,
      'addedAt': final int addedAt,
    }) {
      return ShelfItem(
        id: id,
        kind: ShelfKind.byName(json['kind']),
        path: path,
        name: name,
        key: key,
        addedAt: DateTime.fromMillisecondsSinceEpoch(addedAt),
        source: ShelfSource.byName(json['source']),
        text: switch (json['text']) {
          final String text => text,
          _ => '',
        },
        fromDeviceId: switch (json['fromDeviceId']) {
          final String deviceId => deviceId,
          _ => null,
        },
        isCached: json['cached'] == true,
      );
    }

    return null;
  }
}
