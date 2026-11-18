/// Something the user asked for from outside the app, such as tapping the
/// Quick Settings tile. `clipboard.send` carries the copied text in
/// `data['text']`, read while Ferret was in the foreground.
class SystemAction {
  const SystemAction(this.id, [this.data = const {}]);

  /// Sends the clipboard to paired devices. `data['text']` holds it.
  static const clipboardSend = 'clipboard.send';

  final String id;
  final Map<String, String> data;

  @override
  bool operator ==(Object other) =>
      other is SystemAction &&
      other.id == id &&
      other.data.length == data.length &&
      other.data.entries.every((entry) => data[entry.key] == entry.value);

  @override
  int get hashCode => Object.hash(id, Object.hashAllUnordered(data.entries));

  @override
  String toString() => 'SystemAction($id)';
}
