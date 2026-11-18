import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:interop_quickshare/connection/bytes_payloads.dart';
import 'package:interop_quickshare/connection/frame_reader.dart';
import 'package:interop_quickshare/crypto/crypto.dart';
import 'package:interop_quickshare/models/models.dart';
import 'package:interop_quickshare/proto/proto.dart';

/// One Quick Share TCP connection: length-prefixed frames, in the clear
/// during the handshake and as secure messages after [secure].
///
/// Sends are queued in call order without waiting, so the sequence
/// numbers inside the secure messages always match the order on the
/// wire.
class QuickShareLink {
  QuickShareLink(this._socket) : _reader = FrameReader(_socket) {
    unawaited(_socket.done.catchError((Object _) {}));
  }

  static final _random = Random.secure();

  final Socket _socket;
  final FrameReader _reader;
  SecureMessageCodec? _codec;
  DecodeWorker? _decoder;
  bool _closed = false;

  InternetAddress get remoteAddress => _socket.remoteAddress;

  bool get isSecure => _codec != null;

  bool get isClosed => _closed;

  /// Switches to encrypted frames with [keys], after the handshake.
  void secure(D2DKeys keys) => _codec = SecureMessageCodec(keys);

  /// Like [secure], but what arrives is verified and decrypted on
  /// another isolate, so receiving large files doesn't hold up the app.
  Future<void> secureInBackground(D2DKeys keys) async {
    final decoder = await DecodeWorker.start(keys);
    if (_closed) {
      decoder.stop();
      return;
    }

    _decoder = decoder;
    _codec = SecureMessageCodec(keys);
  }

  /// The next frame as it came off the wire, or null when the other side
  /// closed. Throws a [QuickShareException] with
  /// [QuickShareFailure.timedOut] after [timeout].
  Future<Uint8List?> readRaw(Duration timeout) async {
    try {
      return await _reader.next().timeout(timeout);
    } on TimeoutException {
      throw const QuickShareException(.timedOut, 'No frame in time');
    } on SocketException {
      return null;
    }
  }

  /// The next connection frame, decrypted once the link is secure, or
  /// null when the other side closed.
  Future<OfflineFrame?> receive(Duration timeout) async {
    final raw = await readRaw(timeout);
    if (raw == null) {
      return null;
    }

    final bytes = await _decode(raw);
    try {
      return OfflineFrame.fromBuffer(bytes);
    } on Object {
      throw const QuickShareException(.protocol, 'Unreadable frame');
    }
  }

  Future<Uint8List> _decode(Uint8List raw) async {
    if (_decoder case final decoder?) {
      return decoder.decode(raw);
    }

    if (_codec case final codec?) {
      return codec.decode(raw);
    }

    return raw;
  }

  /// Sends [frame] as it is, for the handshake.
  void writeRaw(List<int> frame) {
    if (_closed) {
      return;
    }

    final length = ByteData(4)..setUint32(0, frame.length);
    try {
      _socket
        ..add(length.buffer.asUint8List())
        ..add(frame);
    } on Object {
      _closed = true;
    }
  }

  /// Sends a connection frame, encrypted once the link is secure.
  void send(OfflineFrameV1 frame) {
    if (_closed) {
      return;
    }

    final bytes = OfflineFrame(version: .V1, v1: frame).writeToBuffer();
    writeRaw(switch (_codec) {
      final codec? => codec.encode(bytes),
      null => bytes,
    });
  }

  /// Sends a sharing frame as a small payload.
  void sendSharing(SharingFrameV1 frame) => sendBytes(
    newPayloadId(),
    SharingFrame(version: .V1, v1: frame).writeToBuffer(),
  );

  /// Sends [bytes] as one payload: a chunk with everything, then an empty
  /// one that marks the end, the way phones do it.
  void sendBytes(int payloadId, List<int> bytes) {
    final header = PayloadTransfer_PayloadHeader(
      id: Int64(payloadId),
      type: .BYTES,
      totalSize: Int64(bytes.length),
    );
    sendChunk(header, offset: 0, body: bytes);
    sendChunk(header, offset: bytes.length, isLast: true);
  }

  /// Sends one chunk of the payload described by [header].
  void sendChunk(
    PayloadTransfer_PayloadHeader header, {
    required int offset,
    List<int> body = const [],
    bool isLast = false,
  }) => send(
    OfflineFrameV1(
      type: .PAYLOAD_TRANSFER,
      payloadTransfer: PayloadTransfer(
        packetType: .DATA,
        payloadHeader: header,
        payloadChunk: PayloadTransfer_PayloadChunk(
          offset: Int64(offset),
          body: body,
          flags: switch (isLast) {
            true => PayloadFlags.lastChunk,
            false => 0,
          },
        ),
      ),
    ),
  );

  void sendKeepAlive() =>
      send(OfflineFrameV1(type: .KEEP_ALIVE, keepAlive: KeepAlive()));

  /// Says goodbye. With [isAnswer], confirms the other side's own
  /// goodbye, for senders that wait for that before they hang up.
  void sendDisconnection({bool isAnswer = false}) => send(
    OfflineFrameV1(
      type: .DISCONNECTION,
      disconnection: switch (isAnswer) {
        true => Disconnection(ackSafeToDisconnect: true),
        false => Disconnection(),
      },
    ),
  );

  /// Waits until everything queued so far left this device.
  Future<void> flush() async {
    if (_closed) {
      return;
    }

    try {
      await _socket.flush();
    } on Object {
      _closed = true;
    }
  }

  /// Sends what is queued, then closes. The other side gets [grace] to
  /// close too before the connection is torn down.
  Future<void> close({Duration grace = Duration.zero}) async {
    if (_closed) {
      return;
    }

    await flush();
    _closed = true;
    _decoder?.stop();
    try {
      await _socket.close();
    } on Object {
      _socket.destroy();
      return;
    }

    if (grace == Duration.zero) {
      _socket.destroy();
      return;
    }

    Timer(grace, _socket.destroy);
  }

  /// A payload id for a frame this side makes up.
  static int newPayloadId() =>
      (_random.nextInt(1 << 31) << 31) | _random.nextInt(1 << 31);
}
