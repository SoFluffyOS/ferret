import 'package:engine/engine.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';

/// Tells a screen reader when [status] connects, starts reconnecting or
/// drops: "Pixel 7: Connected". A status line that only changes its words
/// ("Last seen 3 min ago", a battery level) stays quiet, and so does a
/// page under another one.
class ConnectionAnnouncer extends StatefulWidget {
  const ConnectionAnnouncer({
    super.key,
    required this.status,
    required this.child,
  });

  final DeviceStatus status;
  final Widget child;

  @override
  State<ConnectionAnnouncer> createState() => _ConnectionAnnouncerState();
}

enum _Link { connected, reconnecting, offline }

class _ConnectionAnnouncerState extends State<ConnectionAnnouncer> {
  @override
  void didUpdateWidget(ConnectionAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final link = _linkOf(widget.status);
    if (link == _linkOf(oldWidget.status)) {
      return;
    }

    if (ModalRoute.of(context)?.isCurrent == false) {
      return;
    }

    final l10n = context.shellL10n;
    final word = switch (link) {
      .connected => l10n.deviceConnected,
      .reconnecting => l10n.deviceReconnecting,
      .offline => l10n.deviceOffline,
    };
    SemanticsService.sendAnnouncement(
      View.of(context),
      l10n.deviceStatusSpoken(widget.status.device.name, word),
      Directionality.of(context),
    ).ignore();
  }

  _Link _linkOf(DeviceStatus status) {
    if (status.isConnected) {
      return .connected;
    }

    if (status.isReconnecting) {
      return .reconnecting;
    }

    return .offline;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
