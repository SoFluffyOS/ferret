import 'dart:io';

/// Runs a command and waits for it, such as `codesign`.
typedef RunProcess = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  Map<String, String>? environment,
});

/// Starts a command that outlives Ferret, such as the relaunch helper.
typedef StartDetached = Future<void> Function(
  String executable,
  List<String> arguments,
);

Future<ProcessResult> runProcess(
  String executable,
  List<String> arguments, {
  Map<String, String>? environment,
}) => Process.run(executable, arguments, environment: environment);

Future<void> startDetached(String executable, List<String> arguments) async {
  await Process.start(executable, arguments, mode: .detached);
}

/// Installs a downloaded, checksum-checked update.
abstract interface class UpdateInstaller {
  /// Checks [file]'s signature where the platform has one, then installs
  /// it, or throws [UpdateRefused] when the signature isn't Ferret's.
  Future<InstallOutcome> install(File file);
}

/// What an install left to do.
enum InstallOutcome {
  /// Installed, and a helper reopens Ferret once it quits: quit now.
  quitToRestart,

  /// Ferret couldn't replace itself (a Mac without write access to the
  /// app's folder), so the update is open for the person to drag in.
  openedForYou,

  /// The system shows its own install prompt (Android).
  handedToSystem,

  /// The system first needs the person's OK to install apps from Ferret
  /// (Android's "Install unknown apps").
  needsPermission,
}

/// Why an update wasn't installed although it downloaded.
enum RefusalReason {
  /// The release has no SHA256SUMS, or it doesn't list this file.
  checksumMissing,

  /// The file's SHA-256 isn't the one SHA256SUMS lists.
  checksumMismatch,

  /// Not signed, or the signature is broken.
  notSigned,

  /// Signed, but not by Ferret's developer.
  wrongPublisher,

  /// Signed, but Apple's notarization (Gatekeeper) doesn't accept it.
  notNotarized,

  /// This copy of Ferret isn't signed itself (Windows), so there is no
  /// publisher to compare with.
  unsignedHere,
}

/// The update was refused before anything was installed.
class UpdateRefused implements Exception {
  const UpdateRefused(this.reason, [this.detail = '']);

  final RefusalReason reason;

  /// What the check said, for the log. Never shown as is.
  final String detail;

  @override
  String toString() => 'UpdateRefused(${reason.name}): $detail';
}
