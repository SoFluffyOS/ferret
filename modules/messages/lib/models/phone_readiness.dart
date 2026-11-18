/// Where a phone is, as a computer sees it, for reading its texts.
enum PhoneReadiness {
  /// Not connected; saved messages still show.
  offline,

  /// Connected, asking the phone how it is set up.
  checking,

  /// Messages are off on the phone.
  off,

  /// Messages are on but the phone doesn't let Ferret read SMS.
  noAccess,

  /// The phone didn't answer.
  unreachable,

  /// Everything works.
  ready,
}
