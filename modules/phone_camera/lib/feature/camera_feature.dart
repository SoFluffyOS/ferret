import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_camera/ferret_camera.dart';
import 'package:path/path.dart' as p;
import 'package:phone_camera/models/models.dart';
import 'package:phone_camera/services/services.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/camera.dart';
import 'package:protocol/protocol.dart';

/// A photo from the phone, straight onto the computer's clipboard.
///
/// A computer (flag `request`) asks a phone for a picture. The phone (flags
/// `photo`, and `document` on an iPhone) shows "MacBook Air wants a photo"
/// with Take photo and Not now, then its own camera: nothing is captured
/// until its owner presses the shutter. The picture comes back through the
/// app's file transfer, lands in the receive folder, and goes on the
/// computer's clipboard.
class CameraFeature extends Feature {
  CameraFeature({
    PhoneCamera? camera,
    this.transfers,
    this.paste,
    this.askFor = const Duration(minutes: 5),
    DateTime Function()? now,
  }) : camera = camera ?? PhoneCamera.current(),
       _now = now ?? DateTime.now;

  static const featureId = 'camera';

  /// This device takes photos for others.
  static const photoFlag = 'photo';

  /// This device scans documents for others.
  static const documentFlag = 'document';

  /// This device asks others for pictures.
  static const requestFlag = 'request';

  static const _replyTimeout = Duration(seconds: 20);

  /// Extra time a computer waits past the phone's own [askFor], so the
  /// phone's "expired" arrives first.
  static const _graceAfterAsk = Duration(seconds: 30);

  final PhoneCamera camera;

  /// How pictures travel, set by the app. Without it nothing is sent.
  CaptureTransfers? transfers;

  /// How a picture goes on the clipboard, set by the app on a computer.
  CapturePaste? paste;

  /// How long a phone shows a request before it gives up.
  final Duration askFor;

  final DateTime Function() _now;

  /// A computer's requests, for Activity.
  final CaptureJobs jobs = CaptureJobs();

  final Map<String, CaptureAsk> _asks = {};
  final Map<String, Timer> _timers = {};
  final StreamController<void> _askChanges = .broadcast();
  var _count = 0;

  @override
  String get id => featureId;

  bool get isPhone => camera.isSupported;

  @override
  List<String> get flags => switch (isPhone) {
    true => [photoFlag, if (camera.scansDocuments) documentFlag],
    false => const [requestFlag],
  };

  /// On a phone: the requests waiting for the owner, newest first.
  List<CaptureAsk> get asks =>
      _asks.values.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

  /// Fires when [asks] changed.
  Stream<void> get askChanges => _askChanges.stream;

  /// Whether [session] is a phone that takes photos for this device.
  static bool takesPhotos(Session session) => _has(session, photoFlag);

  /// Whether [session] is a phone that scans documents, such as an iPhone.
  static bool scansDocuments(Session session) => _has(session, documentFlag);

  static bool _has(Session session, String flag) =>
      session.remoteFeature(featureId)?.flags.contains(flag) ?? false;

  @override
  Future<void> stop() async {
    for (final timer in _timers.values) {
      timer.cancel();
    }

    _timers.clear();
    await _askChanges.close();
    await jobs.dispose();
  }

  @override
  void onSessionClosed(Session session) {
    final deviceId = session.remoteDeviceId;
    for (final ask in [..._asks.values]) {
      if (ask.deviceId == deviceId && !ask.isCapturing) {
        _dropAsk(ask.requestId);
      }
    }

    for (final job in jobs.openFor(deviceId)) {
      if (job.status == .asking) {
        _end(job.id, .offline);
      }
    }
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    final deviceId = session.remoteDeviceId;
    if (payloadOf(envelope, CaptureRequest.new) case final request?) {
      return _onRequest(deviceId, request);
    }

    if (payloadOf(envelope, CaptureResult.new) case final result?) {
      _onResult(deviceId, result);
      return null;
    }

    if (payloadOf(envelope, CaptureCancel.new) case final cancel?) {
      _onCancel(deviceId, cancel.requestId);
      return null;
    }

    return null;
  }

  // The phone's side.

  CaptureReply _onRequest(String deviceId, CaptureRequest request) {
    CaptureReply reply(CaptureStatus status) =>
        CaptureReply(requestId: request.requestId, status: status);

    final kind = switch (request.kind) {
      .CAPTURE_KIND_DOCUMENT => PictureKind.document,
      _ => PictureKind.photo,
    };
    if (!isPhone || request.requestId.isEmpty) {
      return reply(.CAPTURE_STATUS_UNSUPPORTED);
    }

    if (kind == .document && !camera.scansDocuments) {
      return reply(.CAPTURE_STATUS_UNSUPPORTED);
    }

    if (_asks.values.any((ask) => ask.isCapturing)) {
      return reply(.CAPTURE_STATUS_BUSY);
    }

    for (final older in [..._asks.values]) {
      if (older.deviceId == deviceId) {
        _dropAsk(older.requestId);
      }
    }

    final requestId = request.requestId;
    _asks[requestId] = CaptureAsk(
      requestId: requestId,
      deviceId: deviceId,
      kind: kind,
      receivedAt: _now(),
    );
    _timers[requestId] = Timer(askFor, () => unawaited(_expire(requestId)));
    _notifyAsks();

    return reply(.CAPTURE_STATUS_ASKING);
  }

  /// Opens the camera for [requestId], after its owner pressed Take photo,
  /// and sends what comes back. A picture the computer stopped waiting for
  /// meanwhile is thrown away.
  Future<void> take(String requestId) async {
    final ask = _asks[requestId];
    if (ask == null || _asks.values.any((other) => other.isCapturing)) {
      return;
    }

    _timers.remove(requestId)?.cancel();
    _asks[requestId] = ask.capturing();
    _notifyAsks();

    final result = await _capture(ask.kind);
    final stillWanted = _asks.remove(requestId) != null;
    _notifyAsks();
    if (!stillWanted) {
      await _discard(result.path);
      return;
    }

    final (status, transferId) = await _send(ask.deviceId, result);
    await _tell(
      ask.deviceId,
      CaptureResult(
        requestId: requestId,
        status: status,
        transferId: transferId ?? '',
        mimeType: result.mimeType ?? '',
      ),
    );
  }

  /// Not now: the computer hears it right away.
  Future<void> decline(String requestId) async {
    final ask = _asks[requestId];
    if (ask == null || ask.isCapturing) {
      return;
    }

    _dropAsk(requestId);
    await _tell(
      ask.deviceId,
      CaptureResult(requestId: requestId, status: .CAPTURE_STATUS_DECLINED),
    );
  }

  Future<CameraCapture> _capture(PictureKind kind) async {
    try {
      return await switch (kind) {
        .photo => camera.takePhoto(),
        .document => camera.scanDocument(),
      };
    } on Object catch (error) {
      printWarning('Camera: capture failed: ${error.runtimeType}');
      return const CameraCapture(.failed);
    }
  }

  Future<(CaptureStatus, String?)> _send(
    String deviceId,
    CameraCapture result,
  ) async {
    final path = result.path;
    if (result.outcome != .taken || path == null) {
      return (_statusOf(result.outcome), null);
    }

    final transfers = this.transfers;
    final transferId = await transfers?.send(deviceId, path);
    if (transferId == null) {
      await _discard(path);
      return (CaptureStatus.CAPTURE_STATUS_FAILED, null);
    }

    return (CaptureStatus.CAPTURE_STATUS_TAKEN, transferId);
  }

  void _onCancel(String deviceId, String requestId) {
    final ask = _asks[requestId];
    if (ask == null || ask.deviceId != deviceId) {
      return;
    }

    _dropAsk(requestId);
  }

  Future<void> _expire(String requestId) async {
    final ask = _asks[requestId];
    if (ask == null || ask.isCapturing) {
      return;
    }

    _dropAsk(requestId);
    await _tell(
      ask.deviceId,
      CaptureResult(requestId: requestId, status: .CAPTURE_STATUS_EXPIRED),
    );
  }

  void _dropAsk(String requestId) {
    _timers.remove(requestId)?.cancel();
    if (_asks.remove(requestId) == null) {
      return;
    }

    _notifyAsks();
  }

  void _notifyAsks() {
    if (_askChanges.isClosed) {
      return;
    }

    _askChanges.add(null);
  }

  static CaptureStatus _statusOf(CaptureOutcome outcome) => switch (outcome) {
    .taken => .CAPTURE_STATUS_TAKEN,
    .cancelled => .CAPTURE_STATUS_CANCELLED,
    .noPermission => .CAPTURE_STATUS_NO_PERMISSION,
    .unavailable => .CAPTURE_STATUS_UNSUPPORTED,
    .failed => .CAPTURE_STATUS_FAILED,
  };

  static Future<void> _discard(String? path) async {
    if (path == null) {
      return;
    }

    try {
      await File(path).delete();
    } on FileSystemException {
      return;
    }
  }

  // The computer's side.

  /// Asks [deviceId] for a picture. One request per phone at a time: a new
  /// one takes the place of the one before. Returns the request, which
  /// Activity shows as it goes.
  Future<CaptureJob> request(
    String deviceId, {
    PictureKind kind = .photo,
  }) async {
    for (final open in jobs.openFor(deviceId)) {
      await cancel(open.id);
    }

    final job = CaptureJob(
      id: 'capture.${_now().microsecondsSinceEpoch}.${++_count}',
      deviceId: deviceId,
      kind: kind,
      startedAt: _now(),
    );
    jobs.add(job);

    final status = await _ask(job);
    if (status != null) {
      _end(job.id, status);
      return jobs[job.id] ?? job;
    }

    _timers[job.id] = Timer(askFor + _graceAfterAsk, () {
      if (jobs[job.id]?.status != .asking) {
        return;
      }

      unawaited(_tell(deviceId, CaptureCancel(requestId: job.id)));
      _end(job.id, .expired);
    });
    return jobs[job.id] ?? job;
  }

  /// Null when the phone shows the request, else why it doesn't.
  Future<CaptureJobStatus?> _ask(CaptureJob job) async {
    final session = host.sessionFor(job.deviceId);
    if (session == null) {
      return .offline;
    }

    final supported = switch (job.kind) {
      .photo => takesPhotos(session),
      .document => scansDocuments(session),
    };
    if (!supported) {
      return .unsupported;
    }

    try {
      final reply = await session.call(
        featureId,
        CaptureRequest(
          requestId: job.id,
          kind: switch (job.kind) {
            .photo => .CAPTURE_KIND_PHOTO,
            .document => .CAPTURE_KIND_DOCUMENT,
          },
        ),
        CaptureReply.new,
        timeout: _replyTimeout,
      );
      return switch (reply.status) {
        .CAPTURE_STATUS_ASKING => null,
        final status => _jobStatusOf(status),
      };
    } on Object catch (error) {
      printWarning('Camera: request failed: ${error.runtimeType}');
      return .failed;
    }
  }

  /// Stops waiting for [jobId]: the phone takes its request away, and the
  /// line goes from Activity.
  Future<void> cancel(String jobId) async {
    final job = jobs[jobId];
    if (job == null || job.status != .asking) {
      return;
    }

    _timers.remove(jobId)?.cancel();
    jobs.remove(jobId);
    await _tell(job.deviceId, CaptureCancel(requestId: jobId));
  }

  /// Puts [jobId]'s picture on the clipboard again.
  Future<bool> copyAgain(String jobId) => _paste(jobId);

  void _onResult(String deviceId, CaptureResult result) {
    final job = jobs[result.requestId];
    if (job == null || job.deviceId != deviceId || job.status != .asking) {
      return;
    }

    _timers.remove(job.id)?.cancel();
    final transfers = this.transfers;
    if (result.status != .CAPTURE_STATUS_TAKEN) {
      _end(job.id, _jobStatusOf(result.status));
      return;
    }

    if (transfers == null || result.transferId.isEmpty) {
      _end(job.id, .failed);
      return;
    }

    jobs.update(
      job.id,
      (current) => current.copyWith(
        status: .receiving,
        mimeType: switch (result.mimeType) {
          '' => null,
          final mimeType => mimeType,
        },
      ),
    );
    unawaited(_receive(job.id, transfers.follow(result.transferId)));
  }

  Future<void> _receive(
    String jobId,
    Stream<CaptureTransferProgress> progress,
  ) async {
    await for (final step in progress) {
      switch (step.status) {
        case .running:
          jobs.update(jobId, (job) => job.copyWith(fraction: step.fraction));
        case .done:
          jobs.update(
            jobId,
            (job) => job.copyWith(fraction: 1, paths: step.paths),
          );
          await _paste(jobId);
          _end(jobId, .done);
          return;
        case .failed:
          _end(jobId, .failed);
          return;
      }
    }

    if (jobs[jobId]?.status == .receiving) {
      _end(jobId, .failed);
    }
  }

  Future<bool> _paste(String jobId) async {
    final job = jobs[jobId];
    final paste = this.paste;
    final path = job?.paths.firstOrNull;
    if (job == null || paste == null || path == null) {
      return false;
    }

    final mimeType = job.mimeType ?? imageTypeOf(path);
    if (mimeType == null || !mimeType.startsWith('image/')) {
      return false;
    }

    try {
      final bytes = await File(path).readAsBytes();
      final pasted = await paste.putImage(bytes, mimeType: mimeType);
      jobs.update(jobId, (job) => job.copyWith(onClipboard: pasted));
      return pasted;
    } on Object catch (error) {
      printWarning('Camera: could not copy the picture: ${error.runtimeType}');
      return false;
    }
  }

  void _end(String jobId, CaptureJobStatus status) {
    _timers.remove(jobId)?.cancel();
    jobs.update(jobId, (job) => job.copyWith(status: status));
  }

  /// The image type of [path] by its extension, or null when it isn't an
  /// image the clipboard takes.
  static String? imageTypeOf(String path) =>
      switch (p.extension(path).toLowerCase()) {
        '.jpg' || '.jpeg' => 'image/jpeg',
        '.png' => 'image/png',
        '.heic' => 'image/heic',
        _ => null,
      };

  static CaptureJobStatus _jobStatusOf(CaptureStatus status) =>
      switch (status) {
        .CAPTURE_STATUS_ASKING => .asking,
        .CAPTURE_STATUS_TAKEN => .receiving,
        .CAPTURE_STATUS_DECLINED => .declined,
        .CAPTURE_STATUS_CANCELLED => .cancelled,
        .CAPTURE_STATUS_UNSUPPORTED => .unsupported,
        .CAPTURE_STATUS_NO_PERMISSION => .noPermission,
        .CAPTURE_STATUS_BUSY => .busy,
        .CAPTURE_STATUS_EXPIRED => .expired,
        _ => .failed,
      };

  Future<bool> _tell(String deviceId, GeneratedMessage message) async {
    final session = host.sessionFor(deviceId);
    if (session == null) {
      return false;
    }

    try {
      await session.send(featureId, message);
      return true;
    } on Object catch (error) {
      printWarning('Camera: could not reach a device: ${error.runtimeType}');
      return false;
    }
  }
}
