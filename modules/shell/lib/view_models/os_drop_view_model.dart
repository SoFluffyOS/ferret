import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
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
    SettingsStore? settings,
    DropTargetFinder finder = const RenderTreeDropTargetFinder(),
    void Function(bool allowed)? onAllowedChanged,
    VoidCallback? onFinished,
    VoidCallback? onFailed,
    this.leaveGrace = const Duration(milliseconds: 600),
    this.sentHold = const Duration(milliseconds: 1500),
    this.undoWindow = const Duration(seconds: 3),
  }) : _devices = devices,
       _send = send,
       _sendText = sendText,
       _settings = settings,
       _finder = finder,
       _onAllowedChanged = onAllowedChanged,
       _onFinished = onFinished,
       _onFailed = onFailed;

  final List<DeviceDropTarget> Function() _devices;
  final SendDroppedFiles _send;
  final SendDroppedText? _sendText;
  final SettingsStore? _settings;

  /// Settings key of the device files were last dropped on, where a blind
  /// drop on the menubar icon goes.
  static const lastDeviceKey = 'shell.last_drop_device';
  final DropTargetFinder _finder;
  final void Function(bool allowed)? _onAllowedChanged;
  final VoidCallback? _onFinished;
  final VoidCallback? _onFailed;

  /// How long the targets stay after a drag leaves, since people overshoot.
  final Duration leaveGrace;

  /// How long "Sent" shows before going back to rest.
  final Duration sentHold;

  /// How long a quick drop on the menubar icon waits before it goes, so it
  /// can be undone.
  final Duration undoWindow;

  DropPhase _phase = const DropIdle();
  int _fileCount = 0;
  int _folderCount = 0;
  FilesDropTarget? _hovered;
  FilesDropTarget? _sendTarget;
  List<String> _paths = const [];
  DropKind _kind = .files;
  bool _fromApp = false;
  String _text = '';
  Timer? _timer;
  StreamSubscription<FilesSendProgress>? _progress;
  int _sendRun = 0;
  Timer? _undoTimer;
  DeviceDropTarget? _pendingTarget;

  DropPhase get phase => _phase;

  /// How many files are dragged, or 0 when the platform doesn't say.
  int get fileCount => _fileCount;

  /// How many of the dropped items are folders, known once dropped.
  int get folderCount => _folderCount;

  /// What is dragged, or was dropped.
  DropKind get kind => _kind;

  /// Whether the drag started in Ferret itself, such as an item off the
  /// shelf: the view keeps its page, and only the shelf and device rows
  /// take it, never a pane.
  bool get fromApp => _fromApp;

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

  void enter(
    Offset position, {
    int fileCount = 0,
    DropKind kind = .files,
    bool fromApp = false,
  }) {
    _timer?.cancel();
    if (!_isDragging) {
      _stopSending();
      _fileCount = fileCount;
      _kind = kind;
      _fromApp = fromApp;
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

    _setHovered(null);
    notifyListeners();
    _timer?.cancel();
    _timer = Timer(leaveGrace, cancel);
  }

  /// Dropped at [position]: sent to the target there, if it takes files.
  Future<void> drop(List<String> paths, Offset position) async {
    _locate(position);
    final target = _hovered;
    if (target case ReceiverDropTarget(:final receiver)) {
      cancel();
      if (paths.isNotEmpty) {
        await receiver.takeFiles(paths);
      }

      return;
    }

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
    if (target case ReceiverDropTarget(:final receiver)) {
      cancel();
      if (text.trim().isNotEmpty) {
        await receiver.takeText(
          text,
          isLink: DropKind.ofText(text, isLink: isLink) == .link,
        );
      }

      return;
    }

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

  /// Where a quick drop on the menubar icon goes now: the only connected
  /// device, or with several the one files were last dropped on while it
  /// is connected. Null when Ferret would have to guess.
  DeviceDropTarget? get blindTarget =>
      blindTargetOf(_devices(), _settings?.get<String>(lastDeviceKey));

  static DeviceDropTarget? blindTargetOf(
    List<DeviceDropTarget> devices,
    String? lastId,
  ) {
    final connected = [
      for (final device in devices)
        if (device.isConnected) device,
    ];

    return switch (connected) {
      [final only] => only,
      _ => connected.where((device) => device.deviceId == lastId).firstOrNull,
    };
  }

  /// The device a quick drop on the icon is about to go to, while it can
  /// still be undone.
  DeviceDropTarget? get pendingTarget => _pendingTarget;

  /// Files dropped on the menubar icon without waiting for the popover,
  /// as [mode] says. Sent to [blindTarget] after [undoWindow], unless
  /// [undoIconDrop] comes first; with no target the targets show so
  /// people pick one rather than Ferret guessing. [keeper] keeps them for
  /// [IconDrop.shelf].
  Future<IconDropOutcome> dropOnIcon(
    List<String> paths, {
    IconDrop mode = .sendToLast,
    DropReceiver? keeper,
  }) async {
    if (paths.isEmpty) {
      return const IconDropRefused();
    }

    if ((mode, keeper) case (.shelf, final keeper?)) {
      final kept = await keeper.takeFiles(paths);
      return switch (kept) {
        true => const IconDropKept(),
        false => const IconDropRefused(),
      };
    }

    final target = blindTarget;
    if (mode == .ask || target == null) {
      hold(paths);
      return const IconDropHeld();
    }

    undoIconDrop();
    _pendingTarget = target;
    _undoTimer = Timer(undoWindow, () {
      _pendingTarget = null;
      _kind = .files;
      _paths = paths;
      unawaited(_sendTo(target));
    });
    notifyListeners();
    return IconDropPending(target, paths.length);
  }

  /// Text or a link dropped on the icon: a blind send would be a guess,
  /// so it stays on the shelf ([keeper]) when there is one.
  Future<IconDropOutcome> dropTextOnIcon(
    String text, {
    required bool isLink,
    DropReceiver? keeper,
  }) async {
    if (keeper == null || text.trim().isEmpty) {
      return const IconDropRefused();
    }

    final kept = await keeper.takeText(
      text,
      isLink: DropKind.ofText(text, isLink: isLink) == .link,
    );
    return switch (kept) {
      true => const IconDropKept(),
      false => const IconDropRefused(),
    };
  }

  /// Stops a quick drop that hasn't gone yet. False when there was none.
  bool undoIconDrop() {
    final timer = _undoTimer;
    _undoTimer = null;
    if (timer == null || !timer.isActive) {
      return false;
    }

    timer.cancel();
    _pendingTarget = null;
    notifyListeners();
    return true;
  }

  /// Shows the targets for [paths] already dropped, to pick one by tapping.
  void hold(List<String> paths) {
    _timer?.cancel();
    _stopSending();
    _paths = paths;
    _kind = .files;
    _fromApp = false;
    _fileCount = paths.length;
    _setHovered(null);
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
    _folderCount = 0;
    _fromApp = false;
    _setHovered(null);
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
    _folderCount = switch (_kind) {
      .files => _paths.where(FileSystemEntity.isDirectorySync).length,
      .text || .link => 0,
    };
    _setHovered(null);
    _sendTarget = target;
    _phase = const DropSending(0);
    notifyListeners();

    final deviceId = switch (target) {
      DeviceDropTarget(:final deviceId) => deviceId,
      AllDevicesDropTarget() ||
      PaneDropTarget() ||
      ReceiverDropTarget() => null,
    };
    if (deviceId != null && _kind == .files) {
      unawaited(_settings?.set(lastDeviceKey, deviceId));
    }

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
    final found = _finder.find(position);
    final target = switch (found) {
      PaneDropTarget() when _fromApp => null,
      _ => found,
    };
    final changed = target != _hovered;
    _setHovered(target);
    return changed;
  }

  /// Tells a feature's receiver when the drag comes over it or leaves.
  void _setHovered(FilesDropTarget? target) {
    final before = _hovered;
    _hovered = target;
    if (before == target) {
      return;
    }

    if (before case ReceiverDropTarget(:final receiver)) {
      receiver.hover(over: false);
    }

    if (target case ReceiverDropTarget(:final receiver)) {
      receiver.hover(over: true);
    }
  }

  void _reportAllowed() {
    _onAllowedChanged?.call(_hovered?.acceptsDrop ?? false);
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _timer?.cancel();
    _stopSending();
    super.dispose();
  }
}
