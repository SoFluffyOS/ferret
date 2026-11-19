import 'dart:io';

/// Turns the line a person typed ("~/bin/backup.sh --quick") into the
/// program and arguments to start. No shell ever reads it: quotes group
/// words, and nothing else (`;`, `|`, `$`, backticks) means anything.
abstract final class CommandLine {
  /// Splits [line] at spaces. Single or double quotes keep a part
  /// together, and a backslash keeps the next character as it is (not on
  /// Windows, where it separates folders).
  static List<String> split(String line, {bool? backslashEscapes}) {
    final escapes = backslashEscapes ?? !Platform.isWindows;
    final words = <String>[];
    final word = StringBuffer();
    var hasWord = false;
    String? quote;
    var escaped = false;

    for (final character in line.split('')) {
      if (escaped) {
        word.write(character);
        escaped = false;
        continue;
      }

      if (escapes && character == r'\' && quote != "'") {
        escaped = true;
        hasWord = true;
        continue;
      }

      if (quote != null) {
        if (character == quote) {
          quote = null;
          continue;
        }

        word.write(character);
        continue;
      }

      if (character == '"' || character == "'") {
        quote = character;
        hasWord = true;
        continue;
      }

      if (character.trim().isEmpty) {
        if (hasWord) {
          words.add(word.toString());
          word.clear();
          hasWord = false;
        }
        continue;
      }

      word.write(character);
      hasWord = true;
    }

    if (hasWord) {
      words.add(word.toString());
    }

    return words;
  }

  /// What to really start for [words]: a leading `~` becomes the home
  /// folder, and a script or shortcut gets the program that opens it
  /// (`sh` for `.sh`, `osascript` for `.scpt`, `open` for a Mac app,
  /// PowerShell for `.ps1`, `cmd /c` for `.bat`, `.cmd` and `.lnk`).
  /// Anything else starts as it is.
  static List<String> resolve(
    List<String> words, {
    String? home,
    String? operatingSystem,
  }) {
    if (words.isEmpty) {
      return const [];
    }

    final homeFolder = home ?? _home();
    final system = operatingSystem ?? Platform.operatingSystem;
    final expanded = [for (final word in words) _expandHome(word, homeFolder)];
    final target = expanded.first.toLowerCase();
    final opener = switch (system) {
      'windows' => _windowsOpener(target),
      'macos' => _macOpener(target),
      _ => _unixOpener(target),
    };

    return [...opener, ...expanded];
  }

  static List<String> _unixOpener(String target) {
    if (target.endsWith('.sh')) {
      return const ['/bin/sh'];
    }

    return const [];
  }

  static List<String> _macOpener(String target) {
    if (target.endsWith('.scpt') || target.endsWith('.applescript')) {
      return const ['/usr/bin/osascript'];
    }

    if (target.endsWith('.app') || target.endsWith('.workflow')) {
      return const ['/usr/bin/open'];
    }

    return _unixOpener(target);
  }

  static List<String> _windowsOpener(String target) {
    if (target.endsWith('.ps1')) {
      return const [
        'powershell',
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
      ];
    }

    if (target.endsWith('.bat') ||
        target.endsWith('.cmd') ||
        target.endsWith('.lnk')) {
      return const ['cmd', '/c'];
    }

    return const [];
  }

  static String _expandHome(String word, String home) {
    if (home.isEmpty) {
      return word;
    }

    if (word == '~') {
      return home;
    }

    if (word.startsWith('~/') || word.startsWith(r'~\')) {
      return '$home${word.substring(1)}';
    }

    return word;
  }

  static String _home() =>
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
}
