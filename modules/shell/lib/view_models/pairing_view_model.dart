import 'dart:async';

import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';

/// Where a pairing attempt this device started stands.
sealed class PairingState {
  const PairingState();
}

final class PairingIdle extends PairingState {
  const PairingIdle();
}

final class PairingConnecting extends PairingState {
  const PairingConnecting();
}

/// Comparing codes: show [code] while the other device confirms.
final class PairingComparing extends PairingState {
  const PairingComparing(this.code);

  final String code;
}

final class PairingDone extends PairingState {
  const PairingDone(this.outcome);

  final PairingOutcome outcome;
}

/// The pairing screen: this device's QR offer, and pairing with a link or an
/// address someone typed.
class PairingViewModel extends ChangeNotifier {
  PairingViewModel(this._engine);

  final FerretEngine _engine;
  PairingOfferHandle? _offer;
  PairingState _state = const PairingIdle();
  Timer? _ticker;
  bool _disposed = false;

  PairingOfferHandle? get offer => _offer;

  PairingState get state => _state;

  /// Whole minutes left on the offer, rounded up.
  int get minutesLeft {
    final offer = _offer;
    if (offer == null) {
      return 0;
    }

    final seconds = offer.expiresAt.difference(DateTime.now()).inSeconds;
    return ((seconds + 59) ~/ 60).clamp(0, 99);
  }

  /// Shows a fresh offer, replacing the old one.
  Future<void> createOffer() async {
    final offer = await _engine.createPairingOffer();
    if (_disposed) {
      return;
    }

    _offer = offer;
    _ticker?.cancel();
    _ticker = .periodic(const Duration(seconds: 15), (_) => _onTick());
    notifyListeners();

    final device = await offer.paired;
    if (_disposed || _offer != offer) {
      return;
    }

    _setState(PairingDone(Paired(device)));
  }

  /// Pairs from a `ferret://pair` link. Returns false when [text] isn't one.
  bool pairWithLink(String text) {
    final offer = PairingCodes.parseOffer(text);
    if (offer == null) {
      return false;
    }

    _setState(const PairingConnecting());
    unawaited(
      _engine
          .pairWithOffer(offer)
          .then((outcome) => _setState(PairingDone(outcome))),
    );
    return true;
  }

  /// Pairs with `host:port` by comparing codes. Returns false when [address]
  /// isn't one.
  bool pairWithAddress(String address) {
    final parsed = _parseAddress(address);
    if (parsed == null) {
      return false;
    }

    _setState(const PairingConnecting());
    final (host, port) = parsed;
    unawaited(
      _engine
          .pairWithAddress(
            host,
            port,
            onCode: (code) => _setState(PairingComparing(code)),
          )
          .then((outcome) => _setState(PairingDone(outcome))),
    );
    return true;
  }

  void reset() => _setState(const PairingIdle());

  void _onTick() {
    if (_offer?.isExpired ?? false) {
      unawaited(createOffer());
      return;
    }

    notifyListeners();
  }

  void _setState(PairingState state) {
    if (_disposed) {
      return;
    }

    _state = state;
    notifyListeners();
  }

  (String, int)? _parseAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final separator = trimmed.lastIndexOf(':');
    if (separator <= 0) {
      return (trimmed, FerretEngine.defaultPort);
    }

    final port = int.tryParse(trimmed.substring(separator + 1));
    if (port == null || port <= 0 || port > 65535) {
      return null;
    }

    return (trimmed.substring(0, separator), port);
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
