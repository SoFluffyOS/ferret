/// What `ferret` exits with, from BSD's sysexits where one fits, so scripts
/// can tell the cases apart.
abstract final class ExitCodes {
  static const ok = 0;

  /// Something went wrong, such as the other device saying no.
  static const failed = 1;

  /// The command was called the wrong way.
  static const usage = 64;

  /// A file to send doesn't exist, or there is no clip to print.
  static const noInput = 66;

  /// No paired device has that name, or several do.
  static const noDevice = 67;

  /// The Ferret app isn't running, so there is nobody to hand files to.
  static const unavailable = 69;

  /// The device is paired but not connected right now.
  static const notConnected = 75;

  static const description =
      'Exit codes: 0 done, 1 failed, 64 wrong usage, 66 a file to send or a '
      'clip is missing, 67 no device has that name (or several do), 69 the '
      "Ferret app isn't running, 75 the device isn't connected.";
}
