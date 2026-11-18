import 'dart:io';

import 'package:interop_localsend/models/models.dart';
import 'package:interop_localsend/server/localsend_offer.dart';
import 'package:interop_localsend/server/localsend_session_end.dart';

/// Decides about incoming offers and stores what arrives. The server does
/// the protocol; the app behind this does the asking and the saving.
abstract interface class LocalSendReceiveDelegate {
  /// Someone offers files. Return the ids of the files to accept, an empty
  /// set when nothing needs uploading (such as a text message that was
  /// read from its preview), or null to decline.
  Future<Set<String>?> onOffer(LocalSendOffer offer);

  /// Where to write [file] while it arrives.
  Future<File> partFile(LocalSendOffer offer, LocalSendFile file);

  /// [receivedBytes] of the whole offer are on disk by now.
  void onProgress(LocalSendOffer offer, int receivedBytes);

  /// [part] holds all of [file], with the announced size and SHA-256
  /// checked. Move it to its final place; throw when that fails.
  Future<void> onFileReceived(
    LocalSendOffer offer,
    LocalSendFile file,
    File part,
  );

  /// The session is over. Not called when this device declined the offer
  /// or cancelled the session itself.
  void onSessionEnded(LocalSendOffer offer, LocalSendSessionEnd end);
}
