/// The rows of Settings. Each opens a page with the settings of the features
/// that belong to it, in this order.
enum SettingsGroup {
  clipboard,
  files,
  continueAndMedia,

  /// What a phone shares with a computer: notifications, messages, calls,
  /// its screen.
  phone,

  /// Controlling a device, ringing it, and what a phone unlocks for Ferret.
  control,

  /// Other apps and devices Ferret talks to: LocalSend, Quick Share, the
  /// browser extension, an iPhone.
  otherApps,
}
