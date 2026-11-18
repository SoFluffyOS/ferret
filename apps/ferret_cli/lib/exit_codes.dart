/// What `ferret` exits with, from BSD's sysexits where one fits, so scripts
/// can tell the cases apart.
abstract final class ExitCodes {
  static const ok = 0;

  /// Something went wrong, such as an unknown device name.
  static const failed = 1;

  /// The command was called the wrong way.
  static const usage = 64;

  /// A file to send doesn't exist.
  static const noInput = 66;

  /// The Ferret app isn't running, so there is nobody to hand files to.
  static const unavailable = 69;

  static const description =
      'Exit codes: 0 done, 1 failed, 64 wrong usage, 66 a file to send is '
      "missing, 69 the Ferret app isn't running.";
}
