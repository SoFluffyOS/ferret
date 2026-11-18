import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/drop_targets_frame.dart';
import 'package:shell/view_models/view_models.dart';

/// On computers: files dragged from the system over the window (or the
/// macOS popover and menubar icon, through [menubar]) turn the window into
/// one drop tile per device, then show how sending goes. The view must sit
/// at the window's top left, since drag positions are window coordinates.
class FileDropZone extends StatefulWidget {
  const FileDropZone({super.key, required this.child, this.menubar});

  final Widget child;

  /// The macOS menubar, whose popover and icon take the drags there.
  final FerretMenubar? menubar;

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  late final OsDropViewModel _viewModel;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// desktop_drop finds no window on macOS, where the popover's drags come
  /// through [FileDropZone.menubar] instead.
  bool get _usesDesktopDrop => Platform.isWindows || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    final host = context.read<EngineHost>();
    final menubar = widget.menubar;
    _viewModel = OsDropViewModel(
      devices: () => [
        for (final status in host.devices)
          DeviceDropTarget(
            deviceId: status.device.id,
            name: status.device.name,
            isConnected: status.isConnected,
          ),
      ],
      send: _dispatch,
      onAllowedChanged: (allowed) =>
          unawaited(menubar?.setDropAllowed(allowed)),
      onFinished: () => unawaited(menubar?.closeIfOpenedByDrag()),
      onFailed: () => unawaited(menubar?.show()),
    );
    if (menubar != null) {
      _subscriptions
        ..add(menubar.drags.listen(_onPopoverDrag))
        ..add(menubar.drops.listen(_onIconDrop));
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ChangeNotifierProvider.value(
      value: _viewModel,
      child: Stack(
        children: [
          widget.child,
          const Positioned.fill(child: DropTargetsFrame()),
        ],
      ),
    );
    if (!_usesDesktopDrop) {
      return content;
    }

    return DropTarget(
      onDragEntered: (details) => _viewModel.enter(details.localPosition),
      onDragUpdated: (details) => _viewModel.move(details.localPosition),
      onDragExited: (_) => _viewModel.exit(),
      onDragDone: (details) => unawaited(
        _viewModel.drop([
          for (final file in details.files) file.path,
        ], details.localPosition),
      ),
      child: content,
    );
  }

  void _onPopoverDrag(PopoverDrag drag) {
    switch (drag) {
      case PopoverDragEntered(:final position, :final fileCount):
        _viewModel.enter(position, fileCount: fileCount);
      case PopoverDragMoved(:final position):
        _viewModel.move(position);
      case PopoverDragExited():
        _viewModel.exit();
      case PopoverDragDropped(:final paths, :final position):
        unawaited(_viewModel.drop(paths, position));
    }
  }

  /// Dropped on the icon before the popover opened: one device connected
  /// gets them; otherwise the popover opens on the tiles to pick one.
  Future<void> _onIconDrop(List<String> paths) async {
    final connected = context
        .read<EngineHost>()
        .devices
        .where((status) => status.isConnected)
        .length;
    if (connected != 1) {
      await widget.menubar?.show();
    }

    await _viewModel.dropBlind(paths);
  }

  Future<Stream<FilesSendProgress>?> _dispatch(
    List<String> paths,
    String? deviceId,
  ) async {
    if (!mounted) {
      return null;
    }

    final scope = ShellScope.read(context);
    for (final feature in scope.features) {
      final progress = await feature.onFilesDropped(
        scope.featureContext,
        paths,
        deviceId: deviceId,
      );
      if (progress != null) {
        return progress;
      }
    }

    return null;
  }
}
