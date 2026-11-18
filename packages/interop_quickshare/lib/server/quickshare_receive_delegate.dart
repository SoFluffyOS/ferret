import 'dart:io';

import 'package:interop_quickshare/models/models.dart';
import 'package:interop_quickshare/server/quickshare_offer.dart';
import 'package:interop_quickshare/server/quickshare_session_end.dart';

/// Decides about incoming offers and stores what arrives. The server
/// does the protocol; the app behind this does the asking and the saving.
abstract interface class QuickShareReceiveDelegate {
  /// Someone offers files or text. Return whether to take them. The
  /// answer may take as long as a person needs; when the sender gives up
  /// first, [onSessionEnded] is called while this is still open.
  Future<bool> onOffer(QuickShareOffer offer);

  /// Where to write [file] while it arrives.
  Future<File> partFile(QuickShareOffer offer, QuickShareFile file);

  /// [receivedBytes] of the offer's files are on disk by now.
  void onProgress(QuickShareOffer offer, int receivedBytes);

  /// [part] holds all of [file], with the announced size checked. Move
  /// it to its final place; throw when that fails.
  Future<void> onFileReceived(
    QuickShareOffer offer,
    QuickShareFile file,
    File part,
  );

  /// The [content] of [text] arrived.
  void onTextReceived(
    QuickShareOffer offer,
    QuickShareText text,
    String content,
  );

  /// The session is over. Not called when this device declined the offer
  /// or cancelled the session itself.
  void onSessionEnded(QuickShareOffer offer, QuickShareSessionEnd end);
}
