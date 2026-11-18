import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// On computers: files dragged onto the window go to the first feature that
/// takes them, the same as files dropped on the menubar icon.
class FileDropZone extends StatefulWidget {
  const FileDropZone({super.key, required this.child});

  final Widget child;

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _hovering = false;

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) {
      return widget.child;
    }

    return DropTarget(
      onDragEntered: (_) => setState(() => _hovering = true),
      onDragExited: (_) => setState(() => _hovering = false),
      onDragDone: (details) {
        setState(() => _hovering = false);
        final paths = [for (final file in details.files) file.path];
        unawaited(_dispatch(paths));
      },
      child: Stack(
        children: [
          widget.child,
          if (_hovering) const Positioned.fill(child: _DropOverlay()),
        ],
      ),
    );
  }

  Future<void> _dispatch(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }

    final scope = ShellScope.read(context);
    for (final feature in scope.features) {
      if (await feature.onFilesDropped(scope.featureContext, paths)) {
        return;
      }
    }
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return IgnorePointer(
      child: ColoredBox(
        color: palette.background.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: .min,
            children: [
              Icon(
                LucideIcons.download,
                size: Spacing.d36,
                color: palette.accent,
              ),
              Spacing.v8,
              Text(
                context.shellL10n.dropHere,
                style: context.fluffyTheme.typography.title3.copyWith(
                  color: palette.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
