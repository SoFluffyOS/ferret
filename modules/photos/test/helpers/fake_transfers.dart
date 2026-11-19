import 'dart:async';

import 'package:photos/photos.dart';

/// Stands in for drop: remembers what a phone sent, and lets a test say
/// how a transfer on the computer ends.
class FakeTransfers implements PhotoTransfers {
  final List<(String, List<String>)> sent = [];
  final Map<String, StreamController<PhotoTransferProgress>> _follows = {};
  var _next = 0;

  @override
  Future<String?> send(String deviceId, List<String> paths) async {
    sent.add((deviceId, paths));
    return 'transfer-${++_next}';
  }

  @override
  Stream<PhotoTransferProgress> follow(String transferId) =>
      _controller(transferId).stream;

  bool isFollowing(String transferId) => _follows.containsKey(transferId);

  void finish(String transferId, List<String> paths) {
    final controller = _controller(transferId);
    controller.add(
      PhotoTransferProgress(status: .done, fraction: 1, paths: paths),
    );
    unawaited(controller.close());
  }

  StreamController<PhotoTransferProgress> _controller(String transferId) =>
      _follows.putIfAbsent(transferId, StreamController.new);
}
