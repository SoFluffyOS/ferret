/// Something that happened in Ferret, as `ferret-cli watch` prints it and
/// as hook scripts read it on stdin: one JSON object per line.
///
/// Every object has `v` (the schema version, [schemaVersion]), `type` (one
/// of [ScriptEventType]), `at` (UTC, ISO 8601) and, when a device is
/// involved, `device` with its `id` and `name`. The rest depends on the
/// type. New fields may appear in the same version; a field never changes
/// meaning or goes away without a new version.
class ScriptEvent {
  const ScriptEvent({
    required this.type,
    required this.at,
    this.deviceId,
    this.deviceName,
    this.fields = const {},
    this.private = const {},
    this.content = const {},
  });

  static const int schemaVersion = 1;

  final String type;
  final DateTime at;
  final String? deviceId;
  final String? deviceName;

  /// Facts that say nothing about what a person wrote or received, such as
  /// a battery level or a byte count.
  final Map<String, Object?> fields;

  /// Names that may be private, such as a notification's title or the path
  /// of a received file. Left empty when previews from that device are off
  /// on this computer.
  final Map<String, Object?> private;

  /// The content itself, such as copied text. Only printed for
  /// `ferret-cli watch --include-content`, never given to hooks, and left
  /// empty when previews from that device are off or the item is marked
  /// private.
  final Map<String, Object?> content;

  /// The event as JSON, with [content] only when [includeContent].
  Map<String, Object?> toJson({bool includeContent = false}) => {
    'v': schemaVersion,
    'type': type,
    'at': at.toUtc().toIso8601String(),
    if (deviceId case final id?) 'device': {'id': id, 'name': deviceName ?? id},
    ...fields,
    ...private,
    if (includeContent) ...content,
  };

  /// Whether a watcher that asked for [types] wants this event. An entry
  /// matches its own type and every type under it: `device` matches
  /// `device.connected`. No entries match everything.
  bool matches(Iterable<String> types) {
    if (types.isEmpty) {
      return true;
    }

    return types.any(
      (wanted) => type == wanted || type.startsWith('$wanted.'),
    );
  }
}
