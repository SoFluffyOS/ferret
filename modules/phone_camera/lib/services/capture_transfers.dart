import 'package:phone_camera/models/models.dart';

/// How pictures travel: the app wires this to its file transfer (drop),
/// which brings resume and SHA-256 checks. Features never import each
/// other, so the camera only knows this interface.
abstract interface class CaptureTransfers {
  /// On a phone: sends the temporary file at [path] to [deviceId] and
  /// deletes it once the transfer ends. Returns the transfer's id, or null
  /// when nothing could be sent.
  Future<String?> send(String deviceId, String path);

  /// On a computer: how the transfer [transferId] goes, ending with done
  /// or failed. It is accepted without asking: this computer asked for it.
  Stream<CaptureTransferProgress> follow(String transferId);
}
