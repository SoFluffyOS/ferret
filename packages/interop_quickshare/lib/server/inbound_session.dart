import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:interop_quickshare/connection/connection.dart';
import 'package:interop_quickshare/crypto/crypto.dart';
import 'package:interop_quickshare/discovery/discovery.dart';
import 'package:interop_quickshare/models/models.dart';
import 'package:interop_quickshare/proto/proto.dart';
import 'package:interop_quickshare/server/incoming_file.dart';
import 'package:interop_quickshare/server/quickshare_offer.dart';
import 'package:interop_quickshare/server/quickshare_receive_delegate.dart';
import 'package:interop_quickshare/server/quickshare_session_end.dart';

/// One sender connected to the server, from its first frame to the last
/// file: the handshake, the offer, the answer, then the payloads.
class InboundSession {
  InboundSession({
    required this.id,
    required Socket socket,
    required this.delegate,
    this.timeouts = const QuickShareTimeouts(),
  }) : _link = QuickShareLink(socket);

  static const maxAttachments = 2000;
  static const _pairedKeySignedLength = 72;
  static const _pairedKeyHashLength = 6;
  static const _fallbackName = 'Quick Share';

  final String id;
  final QuickShareReceiveDelegate delegate;
  final QuickShareTimeouts timeouts;

  final QuickShareLink _link;
  final BytesPayloads _payloads = BytesPayloads();
  final Map<int, IncomingFile> _files = {};
  final Map<int, QuickShareText> _texts = {};
  QuickShareOffer? _offer;
  String _pin = '';
  _Phase _phase = .opening;
  Timer? _keepAlive;

  /// Whether the sender asked to be told when it is safe to hang up.
  bool _goodbyeWanted = false;
  int _receivedBytes = 0;

  /// Whether the delegate was told how this session ended, or must not
  /// be because this device ended it.
  bool _settled = false;

  /// Whether an offer is waiting for an answer or payloads are arriving.
  bool get isBusy => _phase == .asking || _phase == .receiving;

  /// Runs the session until the connection is over. Never throws.
  Future<void> run() async {
    try {
      final sender = await _handshake();
      _keepAlive = .periodic(timeouts.keepAlive, (_) => _link.sendKeepAlive());
      _sendPairedKeyEncryption();
      await _pump(sender);
    } on Ukey2Exception catch (error) {
      printDebug('Quick Share handshake failed: ${error.message}');
      if (error.alertFrame case final alert?) {
        _link.writeRaw(alert);
      }
    } on QuickShareException catch (error) {
      _onStopped(error);
    } on FileSystemException catch (error) {
      printWarning('Quick Share could not write a file', error.osError);
      _settle(.storageFailed);
      _sendCancel();
    } on Object catch (error) {
      printWarning('Quick Share session failed: ${error.runtimeType}');
      _settle(.protocolError);
    } finally {
      await _shutDown();
    }
  }

  /// The connection broke or the sender broke the rules. Once this side
  /// hung up, what still fails on the way out means nothing.
  void _onStopped(QuickShareException error) {
    if (_phase == .closed) {
      return;
    }

    printDebug('Quick Share session stopped: ${error.failure.name}');
    _settle(switch (error.failure) {
      .timedOut || .unreachable => .connectionLost,
      .handshake || .tampered || .protocol => .protocolError,
    });
  }

  /// Ends the session from this device: a waiting offer is taken as
  /// declined, a running transfer is cancelled.
  Future<void> cancel() async {
    if (_phase == .closed) {
      return;
    }

    _settled = true;
    _sendCancel();
    await _shutDown();
  }

  Future<QuickShareEndpointInfo> _handshake() async {
    final request = await _link.receive(timeouts.handshake);
    if (request == null ||
        request.v1.type != OfflineFrameV1_FrameType.CONNECTION_REQUEST) {
      throw const QuickShareException(.handshake, 'No connection request');
    }

    final ukey = Ukey2Server();
    final clientInit = await _link.readRaw(timeouts.handshake);
    if (clientInit == null) {
      throw const QuickShareException(.handshake, 'Closed before the keys');
    }

    _link.writeRaw(ukey.serverInit(clientInit));
    final clientFinish = await _link.readRaw(timeouts.handshake);
    if (clientFinish == null) {
      throw const QuickShareException(.handshake, 'Closed before the keys');
    }

    final keys = ukey.finish(clientFinish);
    _pin = QuickSharePin.of(keys.authString);
    _link.send(
      OfflineFrameV1(
        type: .CONNECTION_RESPONSE,
        connectionResponse: ConnectionResponse(
          response: .ACCEPT,
          status: 0,
          osInfo: OsInfo(type: _osType),
        ),
      ),
    );

    final response = await _link.receive(timeouts.handshake);
    if (response == null || !_accepts(response)) {
      throw const QuickShareException(.handshake, 'Connection not accepted');
    }

    await _link.secureInBackground(
      D2DKeys.derive(keys.nextSecret, isServer: true),
    );
    if (_phase == .closed) {
      throw const QuickShareException(.handshake, 'Cancelled');
    }

    _phase = .negotiating;
    return _senderOf(request.v1.connectionRequest);
  }

  bool _accepts(OfflineFrame frame) {
    if (frame.v1.type != OfflineFrameV1_FrameType.CONNECTION_RESPONSE) {
      return false;
    }

    final response = frame.v1.connectionResponse;
    if (response.hasResponse()) {
      return response.response == ConnectionResponse_ResponseStatus.ACCEPT;
    }

    return response.status == 0;
  }

  QuickShareEndpointInfo _senderOf(ConnectionRequest request) {
    if (QuickShareEndpointInfo.decode(request.endpointInfo) case final info?
        when info.name.trim().isNotEmpty) {
      return info;
    }

    final name = request.endpointName.trim();
    return QuickShareEndpointInfo(
      name: switch (name.isEmpty) {
        true => _fallbackName,
        false => name,
      },
    );
  }

  Future<void> _pump(QuickShareEndpointInfo sender) async {
    while (_phase != .closed) {
      final frame = await _link.receive(timeouts.idle);
      if (_phase == .closed) {
        return;
      }

      if (frame == null) {
        _settle(_endWithoutGoodbye);
        return;
      }

      final goOn = await _onFrame(frame.v1, sender);
      if (!goOn) {
        return;
      }
    }
  }

  /// What a connection that just dropped means: a sender that walks away
  /// from its own offer cancelled it; one that vanishes mid-file is lost.
  QuickShareSessionEnd get _endWithoutGoodbye => switch (_phase) {
    .receiving => .connectionLost,
    _ => .cancelledBySender,
  };

  /// Handles one frame. Returns false when the session is over.
  Future<bool> _onFrame(
    OfflineFrameV1 frame,
    QuickShareEndpointInfo sender,
  ) async {
    switch (frame.type) {
      case OfflineFrameV1_FrameType.DISCONNECTION:
        _goodbyeWanted = frame.disconnection.requestSafeToDisconnect;
        _settle(.cancelledBySender);
        return false;
      case OfflineFrameV1_FrameType.PAYLOAD_TRANSFER:
        return _onPayload(frame.payloadTransfer, sender);
      default:
        return true;
    }
  }

  Future<bool> _onPayload(
    PayloadTransfer transfer,
    QuickShareEndpointInfo sender,
  ) async {
    if (transfer.packetType == PayloadTransfer_PacketType.CONTROL) {
      return _onControl(transfer);
    }

    if (transfer.packetType != PayloadTransfer_PacketType.DATA) {
      return true;
    }

    if (transfer.payloadHeader.type ==
        PayloadTransfer_PayloadHeader_PayloadType.FILE) {
      return _onFileChunk(transfer);
    }

    if (transfer.payloadHeader.type !=
        PayloadTransfer_PayloadHeader_PayloadType.BYTES) {
      return true;
    }

    final complete = _payloads.add(transfer);
    if (complete == null) {
      return true;
    }

    final (payloadId, bytes) = complete;
    if (_texts.remove(payloadId) case final text?) {
      return _onText(text, bytes);
    }

    return _onSharing(bytes, sender);
  }

  bool _onControl(PayloadTransfer transfer) {
    final stops = switch (transfer.controlMessage.event) {
      PayloadTransfer_ControlMessage_EventType.PAYLOAD_CANCELED ||
      PayloadTransfer_ControlMessage_EventType.PAYLOAD_ERROR => true,
      _ => false,
    };
    final payloadId = transfer.payloadHeader.id.toInt();
    final wanted =
        _files[payloadId]?.isDone == false || _texts.containsKey(payloadId);
    if (!stops || !wanted) {
      return true;
    }

    _settle(.cancelledBySender);
    return false;
  }

  Future<bool> _onSharing(
    List<int> bytes,
    QuickShareEndpointInfo sender,
  ) async {
    final SharingFrameV1 frame;
    try {
      frame = SharingFrame.fromBuffer(bytes).v1;
    } on Object {
      // Phones may send payloads this side has no use for.
      return true;
    }

    switch (frame.type) {
      case SharingFrameV1_FrameType.PAIRED_KEY_ENCRYPTION:
        _link.sendSharing(
          SharingFrameV1(
            type: .PAIRED_KEY_RESULT,
            pairedKeyResult: PairedKeyResult(status: .UNABLE),
          ),
        );
        return true;
      case SharingFrameV1_FrameType.INTRODUCTION:
        return _onIntroduction(frame.introduction, sender);
      case SharingFrameV1_FrameType.CANCEL:
        _settle(.cancelledBySender);
        return false;
      default:
        return true;
    }
  }

  bool _onIntroduction(
    Introduction introduction,
    QuickShareEndpointInfo sender,
  ) {
    if (_phase != .negotiating) {
      return true;
    }

    final offer = _offerFrom(introduction, sender);
    if (offer.files.isEmpty && offer.texts.isEmpty) {
      _settled = true;
      _respond(.UNSUPPORTED_ATTACHMENT_TYPE);
      return false;
    }

    for (final file in offer.files) {
      _files[file.payloadId] = IncomingFile(file);
    }

    for (final text in offer.texts) {
      _texts[text.payloadId] = text;
    }

    _offer = offer;
    _phase = .asking;
    unawaited(_ask(offer));
    return true;
  }

  QuickShareOffer _offerFrom(
    Introduction introduction,
    QuickShareEndpointInfo sender,
  ) {
    final count =
        introduction.fileMetadata.length + introduction.textMetadata.length;
    if (count > maxAttachments) {
      throw const QuickShareException(.protocol, 'Too many attachments');
    }

    final payloadIds = <int>{};
    final files = [
      for (final file in introduction.fileMetadata)
        QuickShareFile(
          payloadId: file.payloadId.toInt(),
          name: file.name,
          size: file.size.toInt(),
          parentFolder: file.parentFolder,
          mimeType: switch (file.mimeType.isEmpty) {
            true => 'application/octet-stream',
            false => file.mimeType,
          },
        ),
    ];
    final texts = [
      for (final text in introduction.textMetadata)
        QuickShareText(
          payloadId: text.payloadId.toInt(),
          kind: switch (text.type) {
            TextMetadata_Type.URL => .url,
            TextMetadata_Type.ADDRESS => .address,
            TextMetadata_Type.PHONE_NUMBER => .phoneNumber,
            _ => .text,
          },
          size: text.size.toInt(),
          title: text.textTitle,
        ),
    ];
    final ids = [
      for (final file in files) file.payloadId,
      for (final text in texts) text.payloadId,
    ];
    if (files.any((file) => file.size < 0) || !ids.every(payloadIds.add)) {
      throw const QuickShareException(.protocol, 'Bad introduction');
    }

    return QuickShareOffer(
      sessionId: id,
      senderName: sender.name,
      senderKind: sender.kind,
      pin: _pin,
      address: _link.remoteAddress,
      files: files,
      texts: texts,
    );
  }

  Future<void> _ask(QuickShareOffer offer) async {
    var accepted = false;
    try {
      accepted = await delegate.onOffer(offer);
    } on Object catch (error) {
      printWarning('Quick Share offer failed: ${error.runtimeType}');
    }

    if (_phase != .asking) {
      return;
    }

    if (!accepted) {
      _settled = true;
      _respond(.REJECT);
      await _shutDown();
      return;
    }

    _phase = .receiving;
    _respond(.ACCEPT);
  }

  void _respond(TransferResponse_Status status) => _link.sendSharing(
    SharingFrameV1(
      type: .RESPONSE,
      connectionResponse: TransferResponse(status: status),
    ),
  );

  Future<bool> _onFileChunk(PayloadTransfer transfer) async {
    final incoming = _files[transfer.payloadHeader.id.toInt()];
    final offer = _offer;
    if (incoming == null || offer == null || incoming.isDone) {
      return true;
    }

    if (_phase != .receiving) {
      throw const QuickShareException(.protocol, 'File before the answer');
    }

    final chunk = transfer.payloadChunk;
    final fits =
        chunk.body.isEmpty ||
        (chunk.offset.toInt() == incoming.received &&
            incoming.received + chunk.body.length <= incoming.file.size);
    if (!fits) {
      throw const QuickShareException(.protocol, 'Chunk out of place');
    }

    if (!incoming.isOpen) {
      final part = await delegate.partFile(offer, incoming.file);
      if (_phase != .receiving) {
        return false;
      }

      await incoming.open(part);
    }

    if (chunk.body.isNotEmpty) {
      await incoming.write(chunk.body);
      _receivedBytes += chunk.body.length;
      if (_phase != .receiving) {
        return false;
      }

      delegate.onProgress(offer, _receivedBytes);
    }

    if (chunk.flags & PayloadFlags.lastChunk == 0) {
      return true;
    }

    return _onFileEnd(offer, incoming);
  }

  Future<bool> _onFileEnd(QuickShareOffer offer, IncomingFile incoming) async {
    await incoming.close();
    final part = incoming.part;
    if (part == null || incoming.received != incoming.file.size) {
      _settle(.incomplete);
      _sendCancel();
      return false;
    }

    try {
      await delegate.onFileReceived(offer, incoming.file, part);
    } on Object catch (error) {
      printWarning('Quick Share could not save a file: ${error.runtimeType}');
      _settle(.storageFailed);
      _sendCancel();
      return false;
    }

    if (_phase != .receiving) {
      return false;
    }

    incoming.isDone = true;
    return _checkFinished();
  }

  bool _onText(QuickShareText text, List<int> bytes) {
    final offer = _offer;
    if (offer == null || _phase != .receiving) {
      throw const QuickShareException(.protocol, 'Text before the answer');
    }

    delegate.onTextReceived(
      offer,
      text,
      utf8.decode(bytes, allowMalformed: true),
    );
    return _checkFinished();
  }

  /// Whether more is expected. Once everything arrived, this side says
  /// goodbye and hangs up, which is what tells a phone it is done.
  bool _checkFinished() {
    final waiting =
        _texts.isNotEmpty || _files.values.any((file) => !file.isDone);
    if (waiting) {
      return true;
    }

    _settle(.finished);
    return false;
  }

  void _settle(QuickShareSessionEnd end) {
    final offer = _offer;
    if (_settled || offer == null) {
      return;
    }

    _settled = true;
    delegate.onSessionEnded(offer, end);
  }

  void _sendPairedKeyEncryption() => _link.sendSharing(
    SharingFrameV1(
      type: .PAIRED_KEY_ENCRYPTION,
      pairedKeyEncryption: PairedKeyEncryption(
        signedData: SecureBytes.random(_pairedKeySignedLength),
        secretIdHash: SecureBytes.random(_pairedKeyHashLength),
      ),
    ),
  );

  void _sendCancel() {
    if (!_link.isSecure || _link.isClosed) {
      return;
    }

    _link.sendSharing(SharingFrameV1(type: .CANCEL));
  }

  Future<void> _shutDown() async {
    if (_phase == .closed) {
      return;
    }

    _phase = .closed;
    _keepAlive?.cancel();
    for (final incoming in _files.values) {
      try {
        await incoming.close();
      } on FileSystemException {
        continue;
      }
    }

    if (_link.isSecure) {
      _link.sendDisconnection(isAnswer: _goodbyeWanted);
    }

    await _link.close(grace: timeouts.closeGrace);
  }

  static OsInfo_OsType get _osType {
    if (Platform.isMacOS || Platform.isIOS) {
      return .APPLE;
    }

    if (Platform.isWindows) {
      return .WINDOWS;
    }

    if (Platform.isAndroid) {
      return .ANDROID;
    }

    return .LINUX;
  }
}

enum _Phase { opening, negotiating, asking, receiving, closed }
