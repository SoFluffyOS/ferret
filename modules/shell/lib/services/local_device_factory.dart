import 'dart:io' as io;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:protocol/protocol.dart';

/// Describes this device from what the platform reports. [name] overrides the
/// name the platform suggests.
Future<LocalDevice> describeThisDevice({
  String? name,
  String appVersion = '',
}) async {
  final info = DeviceInfoPlugin();

  if (io.Platform.isAndroid) {
    final android = await info.androidInfo;
    final isTablet = ThisComputer.isTabletScreen;
    return LocalDevice(
      name: name ?? android.model,
      platform: .PLATFORM_ANDROID,
      formFactor: switch (isTablet) {
        true => FormFactor.FORM_FACTOR_TABLET,
        false => FormFactor.FORM_FACTOR_PHONE,
      },
      model: '${android.manufacturer} ${android.model}',
      appVersion: appVersion,
    );
  }

  if (io.Platform.isIOS) {
    final ios = await info.iosInfo;
    final isTablet = ios.model.toLowerCase().contains('ipad');
    return LocalDevice(
      name: name ?? ios.name,
      platform: .PLATFORM_IOS,
      formFactor: switch (isTablet) {
        true => FormFactor.FORM_FACTOR_TABLET,
        false => FormFactor.FORM_FACTOR_PHONE,
      },
      model: ios.utsname.machine,
      appVersion: appVersion,
    );
  }

  if (io.Platform.isMacOS) {
    final mac = await info.macOsInfo;
    final isLaptop = mac.model.toLowerCase().contains('book');
    return LocalDevice(
      name: name ?? mac.computerName,
      platform: .PLATFORM_MACOS,
      formFactor: switch (isLaptop) {
        true => FormFactor.FORM_FACTOR_LAPTOP,
        false => FormFactor.FORM_FACTOR_DESKTOP,
      },
      model: mac.model,
      appVersion: appVersion,
    );
  }

  if (io.Platform.isWindows) {
    final windows = await info.windowsInfo;
    return LocalDevice(
      name: name ?? windows.computerName,
      platform: .PLATFORM_WINDOWS,
      formFactor: .FORM_FACTOR_DESKTOP,
      model: windows.productName,
      appVersion: appVersion,
    );
  }

  final linux = await info.linuxInfo;
  return LocalDevice(
    name: name ?? io.Platform.localHostname,
    platform: .PLATFORM_LINUX,
    formFactor: .FORM_FACTOR_DESKTOP,
    model: linux.prettyName,
    appVersion: appVersion,
  );
}
