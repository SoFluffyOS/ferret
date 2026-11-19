import 'dart:async';
import 'dart:typed_data';

import 'package:ferret_photos/ferret_photos.dart';

/// A phone's library in memory: [entries] newest first, paged by index.
class FakePhotoLibrary implements PhotoLibrary {
  FakePhotoLibrary({List<PhotoEntry>? entries, this.accessNow = .full})
    : entries = entries ?? [];

  final List<PhotoEntry> entries;
  PhotoLibraryAccess accessNow;
  PhotoLibraryAccess afterRequest = .full;
  int requests = 0;
  int thumbnailCalls = 0;
  final List<String> exported = [];
  final StreamController<PhotoEntry> screenshots = .broadcast();

  @override
  bool get isSupported => true;

  @override
  Future<PhotoLibraryAccess> access() async => accessNow;

  @override
  Future<PhotoLibraryAccess> requestAccess() async {
    requests++;
    accessNow = afterRequest;
    return accessNow;
  }

  @override
  Future<PhotoPage> list({String? cursor, int limit = 60}) async {
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = (start + limit).clamp(0, entries.length);
    final next = switch (end < entries.length) {
      true => '$end',
      false => null,
    };

    return PhotoPage(entries.sublist(start, end), nextCursor: next);
  }

  @override
  Future<Uint8List?> thumbnail(String id, {required int maxPx}) async {
    thumbnailCalls++;
    if (!entries.any((entry) => entry.id == id)) {
      return null;
    }

    return Uint8List.fromList([0xff, 0xd8, maxPx & 0xff, id.length]);
  }

  @override
  Future<String?> export(String id) async {
    if (!entries.any((entry) => entry.id == id)) {
      return null;
    }

    exported.add(id);
    return '/tmp/export/$id.jpg';
  }

  @override
  Stream<PhotoEntry> get newScreenshots => screenshots.stream;

  @override
  Future<bool> openSettings() async => true;
}

PhotoEntry entry(String id, DateTime takenAt, {PhotoEntryKind kind = .photo}) =>
    PhotoEntry(id: id, takenAt: takenAt, kind: kind, name: '$id.jpg');
