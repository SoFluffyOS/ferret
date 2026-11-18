import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';

/// Sends [paths] to [deviceId], or to every connected device when it is
/// null. Null back means nobody took them.
typedef SendDroppedFiles = Future<Stream<FilesSendProgress>?> Function(
  List<String> paths,
  String? deviceId,
);

/// Sends [text] to [deviceId], or to every connected device when it is
/// null: to its clipboard, or opened there when [isLink]. Null back means
/// nobody took it.
typedef SendDroppedText = Future<Stream<FilesSendProgress>?> Function(
  String text,
  String? deviceId, {
  required bool isLink,
});

/// Files, text or a link dragged from the system (Finder, a browser,
/// Explorer, a file manager) over the app's window or the macOS popover:
/// which device is under the pointer, then how sending to it goes. Files go
/// with Files, text to the device's clipboard, a link opens there. Fed by
/// whichever drag source the platform has.
class OsDropViewModel extends ChangeNotifier {
  OsDropViewModel({
    required List<DeviceDropTarget> Function() devices,
    required SendDroppedFiles send,
    SendDroppedText? sendText,
    DropTargetFinder finder = const RenderTreeDropTargetFinder(),
    void Function(bool allowed)? onAllowedChanged,
    VoidCallback? onFinished,
    VoidCallback? onFailed,
    this.leaveGrace = const Duration(milliseconds: 600),
    this.sentHold = const Duration(milliseconds: 1500),
  }) : _devices = devices,
       _send = send,
       _sendText = sendText,
       _finder = finder,
       _onAllowedChanged = onAllowedChanged,
       _onFinished = onFinished,
       _onFailed = onFailed;

  final List<DeviceDropTarget> Function() _devices;
  final SendDroppedFiles _send;
  final SendDroppedText? _sendText;
  final DropTargetFinder _finder;
  final void Function(bool allowed)? _onAllowedChanged;
  final VoidCallback? _onFinished;
  final VoidCallback? _onFailed;

  /// How long the targets stay after a drag leaves, since people overshoot.
  final Duration leaveGrace;

  /// How long "Sent" shows before going back to rest.
  final Duration sentHold;

  DropPhase _phase = const DropIdle();
  int _fileCount = 0;
  FilesDropTarget? _hovered;
  FilesDropTarget? _sendTarget;
  List<String> _paths = const [];
  DropKind _kind = .files;
  String _text = '';
  Timer? _timer;
  StreamSubscription<FilesSendProgress>? _progress;
  int _sendRun = 0;

  DropPhase get phase => _phase;

  /// How many files are dragged, or 0 when the platform doesn't say.
  int get fileCount => _fileCount;

  /// What is dragged, or was dropped.
  DropKind get kind => _kind;

  /// The target under the pointer, highlighted while dragging.
  FilesDropTarget? get hovered => _hovered;

  /// Where the files are going, once dropped.
  FilesDropTarget? get sendTarget => _sendTarget;

  bool get _isDragging => switch (_phase) {
    DropChoosing(held: false) => true,
    _ => false,
  };

  bool get _isHeld => switch (_phase) {
    DropChoosing(held: true) => true,
    _ => false,
  };

  void enter(Offset position, {int fileCount = 0, DropKind kind = .files}) {
    _timer?.cancel();
    if (!_isDragging) {
      _stopSending();
      _fileCount = fileCount;
      _kind = kind;
    }

    _phase = const DropChoosing();
    _locate(position);
    _reportAllowed();
    notifyListeners();
  }

  /// Notifies only when the target under the pointer changes, so a drag
  /// doesn't rebuild the app on every move.
  void move(Offset position) {
    if (_phase is! DropChoosing) {
      enter(position);
      return;
    }

    final changed = _locate(position);
    if (!changed) {
      return;
    }

    _reportAllowed();
    notifyListeners();
  }

  /// The drag left: the targets stay for [leaveGrace], then go.
  void exit() {
    if (!_isDragging) {
      return;
    }

    _hovered = null;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer(leaveGrace, cancel);
  }

  /// Dropped at [position]: sent to the target there, if it takes files.
  Future<void> drop(List<String> paths, Offset position) async {
    _locate(position);
    final target = _hovered;
    if (paths.isEmpty || target == null || !target.acceptsDrop) {
      cancel();
      return;
    }

    _kind = .files;
    _paths = paths;
    await _sendTo(target);
  }

  /// Text, or a link when [isLink], dropped at [position]: sent to the
  /// target there. A lone web address dropped as text counts as a link.
  Future<void> dropText(
    String text,
    Offset position, {
    required bool isLink,
  }) async {
    _locate(position);
    final target = _hovered;
    if (text.trim().isEmpty ||
        _sendText == null ||
        target == null ||
        !target.acceptsDrop) {
      cancel();
      return;
    }

    _kind = DropKind.ofText(text, isLink: isLink);
    _text = text;
    _fileCount = 1;
    await _sendTo(target);
  }

  /// Files dropped on the menubar icon without waiting for the popover:
  /// with one device connected they go straight to it; otherwise the
  /// targets show so people pick one rather than Ferret guessing.
  Future<void> dropBlind(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }

    final connected = [
      for (final device in _devices())
        if (device.isConnected) device,
    ];
    if (connected case [final only]) {
      _kind = .files;
      _paths = paths;
      await _sendTo(only);
      return;
    }

    hold(paths);
  }

  /// Shows the targets for [paths] already dropped, to pick one by tapping.
  void hold(List<String> paths) {
    _timer?.cancel();
    _stopSending();
    _paths = paths;
    _kind = .files;
    _fileCount = paths.length;
    _hovered = null;
    _phase = const DropChoosing(held: true);
    notifyListeners();
  }

  /// A target tapped while files are held.
  Future<void> pick(FilesDropTarget target) async {
    if (!_isHeld || !target.acceptsDrop) {
      return;
    }

    await _sendTo(target);
  }

  Future<void> retry() async {
    final target = _sendTarget;
    final hasSomething = switch (_kind) {
      .files => _paths.isNotEmpty,
      .text || .link => _text.isNotEmpty,
    };
    if (target == null || !hasSomething) {
      return;
    }

    await _sendTo(target);
  }

  /// Back to rest. A transfer already going keeps going.
  void cancel() {
    _timer?.cancel();
    _stopSending();
    if (_phase is DropIdle) {
      return;
    }

    _phase = const DropIdle();
    _fileCount = 0;
    _hovered = null;
    _sendTarget = null;
    _paths = const [];
    _text = '';
    _kind = .files;
    _onAllowedChanged?.call(true);
    notifyListeners();
  }

  /// Sends what was dropped, [_paths] or [_text] by [_kind], to [dropped].
  Future<void> _sendTo(FilesDropTarget dropped) async {
    _timer?.cancel();
    _stopSending();
    final run = _sendRun;
    final target = switch (dropped) {
      PaneDropTarget(:final target) => target,
      _ => dropped,
    };
    _fileCount = switch (_kind) {
      .files => _paths.length,
      .text || .link => 1,
    };
    _hovered = null;
    _sendTarget = target;
    _phase = const DropSending(0);
    notifyListeners();

    final deviceId = switch (target) {
      DeviceDropTarget(:final deviceId) => deviceId,
      AllDevicesDropTarget() || PaneDropTarget() => null,
    };
    final progress = await _dispatch(deviceId);
    if (run != _sendRun) {
      return;
    }

    if (progress == null) {
      _fail('');
      return;
    }

    _progress = progress.listen(_onProgress);
  }

  Future<Stream<FilesSendProgress>?> _dispatch(String? deviceId) async {
    final sendText = _sendText;

    return switch ((_kind, sendText)) {
      (.files, _) => _send(_paths, deviceId),
      (.text || .link, final sendText?) => sendText(
        _text,
        deviceId,
        isLink: _kind == .link,
      ),
      (.text || .link, null) => null,
    };
  }

  void _onProgress(FilesSendProgress progress) {
    switch (progress) {
      case FilesSending(:final fraction):
        _phase = DropSending(fraction);
        notifyListeners();
      case FilesSent():
        _phase = const DropSent();
        notifyListeners();
        _timer = Timer(sentHold, () {
          cancel();
          _onFinished?.call();
        });
      case FilesSendFailed(:final reason):
        _fail(reason);
    }
  }

  void _fail(String reason) {
    _phase = DropFailed(reason);
    notifyListeners();
    _onFailed?.call();
  }

  /// Stops listening to a send in flight, so a late answer is ignored.
  void _stopSending() {
    _sendRun++;
    unawaited(_progress?.cancel());
    _progress = null;
  }

  bool _locate(Offset position) {
    final target = _finder.find(position);
    final changed = target != _hovered;
    _hovered = target;
    return changed;
  }

  void _reportAllowed() {
    _onAllowedChanged?.call(_hovered?.acceptsDrop ?? false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopSending();
    super.dispose();
  }
}
