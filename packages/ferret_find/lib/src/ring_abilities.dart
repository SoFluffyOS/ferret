/// What this device may and can do while ringing.
class RingAbilities {
  const RingAbilities({
    this.controlsVolume = false,
    this.needsDndAccess = false,
    this.dndAccessGranted = false,
    this.fullScreenAllowed = true,
    this.hasTorch = false,
    this.ringsInBackground = true,
    this.showsOwnAlert = false,
    this.canPlaySound = true,
    this.ignoresSilentSwitch = false,
  });

  /// It can raise the volume to the top and put it back (Android, macOS).
  final bool controlsVolume;

  /// Ringing through Do Not Disturb needs a permission (Android).
  final bool needsDndAccess;
  final bool dndAccessGranted;

  /// Android 14+ lets people deny full-screen notifications, which put the
  /// ringing screen over the lock screen.
  final bool fullScreenAllowed;
  final bool hasTorch;

  /// False on iOS, which stops Ferret soon after it leaves the screen.
  final bool ringsInBackground;

  /// The platform shows its own ringing notification with "Found it"
  /// (Android), so the app shows none.
  final bool showsOwnAlert;

  /// False on Linux when no sound player is installed.
  final bool canPlaySound;

  /// The sound plays through the silent switch on its own (iOS).
  final bool ignoresSilentSwitch;

  /// Whether ringing can be loud on silent once the person allowed it.
  bool get canRingWhenSilent =>
      ignoresSilentSwitch ||
      (controlsVolume && (!needsDndAccess || dndAccessGranted));

  /// The person allowed ringing on silent but the system permission for it
  /// is missing.
  bool get missingDndAccess => needsDndAccess && !dndAccessGranted;

  @override
  bool operator ==(Object other) =>
      other is RingAbilities &&
      other.controlsVolume == controlsVolume &&
      other.needsDndAccess == needsDndAccess &&
      other.dndAccessGranted == dndAccessGranted &&
      other.fullScreenAllowed == fullScreenAllowed &&
      other.hasTorch == hasTorch &&
      other.ringsInBackground == ringsInBackground &&
      other.showsOwnAlert == showsOwnAlert &&
      other.canPlaySound == canPlaySound &&
      other.ignoresSilentSwitch == ignoresSilentSwitch;

  @override
  int get hashCode => Object.hash(
    controlsVolume,
    needsDndAccess,
    dndAccessGranted,
    fullScreenAllowed,
    hasTorch,
    ringsInBackground,
    showsOwnAlert,
    canPlaySound,
    ignoresSilentSwitch,
  );
}
