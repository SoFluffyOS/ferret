import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:shell/l10n/generated/shell_localizations.dart';

/// What to call the device Ferret runs on: "this Mac", "this phone". Never
/// "this device" when its kind is known.
extension LocalNames on ShellLocalizations {
  /// For the middle of a sentence: "this Mac".
  String here(LocalDevice device) => switch ((
    device.platform,
    device.formFactor,
  )) {
    (.PLATFORM_MACOS, _) => thisMac,
    (_, .FORM_FACTOR_PHONE) => thisPhone,
    (_, .FORM_FACTOR_TABLET) => thisTablet,
    (.PLATFORM_ANDROID || .PLATFORM_IOS, _) => thisPhone,
    _ => thisComputer,
  };

  /// For the start of a sentence: "This Mac".
  String hereStart(LocalDevice device) => switch ((
    device.platform,
    device.formFactor,
  )) {
    (.PLATFORM_MACOS, _) => thisMacStart,
    (_, .FORM_FACTOR_PHONE) => thisPhoneStart,
    (_, .FORM_FACTOR_TABLET) => thisTabletStart,
    (.PLATFORM_ANDROID || .PLATFORM_IOS, _) => thisPhoneStart,
    _ => thisComputerStart,
  };

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
