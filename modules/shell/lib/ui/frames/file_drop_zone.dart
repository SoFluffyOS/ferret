import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/drop_targets_frame.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';

/// On computers: files dragged from the system over the window (or the
/// macOS popover, desktop window and menubar icon, through [menubar]) turn
/// the view they are over into one drop tile per device, then show how
/// sending goes. The zone must sit at its view's top left, since drag
/// positions are view coordinates.
class FileDropZone extends StatefulWidget {
  const FileDropZone({
    super.key,
    required this.child,
    this.menubar,
    this.footer,
  });

  final Widget child;

  /// A bar under [child] that drag tiles never cover, such as the
  /// popover's shelf, so things can be dropped on it too.
  final Widget? footer;

  /// The macOS menubar, whose popover and icon take the drags there.
  final FerretMenubar? menubar;

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  late final OsDropViewModel _viewModel;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  int? _viewId;

  /// desktop_drop finds no window on macOS, where the popover's drags come
  /// through [FileDropZone.menubar] instead.
  bool get _usesDesktopDrop => Platform.isWindows || Platform.isLinux;

  /// The menubar icon's drops are the popover's, which is the main view.
  bool get _isMainView =>
      _viewId ==
      WidgetsBinding.instance.platformDispatcher.implicitView?.viewId;

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
      sendText: _dispatchText,
      settings: ShellScope.read(context).featureContext.engine.settings,
      finder: RenderTreeDropTargetFinder(viewId: () => _viewId),
      onAllowedChanged: _onAllowedChanged,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewId = View.of(context).viewId;
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
      child: _withFooter(
        Stack(
          children: [
            widget.child,
            const Positioned.fill(child: DropTargetsFrame()),
          ],
        ),
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

  Widget _withFooter(Widget content) {
    final footer = widget.footer;
    if (footer == null) {
      return content;
    }

    return FooterOverlay(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Expanded(child: content),
          footer,
        ],
      ),
    );
  }

  void _onAllowedChanged(bool allowed) {
    final viewId = _viewId;
    if (viewId == null) {
      return;
    }

    unawaited(widget.menubar?.setDropAllowed(viewId, allowed: allowed));
  }

  /// Each view has its own zone, and a drag belongs to the one it is over.
  void _onPopoverDrag(PopoverDrag drag) {
    if (drag.viewId != _viewId) {
      return;
    }

    switch (drag) {
      case PopoverDragEntered(
        :final position,
        :final fileCount,
        :final kind,
        :final fromApp,
      ):
        _viewModel.enter(
          position,
          fileCount: fileCount,
          kind: switch (kind) {
            .files => .files,
            .text => .text,
            .link => .link,
          },
          fromApp: fromApp,
        );
      case PopoverDragMoved(:final position):
        _viewModel.move(position);
      case PopoverDragExited():
        _viewModel.exit();
      case PopoverDragDropped(:final paths, :final position):
        unawaited(_viewModel.drop(paths, position));
      case PopoverTextDropped(:final text, :final position, :final isLink):
        unawaited(_viewModel.dropText(text, position, isLink: isLink));
    }
  }

  /// Dropped on the icon before the popover opened: the only connected
  /// device, or the one used last, gets them while the icon shows the
  /// ring; otherwise the popover opens on the tiles to pick one.
  Future<void> _onIconDrop(List<String> paths) async {
    if (!_isMainView) {
      return;
    }

    final held = await _viewModel.dropBlind(paths);
    if (held) {
      await widget.menubar?.show();
    }
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

  /// Text goes to the first feature that takes text (the clipboard), a
  /// link to the first that takes links (Handoff).
  Future<Stream<FilesSendProgress>?> _dispatchText(
    String text,
    String? deviceId, {
    required bool isLink,
  }) async {
    if (!mounted) {
      return null;
    }

    final scope = ShellScope.read(context);
    final link = switch (isLink) {
      true => Uri.tryParse(text.trim()),
      false => null,
    };
    for (final feature in scope.features) {
      final progress = switch (link) {
        final link? => await feature.onLinkDropped(
          scope.featureContext,
          link,
          deviceId: deviceId,
        ),
        null => await feature.onTextDropped(
          scope.featureContext,
          text,
          deviceId: deviceId,
        ),
      };
      if (progress != null) {
        return progress;
      }
    }

    return null;
  }
}
