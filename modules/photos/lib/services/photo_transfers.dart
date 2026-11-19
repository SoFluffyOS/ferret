import 'package:photos/models/models.dart';

/// How full photos travel: the app wires this to its file transfer (drop),
/// which brings resume and SHA-256 checks. Features never import each
/// other, so photos only knows this interface.
abstract interface class PhotoTransfers {
  /// On a phone: sends the temporary copies at [paths] to [deviceId] and
  /// deletes them once the transfer ends. Returns the transfer's id, or
  /// null when nothing could be sent.
  Future<String?> send(String deviceId, List<String> paths);

  /// On a computer: how the transfer [transferId] goes, ending with done
  /// or failed. It is accepted without asking: this computer asked for it.
  Stream<PhotoTransferProgress> follow(String transferId);
}
