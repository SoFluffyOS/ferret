import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// The two connections to a running scrcpy server, through an adb forward:
/// video first, then control, the order the server accepts them in.
class ScrcpySockets {
  ScrcpySockets._(this._video, this._control, this.video);

  static const int _attempts = 100;
  static const Duration _retryDelay = Duration(milliseconds: 100);

  final Socket _video;
  final Socket _control;

  /// What the server sends on the video socket, from its first byte.
  final Stream<Uint8List> video;

  /// Connects to [port] on this computer. A forwarded port accepts a
  /// connection even before the server listens on the device, and then
  /// closes it: only the server's first byte proves it is there. So this
  /// tries again, as scrcpy's client does, until [shouldGiveUp] or about
  /// ten seconds passed. Returns null when it gave up.
  static Future<ScrcpySockets?> connect(
    int port, {
    required bool Function() shouldGiveUp,
  }) async {
    for (var attempt = 0; attempt < _attempts; attempt++) {
      if (shouldGiveUp()) {
        return null;
      }

      if (await _connectOnce(port) case final sockets?) {
        return sockets;
      }

      await Future<void>.delayed(_retryDelay);
    }

    return null;
  }

  void sendControl(Uint8List message) {
    try {
      _control.add(message);
    } on StateError {
      // The socket is closing: the feed is ending anyway.
    }
  }

  Future<void> close() async {
    _video.destroy();
    _control.destroy();
  }

  static Future<ScrcpySockets?> _connectOnce(int port) async {
    final Socket video;
    try {
      video = await Socket.connect(InternetAddress.loopbackIPv4, port);
    } on SocketException {
      return null;
    }

    final firstChunk = Completer<bool>();
    final chunks = StreamController<Uint8List>();
    final subscription = video.listen(
      (chunk) {
        if (!firstChunk.isCompleted) {
          firstChunk.complete(true);
        }
        chunks.add(chunk);
      },
      onError: (Object error) {
        if (!firstChunk.isCompleted) {
          firstChunk.complete(false);
        }
        unawaited(chunks.close());
      },
      onDone: () {
        if (!firstChunk.isCompleted) {
          firstChunk.complete(false);
        }
        unawaited(chunks.close());
      },
    );
    chunks.onCancel = subscription.cancel;

    final isServerThere = await firstChunk.future;
    if (!isServerThere) {
      video.destroy();
      return null;
    }

    final Socket control;
    try {
      control = await Socket.connect(InternetAddress.loopbackIPv4, port);
    } on SocketException {
      video.destroy();
      return null;
    }

    video.setOption(.tcpNoDelay, true);
    control.setOption(.tcpNoDelay, true);
    // The device's answers (clipboard acknowledgements) aren't used, but
    // must be read so the server never blocks on a full socket.
    control.listen((_) {}, onError: (Object _) {}, cancelOnError: true);
    unawaited(control.done.catchError((Object _) => control));

    return ScrcpySockets._(video, control, chunks.stream);
  }
}
