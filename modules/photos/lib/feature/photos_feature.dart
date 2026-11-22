import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_photos/ferret_photos.dart';
import 'package:fixnum/fixnum.dart';
import 'package:photos/models/models.dart';
import 'package:photos/services/services.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/photos.dart';
import 'package:protocol/protocol.dart';

/// A phone's recent photos and screenshots on a computer.
///
/// A phone shares them (flag `share`) only with computers its owner turned
/// on, one by one, and never deletes anything. A computer (flag `browse`)
/// pages through them newest first, asks for thumbnails only as they come
/// into view, and saves full files through the app's file transfer. It can
/// ask a phone to send each new screenshot by itself while both run.
class PhotosFeature extends Feature {
  PhotosFeature({
    PhotoLibrary? library,
    this.cache,
    this.transfers,
    DateTime Function()? now,
  }) : library = library ?? PhotoLibrary.current(),
       _now = now ?? DateTime.now;

  static const featureId = 'photos';

  /// This device shares its photos.
  static const shareFlag = 'share';

  /// This device browses other devices' photos.
  static const browseFlag = 'browse';

  /// The most a phone sends in one page.
  static const maxPage = 200;

  /// The most full photos one request may fetch.
  static const maxFetch = 100;

  static const _requestTimeout = Duration(seconds: 20);

  final PhotoLibrary library;

  /// Thumbnails kept on a computer. Null on a phone, and on a computer
  /// until the app sets it.
  ThumbnailCache? cache;

  /// How full files travel, set by the app. Without it nothing is fetched.
  PhotoTransfers? transfers;

  final DateTime Function() _now;
  late final PhotosSettings settings;

  /// What came to this computer, for Activity.
  final PhotoSaves saves = PhotoSaves();

  /// Full files already here, by device and photo: a drag out of one
  /// uses it rather than fetching it again.
  final Map<(String, String), String> _localCopies = {};

  final Map<String, DateTime> _subscribers = {};
  final Set<String> _sentScreenshots = {};
  final StreamController<String> _accessPrompts = .broadcast();
  StreamSubscription<PhotoEntry>? _watch;
  StreamSubscription<List<TrustedDevice>>? _trustChanges;
  StreamSubscription<String>? _settingChanges;
  var _saveCount = 0;

  @override
  String get id => featureId;

  bool get isPhone => library.isSupported;

  @override
  List<String> get flags => switch (isPhone) {
    true => const [shareFlag],
    false => const [browseFlag],
  };

  /// On a phone: the id of a computer whose owner asks to see photos, or
  /// more of them.
  Stream<String> get accessPrompts => _accessPrompts.stream;

  /// Whether [session] is a phone that shares photos.
  static bool sharesPhotos(Session session) =>
      session.remoteFeature(featureId)?.flags.contains(shareFlag) ?? false;

  @override
  Future<void> onStart() async {
    settings = PhotosSettings(host.settings);
    _settingChanges = settings.changes.listen((_) => _onSettingsChanged());
    _trustChanges = host.trustStore.changes.listen(_onTrustChanged);
    if (cache case final cache?) {
      unawaited(cache.keepOnly(_pairedIds()));
    }
  }

  /// Keeps thumbnails in [thumbnails] from now on, and drops the ones of
  /// phones that aren't paired any more.
  void useCache(ThumbnailCache thumbnails) {
    cache = thumbnails;
    unawaited(thumbnails.keepOnly(_pairedIds()));
  }

  @override
  Future<void> stop() async {
    await _watch?.cancel();
    _watch = null;
    await _trustChanges?.cancel();
    await _settingChanges?.cancel();
    await _accessPrompts.close();
    await saves.dispose();
  }

  @override
  void onSessionOpened(Session session) {
    if (isPhone || !sharesPhotos(session)) {
      return;
    }

    if (!settings.autoScreenshots(session.remoteDeviceId)) {
      return;
    }

    unawaited(_subscribe(session, enabled: true));
  }

  @override
  void onSessionClosed(Session session) {
    if (_subscribers.remove(session.remoteDeviceId) == null) {
      return;
    }

    unawaited(_updateWatch());
  }

  @override
  Future<void> onPairedDevices(Set<String> deviceIds) =>
      host.settings.keepOnlyPaired([
        PhotosSettings.sharedWithKey,
        PhotosSettings.autoScreenshotsKey,
      ], deviceIds);

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    if (payloadOf(envelope, PhotoListRequest.new) case final request?) {
      return _list(session.remoteDeviceId, request);
    }

    if (payloadOf(envelope, ThumbnailRequest.new) case final request?) {
      return _thumbnail(session.remoteDeviceId, request);
    }

    if (payloadOf(envelope, PhotoFetchRequest.new) case final request?) {
      return _fetch(session.remoteDeviceId, request);
    }

    if (payloadOf(envelope, ScreenshotSubscription.new) case final request?) {
      _onSubscription(session.remoteDeviceId, enabled: request.enabled);
      return null;
    }

    if (payloadOf(envelope, ScreenshotSent.new) case final sent?) {
      _onScreenshotSent(session.remoteDeviceId, sent);
      return null;
    }

    if (payloadOf(envelope, PhotoAccessPrompt.new) != null) {
      _onAccessPrompt(session.remoteDeviceId);
      return null;
    }

    return null;
  }

  // The phone's side.

  /// What [deviceId] may see right now.
  Future<PhotoAccess> accessFor(String deviceId) async {
    if (!settings.sharesWith(deviceId)) {
      return .PHOTO_ACCESS_NOT_ALLOWED;
    }

    return switch (await library.access()) {
      .full => .PHOTO_ACCESS_FULL,
      .limited => .PHOTO_ACCESS_LIMITED,
      .denied || .notAsked => .PHOTO_ACCESS_NO_PERMISSION,
      .unavailable || .unsupported => .PHOTO_ACCESS_UNAVAILABLE,
    };
  }

  /// Turns sharing with [deviceId] on or off. Turning it on asks the
  /// system for photo access first when there is none.
  Future<PhotoLibraryAccess> setSharesWith(
    String deviceId, {
    required bool shared,
  }) async {
    var access = await library.access();
    if (shared && !access.canRead && access != .denied) {
      access = await library.requestAccess();
    }

    await settings.setSharesWith(deviceId, shared: shared);
    return access;
  }

  Future<PhotoList> _list(String deviceId, PhotoListRequest request) async {
    final access = await accessFor(deviceId);
    if (!_canRead(access)) {
      return PhotoList(access: access);
    }

    final limit = request.limit.clamp(1, maxPage);
    final cursor = switch (request.cursor) {
      '' => null,
      final cursor => cursor,
    };
    final page = await library.list(cursor: cursor, limit: limit);

    return PhotoList(
      items: [for (final entry in page.entries) itemOf(entry)],
      nextCursor: page.nextCursor ?? '',
      access: access,
    );
  }

  Future<Thumbnail> _thumbnail(
    String deviceId,
    ThumbnailRequest request,
  ) async {
    final access = await accessFor(deviceId);
    if (!_canRead(access)) {
      return Thumbnail(id: request.id, access: access);
    }

    final maxPx = request.maxPx.clamp(32, 2048);
    final jpeg = await library.thumbnail(request.id, maxPx: maxPx);

    return Thumbnail(id: request.id, jpeg: jpeg, access: access);
  }

  Future<PhotoFetchReply> _fetch(
    String deviceId,
    PhotoFetchRequest request,
  ) async {
    final access = await accessFor(deviceId);
    final transfers = this.transfers;
    if (!_canRead(access) || transfers == null) {
      return PhotoFetchReply(access: access);
    }

    final ids = request.ids.take(maxFetch).toList();
    final paths = <String>[];
    for (final id in ids) {
      if (await library.export(id) case final path?) {
        paths.add(path);
      }
    }
    final missing = ids.length - paths.length;
    if (paths.isEmpty) {
      return PhotoFetchReply(access: access, missing: missing);
    }

    final transferId = await transfers.send(deviceId, paths);

    return PhotoFetchReply(
      transferId: transferId ?? '',
      access: access,
      missing: missing,
    );
  }

  void _onSubscription(String deviceId, {required bool enabled}) {
    if (!isPhone) {
      return;
    }

    if (enabled) {
      _subscribers.putIfAbsent(deviceId, _now);
    }

    if (!enabled) {
      _subscribers.remove(deviceId);
    }

    unawaited(_updateWatch());
  }

  void _onAccessPrompt(String deviceId) {
    if (!isPhone || _accessPrompts.isClosed) {
      return;
    }

    _accessPrompts.add(deviceId);
  }

  /// Watches for screenshots only while a computer the owner shares with
  /// asked for them: no observer runs otherwise.
  Future<void> _updateWatch() async {
    final wanted = _subscribers.keys.any(settings.sharesWith);
    if (wanted && _watch == null) {
      _watch = library.newScreenshots.listen(
        (entry) => unawaited(_onScreenshot(entry)),
      );
      return;
    }

    if (wanted) {
      return;
    }

    await _watch?.cancel();
    _watch = null;
  }

  Future<void> _onScreenshot(PhotoEntry entry) async {
    final transfers = this.transfers;
    if (transfers == null) {
      return;
    }

    final targets = [
      for (final MapEntry(key: deviceId, value: subscribedAt)
          in _subscribers.entries)
        if (ScreenshotRule.shouldSend(
          entry: entry,
          isShared: settings.sharesWith(deviceId),
          subscribedAt: subscribedAt,
          alreadySent: _sentScreenshots,
        ))
          deviceId,
    ];
    if (targets.isEmpty) {
      return;
    }

    _sentScreenshots.add(entry.id);
    for (final deviceId in targets) {
      final session = host.sessionFor(deviceId);
      final path = await library.export(entry.id);
      if (session == null || path == null) {
        continue;
      }

      final transferId = await transfers.send(deviceId, [path]);
      if (transferId == null) {
        continue;
      }

      await _sendQuietly(
        session,
        ScreenshotSent(transferId: transferId, item: itemOf(entry)),
      );
    }
  }

  // The computer's side.

  /// A page of [deviceId]'s photos, newest first, from [cursor].
  Future<PhotoListResult> list(
    String deviceId, {
    String? cursor,
    int limit = 60,
  }) async {
    final session = host.sessionFor(deviceId);
    if (session == null) {
      return const .failed(.offline);
    }

    if (!sharesPhotos(session)) {
      return const .failed(.unsupported);
    }

    try {
      final reply = await session.call(
        featureId,
        PhotoListRequest(cursor: cursor ?? '', limit: limit),
        PhotoList.new,
        timeout: _requestTimeout,
      );

      return PhotoListResult(
        items: reply.items,
        nextCursor: switch (reply.nextCursor) {
          '' => null,
          final next => next,
        },
        access: reply.access,
        total: reply.total,
      );
    } on Object catch (error) {
      printWarning('Photos: listing failed: ${error.runtimeType}');
      return const .failed(.failed);
    }
  }

  /// A JPEG of one photo on [deviceId], from the cache when it was fetched
  /// before.
  Future<Uint8List?> thumbnail(
    String deviceId,
    String photoId, {
    required int maxPx,
  }) async {
    if (await cache?.read(deviceId, photoId, maxPx) case final cached?) {
      return cached;
    }

    final session = host.sessionFor(deviceId);
    if (session == null) {
      return null;
    }

    try {
      final reply = await session.call(
        featureId,
        ThumbnailRequest(id: photoId, maxPx: maxPx),
        Thumbnail.new,
        timeout: _requestTimeout,
      );
      if (reply.jpeg.isEmpty) {
        return null;
      }

      final bytes = Uint8List.fromList(reply.jpeg);
      await cache?.write(deviceId, photoId, maxPx, bytes);
      return bytes;
    } on Object catch (error) {
      printWarning('Photos: thumbnail failed: ${error.runtimeType}');
      return null;
    }
  }

  /// Opens a saved file in its app. False when nothing could open it.
  Future<bool> openSaved(String path) async =>
      await transfers?.open(path) ?? false;

  /// Shows a saved file in Finder or the file manager.
  Future<bool> revealSaved(String path) async =>
      await transfers?.reveal(path) ?? false;

  /// Saves the full files of [photoIds] from [deviceId] into the receive
  /// folder. Returns the save, which Activity shows as it goes.
  Future<PhotoSave> save(String deviceId, List<String> photoIds) async {
    final save = PhotoSave(
      id: 'save.${++_saveCount}',
      deviceId: deviceId,
      count: photoIds.length,
      startedAt: _now(),
    );
    saves.add(save);

    final problem = await _fetchInto(save, photoIds);
    if (problem != null) {
      saves.update(
        save.id,
        (current) => current.copyWith(status: .failed, problem: problem),
      );
    }

    final result = saves[save.id] ?? save;
    // Paths come in the order asked for; with one missing they can't be
    // matched up, so none is kept.
    if (result.status == .done && result.paths.length == photoIds.length) {
      for (final (index, photoId) in photoIds.indexed) {
        _localCopies[(deviceId, photoId)] = result.paths[index];
      }
    }

    return result;
  }

  /// The full file of [photoId] when it is on this computer already, such
  /// as after a save.
  String? localCopy(String deviceId, String photoId) {
    final path = _localCopies[(deviceId, photoId)];
    if (path == null) {
      return null;
    }

    if (!File(path).existsSync()) {
      _localCopies.remove((deviceId, photoId));
      return null;
    }

    return path;
  }

  /// The full file of [photoId] on this computer: the one here already,
  /// or a fresh save into the receive folder. Null when it couldn't come.
  Future<String?> fetchLocal(String deviceId, String photoId) async {
    if (localCopy(deviceId, photoId) case final path?) {
      return path;
    }

    final save = await this.save(deviceId, [photoId]);
    return switch (save) {
      PhotoSave(status: .done, paths: [final path, ...]) => path,
      _ => null,
    };
  }

  Future<PhotoSaveProblem?> _fetchInto(
    PhotoSave save,
    List<String> photoIds,
  ) async {
    final session = host.sessionFor(save.deviceId);
    final transfers = this.transfers;
    if (session == null || !sharesPhotos(session)) {
      return .offline;
    }

    if (transfers == null) {
      return .failed;
    }

    final PhotoFetchReply reply;
    try {
      reply = await session.call(
        featureId,
        PhotoFetchRequest(ids: photoIds.take(maxFetch)),
        PhotoFetchReply.new,
        timeout: const Duration(minutes: 2),
      );
    } on Object catch (error) {
      printWarning('Photos: fetch failed: ${error.runtimeType}');
      return .failed;
    }

    switch (reply.access) {
      case .PHOTO_ACCESS_NOT_ALLOWED:
        return .notAllowed;
      case .PHOTO_ACCESS_NO_PERMISSION || .PHOTO_ACCESS_UNAVAILABLE:
        return .noPermission;
      default:
        break;
    }

    if (reply.transferId.isEmpty) {
      return .missing;
    }

    saves.update(
      save.id,
      (current) => current.copyWith(count: photoIds.length - reply.missing),
    );
    await saves.follow(save.id, transfers.follow(reply.transferId));
    return null;
  }

  /// Whether [deviceId]'s new screenshots come here by themselves.
  bool autoScreenshots(String deviceId) => settings.autoScreenshots(deviceId);

  Future<void> setAutoScreenshots(
    String deviceId, {
    required bool enabled,
  }) async {
    await settings.setAutoScreenshots(deviceId, enabled: enabled);
    final session = host.sessionFor(deviceId);
    if (session == null || !sharesPhotos(session)) {
      return;
    }

    await _subscribe(session, enabled: enabled);
  }

  /// Asks [deviceId]'s owner, on the phone, to share photos here, or more
  /// of them.
  Future<bool> askForAccess(String deviceId) async {
    final session = host.sessionFor(deviceId);
    if (session == null || !sharesPhotos(session)) {
      return false;
    }

    return _sendQuietly(session, PhotoAccessPrompt());
  }

  void _onScreenshotSent(String deviceId, ScreenshotSent sent) {
    final transfers = this.transfers;
    if (isPhone || transfers == null || !autoScreenshots(deviceId)) {
      return;
    }

    final save = PhotoSave(
      id: 'shot.${sent.transferId}',
      deviceId: deviceId,
      count: 1,
      startedAt: _now(),
      isScreenshot: true,
    );
    saves.add(save);
    unawaited(saves.follow(save.id, transfers.follow(sent.transferId)));
  }

  Future<void> _subscribe(Session session, {required bool enabled}) =>
      _sendQuietly(session, ScreenshotSubscription(enabled: enabled));

  void _onSettingsChanged() {
    unawaited(_updateWatch());
  }

  void _onTrustChanged(List<TrustedDevice> devices) {
    final paired = {for (final device in devices) device.id};
    for (final deviceId in [..._subscribers.keys]) {
      if (!paired.contains(deviceId)) {
        _subscribers.remove(deviceId);
      }
    }

    unawaited(_updateWatch());
    if (cache case final cache?) {
      unawaited(cache.keepOnly(paired));
    }
  }

  Set<String> _pairedIds() => {
    for (final device in host.trustStore.devices) device.id,
  };

  static bool _canRead(PhotoAccess access) =>
      access == .PHOTO_ACCESS_FULL || access == .PHOTO_ACCESS_LIMITED;

  static Future<bool> _sendQuietly(
    Session session,
    GeneratedMessage message,
  ) async {
    try {
      await session.send(featureId, message);
      return true;
    } on Object catch (error) {
      printWarning('Photos: could not reach a phone: ${error.runtimeType}');
      return false;
    }
  }

  /// [entry] as the protocol sends it.
  static PhotoItem itemOf(PhotoEntry entry) => PhotoItem(
    id: entry.id,
    takenAtMs: Int64(entry.takenAt.millisecondsSinceEpoch),
    width: entry.width,
    height: entry.height,
    kind: switch (entry.kind) {
      .photo => .PHOTO_KIND_PHOTO,
      .screenshot => .PHOTO_KIND_SCREENSHOT,
      .video => .PHOTO_KIND_VIDEO,
    },
    size: Int64(entry.size),
    name: entry.name,
    durationMs: entry.duration.inMilliseconds,
  );
}
