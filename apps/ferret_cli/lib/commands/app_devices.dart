import 'dart:async';

import 'package:core/core.dart';

/// The devices paired with the Ferret app running on this computer, the
/// ones `ring`, `open`, `notify` and the others reach.
abstract final class AppDevices {
  static const Duration _patience = Duration(seconds: 2);

  /// Each device as `{id, name, connected}` (and `reconnecting`, `battery`
  /// when known), as the first line of `watch` lists them. Null when no app
  /// is running or it is too old to say.
  static Future<List<Map<String, Object?>>?> read(String appRoot) async {
    final events = await AppControl(appRoot).watch({
      'include_content': false,
      'types': const ['ready'],
    });
    if (events == null) {
      return null;
    }

    try {
      final ready = await events.first.timeout(_patience);
      return switch (ready) {
        {'type': 'ready', 'devices': final List<Object?> devices} => [
          for (final device in devices)
            if (device case final Map<String, Object?> known) known,
        ],
        _ => null,
      };
    } on Object {
      return null;
    }
  }
}
