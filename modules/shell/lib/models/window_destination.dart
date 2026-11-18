import 'package:feature_kit/feature_kit.dart';

/// What a window's content pane shows: the thing selected in its device
/// list.
sealed class WindowDestination {
  const WindowDestination();

  /// Reads back what [stored] wrote, or null when it says nothing known.
  static WindowDestination? parse(String? stored) {
    if (stored == null) {
      return null;
    }

    return switch (stored.split(':')) {
      ['activity'] => const ActivityDestination(),
      ['settings'] => const SettingsDestination(),
      ['device', final deviceId, final sectionId] => DeviceDestination(
        deviceId,
        sectionId: sectionId,
      ),
      _ => null,
    };
  }

  /// One line to keep in settings, so the window opens where it was left.
  String get stored;
}

/// One section of a paired device: its Overview, or a feature's page such
/// as its texts.
final class DeviceDestination extends WindowDestination {
  const DeviceDestination(
    this.deviceId, {
    this.sectionId = FeatureSection.overviewId,
  });

  final String deviceId;

  /// A `FeatureSection.id`, or [FeatureSection.overviewId].
  final String sectionId;

  @override
  String get stored => 'device:$deviceId:$sectionId';

  @override
  bool operator ==(Object other) =>
      other is DeviceDestination &&
      other.deviceId == deviceId &&
      other.sectionId == sectionId;

  @override
  int get hashCode => Object.hash(deviceId, sectionId);
}

/// Everything that happened lately, with every device.
final class ActivityDestination extends WindowDestination {
  const ActivityDestination();

  @override
  String get stored => 'activity';
}

final class SettingsDestination extends WindowDestination {
  const SettingsDestination();

  @override
  String get stored => 'settings';
}
