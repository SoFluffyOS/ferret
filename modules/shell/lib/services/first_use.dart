import 'package:engine/engine.dart';
import 'package:shell/services/activity_feed.dart';
import 'package:shell/services/tips.dart';

/// Whether the person has seen Ferret work yet. Right after the first
/// pairing, Home says one thing: here is your device, try sending
/// something. What else could be set up (Do more) waits until something
/// went through, a tip was done or waved off, or the first pairing is a
/// day old.
abstract final class FirstUse {
  /// How long Do more waits for a first use at most.
  static const patience = Duration(days: 1);

  static bool seen({
    required Tips tips,
    required Iterable<TrustedDevice> devices,
    required ActivityFeed feed,
    DateTime? now,
  }) {
    if (tips.isCopyDone || tips.isDragDone || tips.isPasteDone) {
      return true;
    }

    if (!feed.isEmpty) {
      return true;
    }

    final before = (now ?? DateTime.now()).subtract(patience);
    return devices.any((device) => device.pairedAt.isBefore(before));
  }
}
