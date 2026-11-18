/// What happened to an activity sent to another device.
enum SendOutcome {
  /// The other device opened it.
  opened,

  /// The other device shows it as a suggestion to open.
  suggested,

  /// The other device couldn't open it.
  failed,

  /// The other device isn't connected or didn't answer.
  unreachable,
}
