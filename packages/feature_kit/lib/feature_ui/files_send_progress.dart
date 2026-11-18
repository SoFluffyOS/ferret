/// How sending dropped files is going, for the shell's drop state.
sealed class FilesSendProgress {
  const FilesSendProgress();
}

/// Bytes are moving: [fraction] goes from 0 to 1.
final class FilesSending extends FilesSendProgress {
  const FilesSending(this.fraction);

  final double fraction;
}

/// Every file arrived.
final class FilesSent extends FilesSendProgress {
  const FilesSent();
}

/// Sending stopped; [reason] says why in plain words.
final class FilesSendFailed extends FilesSendProgress {
  const FilesSendFailed(this.reason);

  final String reason;
}
