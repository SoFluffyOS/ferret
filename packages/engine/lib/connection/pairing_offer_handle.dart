import 'dart:async';
import 'dart:typed_data';

import 'package:engine/pairing/pairing.dart';
import 'package:protocol/protocol.dart';

/// A pairing offer this device is showing, as a QR code or link.
class PairingOfferHandle {
  PairingOfferHandle(this.offer, this.uri);

  final PairingOffer offer;
  final Uri uri;
  final Completer<DeviceInfo> _paired = .new();

  Uint8List get secret => Uint8List.fromList(offer.secret);

  DateTime get expiresAt =>
      DateTime.fromMillisecondsSinceEpoch(offer.expiresAtMs.toInt());

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isUsed => _paired.isCompleted;

  /// Completes with the device that paired using this offer.
  Future<DeviceInfo> get paired => _paired.future;

  void complete(DeviceInfo device) {
    if (_paired.isCompleted) {
      return;
    }

    _paired.complete(device);
  }

  /// The text a QR code should hold.
  String get qrText => uri.toString();

  static Uri uriFor(PairingOffer offer) => PairingCodes.offerUri(offer);
}
