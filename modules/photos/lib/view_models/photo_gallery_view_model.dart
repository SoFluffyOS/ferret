import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:photos/feature/feature.dart';
import 'package:photos/models/models.dart';
import 'package:protocol/photos.dart';

/// One phone's photos on this computer: pages newest first, thumbnails as
/// tiles come into view, and the selection to save.
class PhotoGalleryViewModel extends ChangeNotifier {
  PhotoGalleryViewModel(this._feature, this.deviceId, {this.pageSize = 60});

  final PhotosFeature _feature;
  final String deviceId;
  final int pageSize;

  final List<PhotoItem> _items = [];
  final Set<String> _ids = {};
  final Map<String, Future<Uint8List?>> _thumbnails = {};
  final Set<String> _selected = {};
  String? _nextCursor;
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isSelecting = false;
  bool _askedForAccess = false;
  PhotoAccess _access = .PHOTO_ACCESS_UNSPECIFIED;
  PhotoListProblem? _problem;
  int _generation = 0;
  bool _disposed = false;

  List<PhotoItem> get items => List.unmodifiable(_items);

  bool get isLoading => _isLoading;

  bool get isSelecting => _isSelecting;

  Set<String> get selected => Set.unmodifiable(_selected);

  /// Only the photos the phone's owner picked are shared.
  bool get isLimited => _access == .PHOTO_ACCESS_LIMITED;

  /// The owner was asked on the phone, from here, since the page opened.
  bool get askedForAccess => _askedForAccess;

  bool get hasMore => _nextCursor != null;

  bool get autoScreenshots => _feature.autoScreenshots(deviceId);

  GalleryState get state {
    if (!_hasLoaded) {
      return .loading;
    }

    if (_problem case final problem?) {
      return switch (problem) {
        .offline => .offline,
        .unsupported => .unsupported,
        .failed => .failed,
      };
    }

    return switch (_access) {
      .PHOTO_ACCESS_NOT_ALLOWED => .notAllowed,
      .PHOTO_ACCESS_NO_PERMISSION => .noPermission,
      .PHOTO_ACCESS_UNAVAILABLE => .unavailable,
      _ when _items.isEmpty => .empty,
      _ => .photos,
    };
  }

  /// Reads the first page again, keeping thumbnails already fetched.
  Future<void> load() async {
    final generation = ++_generation;
    _isLoading = true;
    _notify();

    final result = await _feature.list(deviceId, limit: pageSize);
    if (generation != _generation) {
      return;
    }

    _items.clear();
    _ids.clear();
    _selected.clear();
    _apply(result);
  }

  /// Reads the next page, once the last one is on screen.
  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _isLoading || _problem != null) {
      return;
    }

    final generation = _generation;
    _isLoading = true;
    _notify();

    final result = await _feature.list(
      deviceId,
      cursor: cursor,
      limit: pageSize,
    );
    if (generation != _generation) {
      return;
    }

    if (result.problem != null) {
      _isLoading = false;
      _notify();
      return;
    }

    _apply(result);
  }

  /// A JPEG of [photoId], asked for once however often a tile rebuilds.
  Future<Uint8List?> thumbnail(String photoId, {required int maxPx}) =>
      _thumbnails.putIfAbsent(
        '$photoId@$maxPx',
        () => _feature.thumbnail(deviceId, photoId, maxPx: maxPx),
      );

  void setSelecting(bool selecting) {
    _isSelecting = selecting;
    if (!selecting) {
      _selected.clear();
    }

    _notify();
  }

  void toggle(String photoId) {
    if (!_selected.remove(photoId)) {
      _selected.add(photoId);
    }

    _isSelecting = true;
    _notify();
  }

  /// Saves [photoIds], or the selection, into the receive folder.
  Future<PhotoSave> save([List<String>? photoIds]) async {
    final ids =
        photoIds ??
        [
          for (final item in _items)
            if (_selected.contains(item.id)) item.id,
        ];
    if (photoIds == null) {
      setSelecting(false);
    }

    return _feature.save(deviceId, ids);
  }

  /// The full file of [photoId] when it is on this computer already.
  String? localCopy(String photoId) => _feature.localCopy(deviceId, photoId);

  /// The full file of [photoId] on this computer, saved first when it
  /// isn't here yet.
  Future<String?> fetchLocal(String photoId) =>
      _feature.fetchLocal(deviceId, photoId);

  /// What a drag that starts on [item] takes: the whole selection when
  /// [item] is in it, else [item] alone.
  List<PhotoItem> dragged(PhotoItem item) {
    if (!_isSelecting || !_selected.contains(item.id)) {
      return [item];
    }

    return [
      for (final each in _items)
        if (_selected.contains(each.id)) each,
    ];
  }

  Future<bool> open(String path) => _feature.openSaved(path);

  Future<bool> reveal(String path) => _feature.revealSaved(path);

  Future<void> setAutoScreenshots(bool enabled) async {
    await _feature.setAutoScreenshots(deviceId, enabled: enabled);
    _notify();
  }

  Future<void> askForAccess() async {
    _askedForAccess = await _feature.askForAccess(deviceId);
    _notify();
  }

  void _apply(PhotoListResult result) {
    _isLoading = false;
    _hasLoaded = true;
    _problem = result.problem;
    _access = result.access;
    _nextCursor = result.nextCursor;
    for (final item in result.items) {
      if (_ids.add(item.id)) {
        _items.add(item);
      }
    }
    _notify();
  }

  void _notify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
