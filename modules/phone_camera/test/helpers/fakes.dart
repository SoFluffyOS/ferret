import 'dart:async';
import 'dart:typed_data';

import 'package:ferret_camera/ferret_camera.dart';
import 'package:phone_camera/phone_camera.dart';

/// A phone camera whose shutter the test presses: each capture waits for
/// [press] (or [close]).
class FakePhoneCamera implements PhoneCamera {
  FakePhoneCamera({this.scansDocuments = false});

  @override
  final bool scansDocuments;

  /// How many times the camera was opened.
  var opened = 0;
  Completer<CameraCapture>? _open;

  bool get isOpen => _open != null;

  @override
  bool get isSupported => true;

  @override
  Future<CameraAbilities> abilities() async =>
      CameraAbilities(photo: true, document: scansDocuments);

  @override
  Future<CameraCapture> takePhoto() => _capture();

  @override
  Future<CameraCapture> scanDocument() => _capture();

  /// The person pressed the shutter: the picture is at [path].
  void press(String path, {String mimeType = 'image/jpeg'}) =>
      _finish(CameraCapture.taken(path, mimeType: mimeType));

  /// The camera closed with [outcome] and no picture.
  void close([CaptureOutcome outcome = .cancelled]) =>
      _finish(CameraCapture(outcome));

  Future<CameraCapture> _capture() {
    opened++;
    final open = Completer<CameraCapture>();
    _open = open;
    return open.future;
  }

  void _finish(CameraCapture capture) {
    final open = _open;
    _open = null;
    open?.complete(capture);
  }
}

/// Stands in for drop: remembers what a phone sent, and lets a test say
/// how a transfer on the computer ends.
class FakeTransfers implements CaptureTransfers {
  final List<(String, String)> sent = [];
  final Map<String, StreamController<CaptureTransferProgress>> _follows = {};
  var _next = 0;

  @override
  Future<String?> send(String deviceId, String path) async {
    sent.add((deviceId, path));
    return 'transfer-${++_next}';
  }

  @override
  Stream<CaptureTransferProgress> follow(String transferId) =>
      _controller(transferId).stream;

  bool isFollowing(String transferId) => _follows.containsKey(transferId);

  void finish(String transferId, List<String> paths) {
    final controller = _controller(transferId);
    controller.add(
      CaptureTransferProgress(status: .done, fraction: 1, paths: paths),
    );
    unawaited(controller.close());
  }

  void fail(String transferId) {
    final controller = _controller(transferId);
    controller.add(const CaptureTransferProgress(status: .failed));
    unawaited(controller.close());
  }

  StreamController<CaptureTransferProgress> _controller(String transferId) =>
      _follows.putIfAbsent(transferId, StreamController.new);
}

/// Remembers what went on the clipboard.
class FakePaste implements CapturePaste {
  final List<(Uint8List, String)> images = [];

  @override
  Future<bool> putImage(Uint8List image, {required String mimeType}) async {
    images.add((image, mimeType));
    return true;
  }
}
