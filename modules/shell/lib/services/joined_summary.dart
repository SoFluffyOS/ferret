import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';

/// Several devices that joined at once, as one line: who, and who added
/// them when it was the same device for all.
class JoinedSummary {
  const JoinedSummary(this.joined);

  final List<DeviceJoined> joined;

  /// Their names, in the order they joined.
  String get names =>
      ListText.join([for (final each in joined) each.device.name]);

  /// The device that added all of them, or null when it was several.
  String? get introducer {
    final names = {for (final each in joined) each.introducer.name};
    return switch (names.length) {
      1 => names.first,
      _ => null,
    };
  }
}
