import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:fixnum/fixnum.dart';
import 'package:interop_quickshare/client/quickshare_outgoing_file.dart';
import 'package:interop_quickshare/client/quickshare_send_result.dart';
import 'package:interop_quickshare/connection/connection.dart';
import 'package:interop_quickshare/crypto/crypto.dart';
import 'package:interop_quickshare/discovery/discovery.dart';
import 'package:interop_quickshare/models/models.dart';
import 'package:interop_quickshare/proto/proto.dart';

/// Sends files or a text to one Quick Share receiver: connects, runs the
/// handshake, introduces what it has, waits for the answer, then sends.
///
/// It works with receivers that are reachable over the local network,
/// such as another Ferret or a desktop Quick Share app. Android phones
/// only start listening after a Bluetooth signal this can't give.
class QuickShareSendJob {
  QuickShareSendJob({
    required this.address,
    required this.port,
    required this.sender,
    this.files = const [],
    this.text,
    this.chunkSize = 512 * 1024,
    this.answerTimeout = const Duration(minutes: 2),
    this.timeouts = const QuickShareTimeouts(),
    this.onPin,
    this.onProgress,
  });

  final InternetAddress address;
  final int port;

  /// How this device introduces itself to the receiver.
  final QuickShareEndpointInfo sender;
  final List<QuickShareOutgoingFile> files;

  /// A text to send, alone or with [files].
  final String? text;
  final int chunkSize;

  /// How long the receiver's person gets to answer.
  final Duration answerTimeout;
  final QuickShareTimeouts timeouts;

  /// Called with the PIN both screens should show, once it is known.
  final void Function(String pin)? onPin;

  /// Called with the file bytes sent so far.
  final void Function(int sentBytes)? onProgress;

  QuickShareLink? _link;
  Timer? _keepAlive;
  bool _cancelled = false;

  /// The receiver sent a cancel, at any point.
  bool _receiverCancelled = false;

  /// The receiver hung up. That is fine once everything was sent.
  bool _receiverLeft = false;
  bool _saidGoodbye = false;
  int _sentBytes = 0;
  List<int> _fileIds = const [];
  late final int _textId = QuickShareLink.newPayloadId();

  /// Runs the transfer. Throws a [QuickShareException] when the receiver
  /// can't be reached or breaks the protocol.
  Future<QuickShareSendResult> run() async {
    final link = await _connect();
    _link = link;
    try {
      await _handshake(link);
      _keepAlive = .periodic(timeouts.keepAlive, (_) => link.sendKeepAlive());
      final answer = await _introduce(link);
      if (answer != QuickShareSendResult.sent) {
        return answer;
      }

      return await _sendEverything(link);
    } on Ukey2Exception catch (error) {
      if (error.alertFrame case final alert?) {
        link.writeRaw(alert);
      }

      throw QuickShareException(.handshake, error.message);
    } on QuickShareException {
      if (_cancelled) {
        return .cancelled;
      }

      rethrow;
    } finally {
      _keepAlive?.cancel();
      if (link.isSecure && !_saidGoodbye) {
        link.sendDisconnection();
      }

      await link.close(grace: timeouts.closeGrace);
    }
  }

  /// Stops the transfer and tells the receiver.
  Future<void> cancel() async {
    if (_cancelled) {
      return;
    }

    _cancelled = true;
    final link = _link;
    if (link == null) {
      return;
    }

    if (link.isSecure) {
      _saidGoodbye = true;
      link
        ..sendSharing(SharingFrameV1(type: .CANCEL))
        ..sendDisconnection();
    }

    await link.close();
  }

  Future<QuickShareLink> _connect() async {
    try {
      final socket = await Socket.connect(
        address,
        port,
        timeout: timeouts.handshake,
      );
      socket.setOption(SocketOption.tcpNoDelay, true);
      return QuickShareLink(socket);
    } on SocketException catch (error) {
      printDebug('Quick Share connect failed: ${error.osError?.message}');
      throw const QuickShareException(.unreachable, 'No answer');
    }
  }

  Future<void> _handshake(QuickShareLink link) async {
    final endpointId = QuickShareService.newEndpointId();
    link.send(
      OfflineFrameV1(
        type: .CONNECTION_REQUEST,
        connectionRequest: ConnectionRequest(
          endpointId: endpointId,
          endpointName: sender.name,
          endpointInfo: sender.encode(),
          mediums: const [ConnectionRequest_Medium.WIFI_LAN],
        ),
      ),
    );

    final ukey = Ukey2Client();
    link.writeRaw(ukey.clientInit());
    final serverInit = await link.readRaw(timeouts.handshake);
    if (serverInit == null) {
      throw const QuickShareException(.handshake, 'Closed before the keys');
    }

    final (:clientFinish, :keys) = ukey.finish(serverInit);
    link
      ..writeRaw(clientFinish)
      ..send(
        OfflineFrameV1(
          type: .CONNECTION_RESPONSE,
          connectionResponse: ConnectionResponse(response: .ACCEPT, status: 0),
        ),
      );

    final response = await link.receive(timeouts.handshake);
    final accepted =
        response != null &&
        response.v1.type == OfflineFrameV1_FrameType.CONNECTION_RESPONSE &&
        response.v1.connectionResponse.response !=
            ConnectionResponse_ResponseStatus.REJECT;
    if (!accepted) {
      throw const QuickShareException(.handshake, 'Connection not accepted');
    }

    link.secure(D2DKeys.derive(keys.nextSecret, isServer: false));
    onPin?.call(QuickSharePin.of(keys.authString));
  }

  /// Exchanges the paired key frames, introduces the content and waits
  /// for the answer. Returns [QuickShareSendResult.sent] when the
  /// receiver accepted and sending can start.
  Future<QuickShareSendResult> _introduce(QuickShareLink link) async {
    final fileIds = [for (final _ in files) QuickShareLink.newPayloadId()];
    _fileIds = fileIds;
    link.sendSharing(
      SharingFrameV1(
        type: .PAIRED_KEY_ENCRYPTION,
        pairedKeyEncryption: PairedKeyEncryption(
          signedData: SecureBytes.random(72),
          secretIdHash: SecureBytes.random(6),
        ),
      ),
    );

    final payloads = BytesPayloads();
    final deadline = DateTime.now().add(answerTimeout);
    var introduced = false;
    while (true) {
      final left = deadline.difference(DateTime.now());
      if (left <= Duration.zero) {
        return .timedOut;
      }

      final frame = await _receiveUntil(link, left);
      if (_cancelled) {
        return .cancelled;
      }

      if (frame == null ||
          frame.v1.type == OfflineFrameV1_FrameType.DISCONNECTION) {
        return .cancelledByReceiver;
      }

      final sharing = _sharingOf(frame, payloads);
      switch (sharing?.type) {
        case SharingFrameV1_FrameType.PAIRED_KEY_ENCRYPTION:
          link.sendSharing(
            SharingFrameV1(
              type: .PAIRED_KEY_RESULT,
              pairedKeyResult: PairedKeyResult(status: .UNABLE),
            ),
          );
        case SharingFrameV1_FrameType.PAIRED_KEY_RESULT when !introduced:
          introduced = true;
          link.sendSharing(_introduction(fileIds));
        case SharingFrameV1_FrameType.RESPONSE:
          return switch (sharing?.connectionResponse.status) {
            TransferResponse_Status.ACCEPT => .sent,
            TransferResponse_Status.NOT_ENOUGH_SPACE => .noSpace,
            TransferResponse_Status.UNSUPPORTED_ATTACHMENT_TYPE => .unsupported,
            TransferResponse_Status.TIMED_OUT => .timedOut,
            _ => .declined,
          };
        case SharingFrameV1_FrameType.CANCEL:
          return .cancelledByReceiver;
        default:
          continue;
      }
    }
  }

  /// Waits for the next frame for at most [left], but never longer than
  /// the receiver may stay silent.
  Future<OfflineFrame?> _receiveUntil(QuickShareLink link, Duration left) {
    final wait = switch (left < timeouts.idle) {
      true => left,
      false => timeouts.idle,
    };
    return link.receive(wait);
  }

  SharingFrameV1? _sharingOf(OfflineFrame frame, BytesPayloads payloads) {
    final transfer = frame.v1.payloadTransfer;
    final isBytes =
        frame.v1.type == OfflineFrameV1_FrameType.PAYLOAD_TRANSFER &&
        transfer.packetType == PayloadTransfer_PacketType.DATA &&
        transfer.payloadHeader.type ==
            PayloadTransfer_PayloadHeader_PayloadType.BYTES;
    if (!isBytes) {
      return null;
    }

    final complete = payloads.add(transfer);
    if (complete == null) {
      return null;
    }

    try {
      return SharingFrame.fromBuffer(complete.$2).v1;
    } on Object {
      return null;
    }
  }

  SharingFrameV1 _introduction(List<int> fileIds) => SharingFrameV1(
    type: .INTRODUCTION,
    introduction: Introduction(
      fileMetadata: [
        for (final (index, file) in files.indexed)
          FileMetadata(
            name: file.name,
            payloadId: Int64(fileIds[index]),
            size: Int64(file.size),
            mimeType: file.mimeType,
            type: _kindOf(file.mimeType),
          ),
      ],
      textMetadata: [
        if (text case final content?)
          TextMetadata(
            payloadId: Int64(_textId),
            type: _textKindOf(content),
            size: Int64(utf8.encode(content).length),
            textTitle: _titleOf(content),
          ),
      ],
    ),
  );

  Future<QuickShareSendResult> _sendEverything(QuickShareLink link) async {
    final watching = _watch(link);
    if (text case final content?) {
      link.sendBytes(_textId, utf8.encode(content));
    }

    for (final (index, file) in files.indexed) {
      await _sendFile(link, file, _fileIds[index]);
      if (_cancelled) {
        return .cancelled;
      }

      if (_receiverCancelled || _receiverLeft) {
        return .cancelledByReceiver;
      }
    }

    _saidGoodbye = true;
    link.sendDisconnection();
    await link.flush();
    await watching.timeout(timeouts.closeGrace, onTimeout: () {});
    if (_cancelled) {
      return .cancelled;
    }

    if (_receiverCancelled) {
      return .cancelledByReceiver;
    }

    return .sent;
  }

  Future<void> _sendFile(
    QuickShareLink link,
    QuickShareOutgoingFile file,
    int payloadId,
  ) async {
    final header = PayloadTransfer_PayloadHeader(
      id: Int64(payloadId),
      type: .FILE,
      totalSize: Int64(file.size),
      fileName: file.name,
    );
    var offset = 0;
    await for (final data in file.open()) {
      for (var start = 0; start < data.length; start += chunkSize) {
        if (_cancelled || _receiverCancelled || _receiverLeft) {
          return;
        }

        final end = min(start + chunkSize, data.length);
        final body = Uint8List.sublistView(
          switch (data) {
            final Uint8List bytes => bytes,
            _ => Uint8List.fromList(data),
          },
          start,
          end,
        );
        link.sendChunk(header, offset: offset, body: body);
        offset += body.length;
        _sentBytes += body.length;
        onProgress?.call(_sentBytes);
        await link.flush();
      }
    }

    if (offset != file.size) {
      link.sendSharing(SharingFrameV1(type: .CANCEL));
      throw const QuickShareException(.protocol, 'File changed while sending');
    }

    link.sendChunk(header, offset: offset, isLast: true);
  }

  /// Listens while files go out, so a receiver that cancels or hangs up
  /// stops the sending.
  Future<void> _watch(QuickShareLink link) async {
    final payloads = BytesPayloads();
    try {
      while (true) {
        final frame = await link.receive(timeouts.idle);
        if (frame == null ||
            frame.v1.type == OfflineFrameV1_FrameType.DISCONNECTION) {
          _receiverLeft = true;
          return;
        }

        final sharing = _sharingOf(frame, payloads);
        if (sharing?.type == SharingFrameV1_FrameType.CANCEL) {
          _receiverCancelled = true;
          return;
        }
      }
    } on QuickShareException {
      _receiverLeft = true;
    }
  }

  FileMetadata_Type _kindOf(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return .IMAGE;
    }

    if (mimeType.startsWith('video/')) {
      return .VIDEO;
    }

    if (mimeType.startsWith('audio/')) {
      return .AUDIO;
    }

    return .UNKNOWN;
  }

  TextMetadata_Type _textKindOf(String content) {
    final uri = Uri.tryParse(content.trim());
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      return .URL;
    }

    return .TEXT;
  }

  /// A short preview for the receiver's prompt. Phones do the same.
  String _titleOf(String content) {
    const shown = 32;
    final line = content.trim().split('\n').first;
    if (line.length <= shown) {
      return line;
    }

    return '${line.substring(0, shown)}…';
  }
}
