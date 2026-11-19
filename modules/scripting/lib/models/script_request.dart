/// A request from Tasker or Shortcuts, in the words of `ferret-cli`:
/// [command] is `clipboard_send`, `ring`, `open`, `action_run`, `notify`
/// or `send_files`.
class ScriptRequest {
  const ScriptRequest({
    required this.source,
    required this.command,
    this.device = '',
    this.value = '',
    this.body = '',
    this.paths = const [],
  });

  /// Reads what Tasker or Shortcuts sent. Null when it names no command.
  static ScriptRequest? fromMap(
    ScriptSource source,
    Map<Object?, Object?> map,
  ) {
    final command = map['command'];
    if (command is! String || command.isEmpty) {
      return null;
    }

    String text(String key) => switch (map[key]) {
      final String value => value,
      _ => '',
    };

    return ScriptRequest(
      source: source,
      command: command,
      device: text('device').trim(),
      value: text('value'),
      body: text('body'),
      paths: switch (map['paths']) {
        final List<Object?> list => [
          for (final path in list)
            if (path case final String text when text.isNotEmpty) text,
        ],
        _ => const [],
      },
    );
  }

  final ScriptSource source;
  final String command;

  /// The device's name or id. Empty for every connected device, where the
  /// command allows it.
  final String device;

  /// The text, link, action or title, depending on [command].
  final String value;
  final String body;
  final List<String> paths;

  /// The arguments the app's command handler takes for [command].
  Map<String, Object?> get arguments => switch (command) {
    'clipboard_send' => {
      'text': value,
      if (device.isNotEmpty) 'device': device,
    },
    'open' => {'device': device, 'link': value},
    'action_run' => {'device': device, 'action': value},
    'notify' => {'device': device, 'title': value, 'body': body},
    'send_files' => {'device': device, 'paths': paths},
    _ => {'device': device},
  };
}

/// Where a [ScriptRequest] came from.
enum ScriptSource { tasker, shortcuts }
