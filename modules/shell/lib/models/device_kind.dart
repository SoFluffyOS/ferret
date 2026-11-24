import 'package:protocol/protocol.dart';

/// What kind of device another one is, by product name: the same in every
/// language. Tells two devices with the same name apart.
abstract final class DeviceKind {
  /// Empty for a kind Ferret doesn't know.
  static String of(Platform platform, FormFactor formFactor) =>
      switch (platform) {
        .PLATFORM_ANDROID => 'Android',
        .PLATFORM_IOS when formFactor == .FORM_FACTOR_TABLET => 'iPad',
        .PLATFORM_IOS => 'iPhone',
        .PLATFORM_MACOS => 'Mac',
        .PLATFORM_LINUX => 'Linux',
        .PLATFORM_WINDOWS => 'Windows',
        .PLATFORM_CLI => 'Terminal',
        _ => '',
      };
}
