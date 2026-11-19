/// A command this computer's owner defined here, under a name of their
/// own. Only the id and the name ever leave this computer.
class CustomAction {
  const CustomAction({
    required this.id,
    required this.name,
    required this.commandLine,
  });

  final String id;

  /// What other devices show, such as "Backup".
  final String name;

  /// The program and its arguments, or the path of a script or shortcut,
  /// as typed. No shell reads it.
  final String commandLine;

  static CustomAction? fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'command': final String commandLine,
    }) {
      return CustomAction(id: id, name: name, commandLine: commandLine);
    }

    return null;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'command': commandLine,
  };
}
