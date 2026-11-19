import 'dart:async';

import 'package:protocol/protocol.dart';

/// Someone wants to pair by comparing codes. The UI shows [code] and [device]
/// and calls [accept] or [reject].
class PairingPrompt {
  PairingPrompt({
    required this.device,
    required this.code,
    required this.expiresAt,
    this.alsoDevices = const [],
  });

  final DeviceInfo device;
  final String code;

  /// When the request gives up waiting for an answer.
  final DateTime expiresAt;

  /// Names of [device]'s other devices, which join along with it.
  final List<String> alsoDevices;

  final Completer<PairingAnswer> _decision = .new();

  /// Whether the user agreed. False as well when the request ended first.
  Future<bool> get decision =>
      _decision.future.then((answer) => answer == .accepted);

  /// How the request ended.
  Future<PairingAnswer> get answer => _decision.future;

  bool get isDecided => _decision.isCompleted;

  void accept() => _decide(.accepted);

  void reject() => _decide(.rejected);

  /// Ends the request because nobody answered in time.
  void expire() => _decide(.expired);

  /// Ends the request because the other device gave up.
  void withdraw() => _decide(.withdrawn);

  void _decide(PairingAnswer answer) {
    if (_decision.isCompleted) {
      return;
    }

    _decision.complete(answer);
  }
}

/// How a [PairingPrompt] ended.
enum PairingAnswer { accepted, rejected, expired, withdrawn }

/// How a pairing attempt ended.
sealed class PairingOutcome {
  const PairingOutcome();
}

final class Paired extends PairingOutcome {
  const Paired(this.device);

  final DeviceInfo device;
}

final class PairingFailed extends PairingOutcome {
  const PairingFailed(this.reason, [this.detail = '']);

  final PairingFailure reason;
  final String detail;
}

enum PairingFailure {
  unreachable,
  rejected,
  expired,
  badProof,

  /// The device that answered isn't the one in the QR code.
  wrongDevice,
  timedOut,
  protocol,

  /// The offer comes from a newer Ferret this one can't talk to. The
  /// failure's detail is that device's name.
  updateThisDevice,

  /// The offer comes from an older Ferret that can't talk to this one. The
  /// failure's detail is that device's name.
  updateOtherDevice,

  /// The user on this device said the codes don't match, or gave up.
  cancelled,
}
