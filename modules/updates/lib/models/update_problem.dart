import 'package:ferret_updates/ferret_updates.dart';

/// Why the last check or install didn't work.
enum UpdateProblem {
  checkFailed,
  noFile,
  downloadFailed,
  checksumMissing,
  checksumMismatch,
  notSigned,
  wrongPublisher,
  notNotarized,
  unsignedHere,
  installFailed;

  static UpdateProblem refused(RefusalReason reason) => switch (reason) {
    .checksumMissing => checksumMissing,
    .checksumMismatch => checksumMismatch,
    .notSigned => notSigned,
    .wrongPublisher => wrongPublisher,
    .notNotarized => notNotarized,
    .unsignedHere => unsignedHere,
  };

  /// Whether trying again may work: a download can, a refused file can't.
  bool get canRetry => switch (this) {
    checkFailed || downloadFailed || installFailed => true,
    _ => false,
  };
}
