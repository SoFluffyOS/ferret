import 'dart:async';

import 'package:protocol/protocol.dart';

/// Someone wants to pair by comparing codes. The UI shows [code] and [device]
/// and calls [accept] or [reject].
class PairingPrompt {
  PairingPrompt({required this.device, required this.code});

  final DeviceInfo device;
  final String code;
  final Completer<bool> _decision = .new();

  Future<bool> get decision => _decision.future;

  bool get isDecided => _decision.isCompleted;

  void accept() => _decide(true);

  void reject() => _decide(false);

  void _decide(bool accepted) {
    if (_decision.isCompleted) {
      return;
    }

    _decision.complete(accepted);
  }
}

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
}
