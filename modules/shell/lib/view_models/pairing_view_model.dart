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

/// Comparing codes: show [code]. [confirmedHere] once the user here said
/// they match and only the other device is left to answer.
final class PairingComparing extends PairingState {
  const PairingComparing(this.code, {this.confirmedHere = false});

  final String code;
  final bool confirmedHere;
}

final class PairingDone extends PairingState {
  const PairingDone(this.outcome);

  final PairingOutcome outcome;
}

/// The other ways to pair: this device's QR offer, and pairing with a link
/// or an address someone typed.
class PairingViewModel extends ChangeNotifier {
  PairingViewModel(this._engine);

  final FerretEngine _engine;
  PairingOfferHandle? _offer;
  PairingState _state = const PairingIdle();
  Timer? _ticker;
  Completer<bool>? _decision;
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

    _decision?.complete(false);
    final decision = Completer<bool>();
    _decision = decision;
    _setState(const PairingConnecting());
    final (host, port) = parsed;
    unawaited(
      _engine
          .pairWithAddress(
            host,
            port,
            onCode: (code) {
              _setState(PairingComparing(code));
              return decision.future;
            },
          )
          .then((outcome) => _onAddressOutcome(decision, outcome)),
    );
    return true;
  }

  /// The user saw the same code on the other device.
  void confirm() {
    final (state, decision) = (_state, _decision);
    if (state is! PairingComparing ||
        decision == null ||
        decision.isCompleted) {
      return;
    }

    decision.complete(true);
    _setState(PairingComparing(state.code, confirmedHere: true));
  }

  /// Gives up on comparing: the codes differ, or the user changed their
  /// mind.
  void cancel() {
    final decision = _decision;
    if (decision == null || decision.isCompleted) {
      return;
    }

    decision.complete(false);
  }

  void reset() => _setState(const PairingIdle());

  void _onAddressOutcome(Completer<bool> decision, PairingOutcome outcome) {
    if (!decision.isCompleted) {
      decision.complete(false);
    }

    if (_decision != decision) {
      return;
    }

    _decision = null;
    final state = switch (outcome) {
      PairingFailed(reason: .cancelled) => const PairingIdle(),
      _ => PairingDone(outcome),
    };
    _setState(state);
  }

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
    cancel();
    _ticker?.cancel();
    super.dispose();
  }
}
