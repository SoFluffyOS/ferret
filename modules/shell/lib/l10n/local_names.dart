import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:shell/l10n/generated/shell_localizations.dart';

/// What to call the device Ferret runs on: "this Mac", "this phone". Never
/// "this device" when its kind is known.
extension LocalNames on ShellLocalizations {
  /// The kind of device this is, for a string's `{here, select, …}`: each
  /// string spells "this Mac" its own way, so a language with cases can
  /// say "diesen Mac" in one sentence and "diesem Mac" in the next.
  String here(LocalDevice device) => switch ((
    device.platform,
    device.formFactor,
  )) {
    (.PLATFORM_MACOS, _) => hereMac,
    (_, .FORM_FACTOR_PHONE) => herePhone,
    (_, .FORM_FACTOR_TABLET) => hereTablet,
    (.PLATFORM_WINDOWS, _) => hereWindows,
    (.PLATFORM_ANDROID || .PLATFORM_IOS, _) => herePhone,
    _ => hereComputer,
  };

  /// The values [here] takes. Strings name the first four and keep
  /// `other` for a computer: "this PC" is what Windows calls itself.
  static const hereMac = 'mac';
  static const hereWindows = 'windows';
  static const herePhone = 'phone';
  static const hereTablet = 'tablet';
  static const hereComputer = 'computer';

  /// The name of a Settings row. What a phone shares is "From your phone"
  /// on a computer and "To your computer" on the phone itself.
  String settingsGroupTitle(SettingsGroup group, LocalDevice device) =>
      switch (group) {
        .clipboard => settingsGroupClipboard,
        .files => settingsGroupFiles,
        .continueAndMedia => settingsGroupContinue,
        .phone => switch (device.formFactor) {
          .FORM_FACTOR_PHONE || .FORM_FACTOR_TABLET => settingsGroupToComputer,
          _ => settingsGroupFromPhone,
        },
        .control => settingsGroupControl,
        .otherApps => settingsGroupOtherApps,
      };
}
