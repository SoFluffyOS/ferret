import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';

/// Names the window after what it shows ("Pixel 9 — Messages"), never just
/// after the app. [onTitle] hears each new title.
class WindowTitleFrame extends StatefulWidget {
  const WindowTitleFrame({
    super.key,
    required this.onTitle,
    required this.child,
  });

  final void Function(String title) onTitle;
  final Widget child;

  @override
  State<WindowTitleFrame> createState() => _WindowTitleFrameState();
}

class _WindowTitleFrameState extends State<WindowTitleFrame> {
  String? _told;

  @override
  Widget build(BuildContext context) {
    final title = _title(context);
    if (title != _told) {
      _told = title;
      scheduleMicrotask(() => widget.onTitle(title));
    }

    return widget.child;
  }

  String _title(BuildContext context) {
    final title = PaneTitles.of(context);

    return switch (title) {
      (deviceName: null, :final place, isOverview: _) => place,
      (:final String deviceName, place: _, isOverview: true) => deviceName,
      (:final String deviceName, :final place, isOverview: false) =>
        context.shellL10n.windowTitleSection(deviceName, place),
    };
  }
}
