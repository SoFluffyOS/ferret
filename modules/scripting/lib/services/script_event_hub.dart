import 'dart:async';

import 'package:scripting/models/models.dart';

/// Where the app's features report what happened, and where `ferret-cli
/// watch` and hook scripts hear about it.
class ScriptEventHub {
  ScriptEventHub({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final StreamController<ScriptEvent> _events = .broadcast();

  Stream<ScriptEvent> get events => _events.stream;

  void add(ScriptEvent event) {
    if (_events.isClosed) {
      return;
    }

    _events.add(event);
  }

  /// The JSON lines one `watch` gets: a [ScriptEventType.ready] line with
  /// [devices], then every event that matches the `types` it asked for.
  /// Content travels only when it asked with `include_content`.
  Stream<Map<String, Object?>> watch(
    Map<String, Object?> arguments, {
    required List<Map<String, Object?>> Function() devices,
  }) {
    final includeContent = arguments['include_content'] == true;
    final types = switch (arguments['types']) {
      final List<Object?> list => [
        for (final type in list)
          if (type case final String name when name.isNotEmpty) name,
      ],
      _ => const <String>[],
    };
    final ready = ScriptEvent(
      type: ScriptEventType.ready,
      at: _clock(),
      fields: {'devices': devices()},
    );

    return Stream.multi((listener) {
      listener.add(ready.toJson());
      final subscription = events
          .where((event) => event.matches(types))
          .listen(
            (event) =>
                listener.add(event.toJson(includeContent: includeContent)),
          );
      listener.onCancel = subscription.cancel;
    });
  }

  Future<void> dispose() => _events.close();
}
