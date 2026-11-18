import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ferret_clipboard/src/clipboard_access.dart';
import 'package:ferret_clipboard/src/clipboard_content.dart';
import 'package:ferret_clipboard/src/clipboard_platform.dart';
import 'package:flutter/services.dart';

/// Runs a command and collects its output; stdout is bytes.
typedef RunCommand = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// Starts a command whose stdin takes the clipboard data.
typedef StartCommand = Future<Process> Function(
  String executable,
  List<String> arguments,
);

/// The Linux clipboard. Text goes through Flutter's GTK clipboard; images
/// and private-item hints need `wl-clipboard` on Wayland or `xclip` on X11,
/// and are skipped when those aren't installed.
class LinuxClipboard implements ClipboardPlatform {
  LinuxClipboard({
    Map<String, String>? environment,
    RunCommand? run,
    StartCommand? start,
    Future<String?> Function()? readText,
    Future<void> Function(String text)? writeText,
    this.pollInterval = const Duration(seconds: 1),
  }) : _environment = environment ?? Platform.environment,
       _run = run ?? _runForBytes,
       _start = start ?? Process.start,
       _readText = readText ?? _flutterReadText,
       _writeText = writeText ?? _flutterWriteText;

  /// KDE's hint that a password manager put a secret on the clipboard;
  /// KeePassXC and others set it.
  static const passwordHintType = 'x-kde-passwordManagerHint';

  static const _concealedType = 'org.nspasteboard.ConcealedType';
  static const _watchStartGrace = Duration(seconds: 1);

  final Map<String, String> _environment;
  final RunCommand _run;
  final StartCommand _start;
  final Future<String?> Function() _readText;
  final Future<void> Function(String text) _writeText;

  /// How often to look for changes when the compositor can't report them.
  final Duration pollInterval;

  final StreamController<void> _changes = .broadcast();
  Timer? _poll;
  Process? _watcher;
  String? _lastSignature;
  bool _toolMissing = false;
  bool _polling = false;

  @override
  ClipboardAccess get access => .always;

  @override
  Stream<void> get changes => _changes.stream;

  bool get _isWayland => (_environment['WAYLAND_DISPLAY'] ?? '').isNotEmpty;

  @override
  Future<ClipboardContent?> read() async {
    final types = await _types();
    final sensitive =
        types.contains(passwordHintType) || types.contains(_concealedType);

    final text = await _readText();
    if (text != null && text.isNotEmpty) {
      return ClipboardContent.text(text, sensitive: sensitive);
    }

    final imageType = _preferredImageType(types);
    if (imageType == null) {
      return null;
    }

    final bytes = await _readBytes(imageType);
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    return ClipboardContent.image(
      bytes,
      imageMime: imageType,
      sensitive: sensitive,
    );
  }

  @override
  Future<void> write(ClipboardContent content) async {
    if (content.text case final text?) {
      await _writeText(text);
      return;
    }

    if ((content.image, content.imageMime) case (final image?, final mime?)) {
      await _writeImage(image, mime);
    }
  }

  @override
  Future<void> startWatching() async {
    if (_poll != null || _watcher != null) {
      return;
    }

    if (_isWayland && await _startWaylandWatcher()) {
      return;
    }

    _lastSignature = await _signature();
    _poll = .periodic(pollInterval, (_) => unawaited(_checkSignature()));
  }

  @override
  Future<void> stopWatching() async {
    _poll?.cancel();
    _poll = null;
    _watcher?.kill();
    _watcher = null;
  }

  /// `wl-paste --watch` reports every change, but only on compositors with
  /// the data-control protocol (wlroots, KDE). It exits at once elsewhere.
  Future<bool> _startWaylandWatcher() async {
    final Process process;
    try {
      process = await _start('wl-paste', ['--watch', 'echo', 'changed']);
    } on ProcessException {
      return false;
    }

    final exited = await process.exitCode
        .then<bool>((_) => true)
        .timeout(_watchStartGrace, onTimeout: () => false);
    if (exited) {
      return false;
    }

    _watcher = process;
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((_) => _changes.add(null));
    unawaited(process.stderr.drain<void>());
    return true;
  }

  Future<void> _checkSignature() async {
    if (_polling) {
      return;
    }

    _polling = true;
    try {
      final signature = await _signature();
      if (signature == _lastSignature) {
        return;
      }

      _lastSignature = signature;
      _changes.add(null);
    } finally {
      _polling = false;
    }
  }

  Future<String> _signature() async {
    final text = await _readText() ?? '';
    final types = await _types();
    final stamp = switch (_isWayland) {
      true => '',
      false => await _x11Timestamp(),
    };
    return '${text.hashCode}|${types.join(',')}|$stamp';
  }

  Future<List<String>> _types() async {
    final output = await _runText(switch (_isWayland) {
      true => ('wl-paste', ['--list-types']),
      false => ('xclip', ['-selection', 'clipboard', '-t', 'TARGETS', '-o']),
    });
    if (output == null) {
      return const [];
    }

    return [
      for (final line in const LineSplitter().convert(output))
        if (line.trim().isNotEmpty) line.trim(),
    ];
  }

  Future<String> _x11Timestamp() async =>
      await _runText((
        'xclip',
        ['-selection', 'clipboard', '-t', 'TIMESTAMP', '-o'],
      )) ??
      '';

  Future<Uint8List?> _readBytes(String type) => _runBytes(switch (_isWayland) {
    true => ('wl-paste', ['--no-newline', '--type', type]),
    false => ('xclip', ['-selection', 'clipboard', '-t', type, '-o']),
  });

  Future<void> _writeImage(Uint8List image, String mime) async {
    final (executable, arguments) = switch (_isWayland) {
      true => ('wl-copy', ['--type', mime]),
      false => ('xclip', ['-selection', 'clipboard', '-t', mime, '-i']),
    };

    final Process process;
    try {
      process = await _start(executable, arguments);
    } on ProcessException {
      throw const ClipboardToolMissingException();
    }

    unawaited(process.stdout.drain<void>());
    unawaited(process.stderr.drain<void>());
    process.stdin.add(image);
    await process.stdin.close();
  }

  Future<String?> _runText((String, List<String>) command) async {
    final bytes = await _runBytes(command);
    if (bytes == null) {
      return null;
    }

    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<Uint8List?> _runBytes((String, List<String>) command) async {
    if (_toolMissing) {
      return null;
    }

    final (executable, arguments) = command;
    final ProcessResult result;
    try {
      result = await _run(executable, arguments);
    } on ProcessException {
      _toolMissing = true;
      return null;
    }

    if (result.exitCode != 0) {
      return null;
    }

    return switch (result.stdout) {
      final Uint8List bytes => bytes,
      final List<int> bytes => Uint8List.fromList(bytes),
      final String text => Uint8List.fromList(utf8.encode(text)),
      _ => null,
    };
  }

  static String? _preferredImageType(List<String> types) {
    if (types.contains('image/png')) {
      return 'image/png';
    }

    for (final type in types) {
      if (type.startsWith('image/')) {
        return type;
      }
    }

    return null;
  }

  static Future<ProcessResult> _runForBytes(
    String executable,
    List<String> arguments,
  ) => Process.run(executable, arguments, stdoutEncoding: null);

  static Future<String?> _flutterReadText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  static Future<void> _flutterWriteText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}

/// Writing an image on Linux needs `wl-clipboard` (Wayland) or `xclip` (X11).
class ClipboardToolMissingException implements Exception {
  const ClipboardToolMissingException();

  @override
  String toString() =>
      'Install wl-clipboard (Wayland) or xclip (X11) to copy images.';
}
