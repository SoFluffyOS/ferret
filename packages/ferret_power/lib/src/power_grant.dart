/// A setting Ferret can turn on for itself once a tier is active, instead of
/// sending the user through the system settings.
enum PowerGrant {
  /// Turns on Ferret's notification listener
  /// (`cmd notification allow_listener`). Also gets past Android 13's
  /// "restricted setting" block for apps installed from an APK.
  notificationAccess,

  /// Exempts Ferret from battery optimisation
  /// (`cmd deviceidle whitelist`), so the connection survives in the
  /// background.
  batteryUnrestricted,
}
