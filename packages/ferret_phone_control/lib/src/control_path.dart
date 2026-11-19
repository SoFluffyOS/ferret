/// What carries a computer's taps and keys into this phone.
enum ControlPath {
  /// The power-ups helper, through Shizuku or root: real touches and keys.
  powerUps,

  /// Ferret's accessibility service, turned on by the owner in the
  /// system's Accessibility settings: gestures, a few keys, typed text.
  service,

  /// Nothing can, until the owner turns one of the two on.
  none,
}

/// What a computer can do on this phone through a [ControlPath].
enum PhoneAbility { pointer, keys, text, buttons }
