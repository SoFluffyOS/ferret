import 'package:path/path.dart' as p;

/// Reads `ferret send <file>…`, the command a file manager's "Send with
/// Ferret" entry starts the app with.
abstract final class SendArguments {
  static const String command = 'send';

  /// The files to send as absolute paths, or nothing when [arguments] isn't
  /// a send command. `file://` links, which some file managers pass, become
  /// paths. Relative paths are read from [workingDirectory].
  static List<String> paths(
    List<String> arguments, {
    String? workingDirectory,
    p.Context? context,
  }) {
    if (arguments case [command, ...final files]) {
      final path = context ?? p.context;
      final base = workingDirectory ?? path.current;

      return [
        for (final file in files)
          if (!file.startsWith('-') && file.isNotEmpty)
            path.normalize(path.join(base, _pathOf(file, path))),
      ];
    }

    return const [];
  }

  static String _pathOf(String file, p.Context path) {
    final link = Uri.tryParse(file);
    if (link == null || !link.isScheme('file')) {
      return file;
    }

    return path.fromUri(link);
  }
}
