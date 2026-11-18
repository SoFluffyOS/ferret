import 'dart:async';
import 'dart:typed_data';

import 'package:ferret_mirror_scrcpy/src/adb/adb.dart';

/// The two connections to a running scrcpy server: video first, then
/// control, the order the server accepts them in.
class ScrcpySockets {
  ScrcpySockets._(this._video, this._control, this.video);

  static const int _attempts = 100;
  static const Duration _retryDelay = Duration(milliseconds: 100);

  final AdbConnection _video;
  final AdbConnection _control;

  /// What the server sends on the video socket, from its first byte.
  final Stream<Uint8List> video;

  /// Connects with [dial], which may fail or give a connection that closes
  /// without a byte while the server isn't listening yet: only the
  /// server's first byte proves it is there. So this tries again, as
  /// scrcpy's client does, until [shouldGiveUp] or about ten seconds
  /// passed. Returns null when it gave up.
  static Future<ScrcpySockets?> connect(
    Future<AdbConnection?> Function() dial, {
    required bool Function() shouldGiveUp,
  }) async {
    for (var attempt = 0; attempt < _attempts; attempt++) {
      if (shouldGiveUp()) {
        return null;
      }

      if (await _connectOnce(dial) case final sockets?) {
        return sockets;
      }

      await Future<void>.delayed(_retryDelay);
    }

    return null;
  }

  void sendControl(Uint8List message) => _control.add(message);

  void close() {
    _video.close();
    _control.close();
  }

  static Future<ScrcpySockets?> _connectOnce(
    Future<AdbConnection?> Function() dial,
  ) async {
    final video = await dial();
    if (video == null) {
      return null;
    }

    final firstChunk = Completer<bool>();
    final chunks = StreamController<Uint8List>();
    void settle(bool isServerThere) {
      if (!firstChunk.isCompleted) {
        firstChunk.complete(isServerThere);
      }
    }

    final subscription = video.input.listen(
      (chunk) {
        if (chunk.isNotEmpty) {
          settle(true);
        }
        chunks.add(chunk);
      },
      onError: (Object _) {
        settle(false);
        unawaited(chunks.close());
      },
      onDone: () {
        settle(false);
        unawaited(chunks.close());
      },
    );
    chunks.onCancel = subscription.cancel;

    final isServerThere = await firstChunk.future;
    if (!isServerThere) {
      video.close();
      return null;
    }

    final control = await dial();
    if (control == null) {
      video.close();
      return null;
    }

    // The device's answers (clipboard acknowledgements) aren't used, but
    // must be read so the server never blocks on a full socket.
    control.input.listen((_) {}, onError: (Object _) {});

    return ScrcpySockets._(video, control, chunks.stream);
  }
}
