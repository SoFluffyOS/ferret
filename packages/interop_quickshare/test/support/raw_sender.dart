import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:interop_quickshare/interop_quickshare.dart';

import 'loopback.dart';

/// A sender driven step by step, to do what a well-behaved one never
/// would.
class RawSender {
  RawSender._(this.socket, this.link);

  static Future<RawSender> connect(QuickShareServer server) async {
    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      server.boundPort ?? 0,
    );
    return RawSender._(socket, QuickShareLink(socket));
  }

  final Socket socket;
  final QuickShareLink link;
  final BytesPayloads _payloads = BytesPayloads();

  /// Opens the connection up to the encrypted part and returns the PIN.
  Future<String> handshake() async {
    link.send(
      OfflineFrameV1(
        type: .CONNECTION_REQUEST,
        connectionRequest: ConnectionRequest(
          endpointId: 'TEST',
          endpointInfo: const QuickShareEndpointInfo(
            name: 'Raw',
            kind: .phone,
          ).encode(),
        ),
      ),
    );
    final ukey = Ukey2Client();
    link.writeRaw(ukey.clientInit());
    final serverInit = await link.readRaw(fastTimeouts.handshake);
    final (:clientFinish, :keys) = ukey.finish(serverInit ?? hex(''));
    link
      ..writeRaw(clientFinish)
      ..send(
        OfflineFrameV1(
          type: .CONNECTION_RESPONSE,
          connectionResponse: ConnectionResponse(response: .ACCEPT),
        ),
      );
    await link.receive(fastTimeouts.handshake);
    link.secure(D2DKeys.derive(keys.nextSecret, isServer: false));
    return QuickSharePin.of(keys.authString);
  }

  /// Introduces one file of [size] bytes and returns its payload header.
  PayloadTransfer_PayloadHeader introduce(int size, {int payloadId = 42}) {
    link.sendSharing(
      SharingFrameV1(
        type: .INTRODUCTION,
        introduction: Introduction(
          fileMetadata: [
            FileMetadata(
              name: 'raw.bin',
              payloadId: Int64(payloadId),
              size: Int64(size),
            ),
          ],
        ),
      ),
    );
    return PayloadTransfer_PayloadHeader(
      id: Int64(payloadId),
      type: .FILE,
      totalSize: Int64(size),
    );
  }

  /// Reads until a sharing frame of [type] arrives. Returns null when
  /// the connection ends first.
  Future<SharingFrameV1?> waitFor(SharingFrameV1_FrameType type) async {
    while (true) {
      final frame = await link.receive(fastTimeouts.idle);
      if (frame == null) {
        return null;
      }

      if (frame.v1.type != OfflineFrameV1_FrameType.PAYLOAD_TRANSFER) {
        continue;
      }

      final complete = _payloads.add(frame.v1.payloadTransfer);
      if (complete == null) {
        continue;
      }

      final sharing = SharingFrame.fromBuffer(complete.$2).v1;
      if (sharing.type == type) {
        return sharing;
      }
    }
  }

  Future<void> close() async {
    await link.close();
  }
}
