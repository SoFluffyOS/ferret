import 'dart:io';

import 'package:ferret_power/src/pigeon_power_platform.dart';
import 'package:ferret_power/src/power_clip.dart';
import 'package:ferret_power/src/power_grant.dart';
import 'package:ferret_power/src/power_input.dart';
import 'package:ferret_power/src/power_status.dart';
import 'package:ferret_power/src/power_tier.dart';
import 'package:ferret_power/src/unsupported_power_platform.dart';

/// The native side of the power-ups. It does what it is told: deciding
/// whether a tier may be used at all is `PowerCapabilities`' job.
abstract interface class PowerPlatform {
  /// Android gets the plugin; every other platform gets one that does
  /// nothing.
  factory PowerPlatform.current() {
    if (Platform.isAndroid) {
      return PigeonPowerPlatform();
    }

    return const UnsupportedPowerPlatform();
  }

  /// Fires when Shizuku starts, stops or changes its answer.
  Stream<PowerStatus> get statusChanges;

  /// Text copied anywhere on the phone, while a watch is running.
  Stream<PowerClip> get clipboardChanges;

  /// Fires when a running watch ended on its own.
  Stream<void> get watchStops;

  Future<PowerStatus> status();

  Future<bool> requestShizukuPermission();

  Future<bool> requestRoot();

  Future<bool> openShizuku();

  Future<bool> openNotificationAccessSettings();

  Future<bool> openAppSettings();

  Future<PowerClip?> readClipboard(PowerTier tier);

  Future<void> startClipboardWatch(PowerTier tier);

  Future<void> stopClipboardWatch();

  Future<bool> grant(PowerTier tier, PowerGrant grant);

  /// Injects [input] through [tier]'s helper. Calls are carried out in the
  /// order they are made. False when the system refused.
  Future<bool> inject(PowerTier tier, PowerInput input);

  /// Lifts a finger that was left down and lets the helper rest.
  Future<void> releaseInput();
}
