/// How a time of mirroring ended, for the history on both sides.
enum MirrorEnd {
  /// The computer closed its mirror page or pressed Stop.
  viewerDone,

  /// Someone pressed Stop on the phone.
  stoppedOnPhone,

  /// The phone's system ended the capture, such as when it was locked.
  systemEnded,

  /// The phone's owner turned screen mirroring off.
  turnedOff,

  /// The connection dropped.
  lostConnection,

  /// Capturing, encoding or decoding stopped working.
  failed,
}
