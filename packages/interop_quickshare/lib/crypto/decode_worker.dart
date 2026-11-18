import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:interop_quickshare/crypto/d2d_keys.dart';
import 'package:interop_quickshare/crypto/secure_message_codec.dart';
import 'package:interop_quickshare/models/models.dart';

/// Verifies and decrypts incoming secure messages on another isolate.
///
/// A file arrives as hundreds of large encrypted chunks. Decrypting them
/// in pure Dart takes long enough to make an app's interface stutter, so
/// a receiver hands that work to a worker and stays responsive.
class DecodeWorker {
  DecodeWorker._(this._isolate, this._replies, this._requests) {
    _replies.listen(_onReply);
  }

  /// Starts a worker that decodes with the receiving half of [keys].
  static Future<DecodeWorker> start(D2DKeys keys) async {
    final replies = ReceivePort();
    final ready = Completer<SendPort>();
    final handshake = ReceivePort();
    handshake.listen((message) {
      if (message case final SendPort port when !ready.isCompleted) {
        ready.complete(port);
      }
    });

    final isolate = await Isolate.spawn(_run, (
      handshake.sendPort,
      replies.sendPort,
      TransferableTypedData.fromList([keys.decryptKey]),
      TransferableTypedData.fromList([keys.verifyKey]),
    ), onExit: replies.sendPort);
    final requests = await ready.future;
    handshake.close();
    return DecodeWorker._(isolate, replies, requests);
  }

  final Isolate _isolate;
  final ReceivePort _replies;
  final SendPort _requests;
  Completer<Uint8List>? _pending;
  bool _stopped = false;

  /// Verifies and decrypts one secure message, and returns the frame
  /// inside. Messages must be given in the order they arrived, one at a
  /// time. Throws a [QuickShareException] when the message fails its
  /// checks or the worker is gone.
  Future<Uint8List> decode(Uint8List secureMessage) {
    if (_stopped || _pending != null) {
      throw const QuickShareException(.protocol, 'Decoder not ready');
    }

    final pending = Completer<Uint8List>();
    _pending = pending;
    _requests.send(TransferableTypedData.fromList([secureMessage]));
    return pending.future;
  }

  void stop() {
    if (_stopped) {
      return;
    }

    _stopped = true;
    _replies.close();
    _isolate.kill(priority: Isolate.immediate);
    _fail('Decoder stopped');
  }

  void _onReply(Object? message) {
    if (message case final TransferableTypedData frame) {
      final pending = _pending;
      _pending = null;
      pending?.complete(frame.materialize().asUint8List());
      return;
    }

    if (message case final String reason) {
      final pending = _pending;
      _pending = null;
      pending?.completeError(QuickShareException(.tampered, reason));
      return;
    }

    // The isolate exited.
    _stopped = true;
    _replies.close();
    _fail('Decoder gone');
  }

  void _fail(String reason) {
    final pending = _pending;
    _pending = null;
    pending?.completeError(QuickShareException(.protocol, reason));
  }

  static void _run(
    (SendPort, SendPort, TransferableTypedData, TransferableTypedData) setup,
  ) {
    final (handshake, replies, decryptKey, verifyKey) = setup;
    final empty = Uint8List(0);
    final codec = SecureMessageCodec(
      D2DKeys(
        encryptKey: empty,
        signKey: empty,
        decryptKey: decryptKey.materialize().asUint8List(),
        verifyKey: verifyKey.materialize().asUint8List(),
      ),
    );
    final requests = ReceivePort();
    requests.listen((message) {
      if (message is! TransferableTypedData) {
        return;
      }

      try {
        final frame = codec.decode(message.materialize().asUint8List());
        replies.send(TransferableTypedData.fromList([frame]));
      } on QuickShareException catch (error) {
        replies.send(error.message);
      }
    });
    handshake.send(requests.sendPort);
  }
}
