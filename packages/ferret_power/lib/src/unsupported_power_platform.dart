import 'package:ferret_power/src/power_clip.dart';
import 'package:ferret_power/src/power_grant.dart';
import 'package:ferret_power/src/power_platform.dart';
import 'package:ferret_power/src/power_status.dart';
import 'package:ferret_power/src/power_tier.dart';

/// Every platform but Android: nothing to find, nothing to run.
class UnsupportedPowerPlatform implements PowerPlatform {
  const UnsupportedPowerPlatform();

  @override
  Stream<PowerStatus> get statusChanges => const .empty();

  @override
  Stream<PowerClip> get clipboardChanges => const .empty();

  @override
  Stream<void> get watchStops => const .empty();

  @override
  Future<PowerStatus> status() async => PowerStatus.unsupported;

  @override
  Future<bool> requestShizukuPermission() async => false;

  @override
  Future<bool> requestRoot() async => false;

  @override
  Future<bool> openShizuku() async => false;

  @override
  Future<bool> openNotificationAccessSettings() async => false;

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<PowerClip?> readClipboard(PowerTier tier) async => null;

  @override
  Future<void> startClipboardWatch(PowerTier tier) async {}

  @override
  Future<void> stopClipboardWatch() async {}

  @override
  Future<bool> grant(PowerTier tier, PowerGrant grant) async => false;
}
