import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:transport/channel/byte_connection.dart';
import 'package:transport/framing/framing.dart';
import 'package:transport/noise/noise.dart';

/// Bound into every handshake, so a Ferret handshake can never be replayed
/// into another protocol or another protocol version.
final List<int> ferretPrologue = utf8.encode('ferret/1');

/// An encrypted, authenticated message channel over a [ByteConnection],
/// set up with a Noise XX handshake.
///
/// Messages can be any size up to [maxMessageLength]; they are split into
/// Noise transport messages of at most 65535 bytes on the wire.
class SecureChannel {
  SecureChannel._(this._connection, this._reader, NoiseHandshakeResult result)
    : remoteStaticKey = result.remoteStaticKey,
      handshakeHash = result.handshakeHash,
      _send = result.send,
      _receive = result.receive {
    unawaited(_readLoop());
  }

  static const maxMessageLength = 64 * 1024 * 1024;
  static const _closeGrace = Duration(seconds: 2);

  /// The longest message this channel takes in before it closes. Starts at
  /// [maxMessageLength]; a device that isn't trusted yet gets less.
  int messageLimit = maxMessageLength;
  static const _segmentPayload =
      FrameReader.maxFrameLength - NoiseCrypto.tagLength - 1;
  static const _lastSegment = 0;
  static const _moreSegments = 1;

  /// Runs the handshake as the side that connected.
  static Future<SecureChannel> initiate(
    ByteConnection connection,
    SimpleKeyPair staticKeyPair, {
    Duration timeout = const Duration(seconds: 10),
  }) => _handshake(connection, staticKeyPair, initiator: true).timeout(timeout);

  /// Runs the handshake as the side that accepted the connection.
  static Future<SecureChannel> respond(
    ByteConnection connection,
    SimpleKeyPair staticKeyPair, {
    Duration timeout = const Duration(seconds: 10),
  }) =>
      _handshake(connection, staticKeyPair, initiator: false).timeout(timeout);

  static Future<SecureChannel> _handshake(
    ByteConnection connection,
    SimpleKeyPair staticKeyPair, {
    required bool initiator,
  }) async {
    final reader = FrameReader(connection.input);
    final handshake = await NoiseXXHandshake.create(
      initiator: initiator,
      staticKeyPair: staticKeyPair,
      prologue: ferretPrologue,
    );

    try {
      while (!handshake.isFinished) {
        if (handshake.isMyTurn) {
          connection.add(encodeFrame(await handshake.writeMessage()));
          await connection.flush();
          continue;
        }

        final frame = await reader.next();
        if (frame == null) {
          throw const NoiseHandshakeException(
            'Connection closed during the handshake.',
          );
        }

        await handshake.readMessage(frame);
      }
    } catch (_) {
      await reader.cancel();
      await connection.close();
      rethrow;
    }

    return SecureChannel._(connection, reader, await handshake.finish());
  }

  final ByteConnection _connection;
  final FrameReader _reader;
  final NoiseCipherState _send;
  final NoiseCipherState _receive;
  late final StreamController<Uint8List> _messages = .new(
    onResume: _resumeReading,
    onCancel: _resumeReading,
  );
  Completer<void>? _paused;
  final Completer<void> _done = .new();
  Future<void> _sendQueue = Future.value();
  bool _closed = false;

  /// The other side's static public key: who they are.
  final Uint8List remoteStaticKey;

  /// Unique to this session, for binding pairing proofs to it.
  final Uint8List handshakeHash;

  String get remoteAddress => _connection.remoteAddress;

  ByteConnection get connection => _connection;

  /// Decrypted messages, in order. Closes when the channel closes.
  Stream<Uint8List> get messages => _messages.stream;

  /// Completes when the channel has closed, for any reason.
  Future<void> get done => _done.future;

  bool get isClosed => _closed;

  /// Encrypts and sends [message]. Sends are kept in order.
  Future<void> send(List<int> message) {
    if (_closed) {
      return Future.error(StateError('Channel is closed.'));
    }

    if (message.length > maxMessageLength) {
      return Future.error(
        ArgumentError.value(message.length, 'message', 'Message too long'),
      );
    }

    final sent = _sendQueue.then((_) => _write(message));
    _sendQueue = sent.catchError((Object _) {});
    return sent;
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;
    _resumeReading();
    // A write into a link that died without a word never finishes, so
    // closing waits for queued sends only briefly; the socket close below
    // gives up on them.
    await _sendQueue.timeout(_closeGrace, onTimeout: () {});
    await _reader.cancel();
    await _connection.close();
    await _finish();
  }

  Future<void> _write(List<int> message) async {
    var offset = 0;
    do {
      final end = switch (message.length - offset > _segmentPayload) {
        true => offset + _segmentPayload,
        false => message.length,
      };
      final marker = switch (end == message.length) {
        true => _lastSegment,
        false => _moreSegments,
      };

      final segment = Uint8List(end - offset + 1)
        ..[0] = marker
        ..setRange(1, end - offset + 1, message, offset);
      _connection.add(
        encodeFrame(await _send.encryptWithAd(const [], segment)),
      );
      offset = end;
    } while (offset < message.length);

    await _connection.flush();
  }

  Future<void> _readLoop() async {
    final message = BytesBuilder(copy: false);
    try {
      while (true) {
        await _whilePaused();
        final frame = await _reader.next();
        if (frame == null) {
          break;
        }

        final segment = await _receive.decryptWithAd(const [], frame);
        if (segment.isEmpty) {
          throw const FramingException('Empty segment.');
        }

        message.add(Uint8List.sublistView(segment, 1));
        if (message.length > messageLimit) {
          throw const FramingException('Message too long.');
        }

        if (segment[0] == _lastSegment) {
          _messages.add(message.takeBytes());
        }
      }
    } on Object catch (error, stackTrace) {
      if (!_closed) {
        _messages.addError(error, stackTrace);
      }
    }

    _closed = true;
    await _connection.close();
    await _finish();
  }

  /// Stops reading while the listener is paused, so a peer that sends
  /// faster than this side handles fills the socket, not memory.
  Future<void> _whilePaused() async {
    while (_messages.hasListener && _messages.isPaused && !_closed) {
      final paused = _paused ??= Completer<void>();
      await paused.future;
    }
  }

  void _resumeReading() {
    final paused = _paused;
    _paused = null;
    if (paused != null && !paused.isCompleted) {
      paused.complete();
    }
  }

  Future<void> _finish() async {
    if (_done.isCompleted) {
      return;
    }

    _done.complete();
    // Its future waits for a listener to see the end, and there may be none.
    unawaited(_messages.close());
  }
}
