import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Another computer's extra display, filling this screen: its picture
/// edge to edge, the pointer and keys going there, and a bar at the top
/// edge with the ways out. Before the first picture it says it is
/// connecting; after the last, how it ended.
class DisplayStageFrame extends StatefulWidget {
  const DisplayStageFrame({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.onClose,
    required this.onToggleFullScreen,
    required this.onExitFullScreen,
  });

  final String deviceId;
  final String deviceName;

  /// Closes what hosts the display, which stops it.
  final VoidCallback onClose;
  final VoidCallback onToggleFullScreen;
  final VoidCallback onExitFullScreen;

  @override
  State<DisplayStageFrame> createState() => _DisplayStageFrameState();
}

class _DisplayStageFrameState extends State<DisplayStageFrame> {
  /// How close to the top edge the pointer brings the bar.
  static final double _edge = Spacing.d4;

  bool _barShown = false;

  @override
  Widget build(BuildContext context) {
    final phase = context.select<ViewerViewModel, ViewPhase?>(
      (viewModel) => viewModel.sessionFor(widget.deviceId)?.phase,
    );
    final end = context.select<ViewerViewModel, ViewEnd?>(
      (viewModel) => viewModel.sessionFor(widget.deviceId)?.end,
    );
    final picture = context.select<ViewerViewModel, MirrorPicture?>(
      (viewModel) => viewModel.picture,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    final name = widget.deviceName;
    void stop() {
      unawaited(viewModel.stop());
      widget.onClose();
    }

    final holdsPicture = phase == .streaming || phase == .starting;
    if (holdsPicture && picture != null) {
      return _live(context, picture, stop);
    }

    if (phase == .ended && end != null) {
      return MirrorMessage(
        icon: LucideIcons.monitorOff,
        title: l10n.displayViewEnded(name, end.name, ThisComputer.here),
        actions: [MessageAction(label: l10n.close, onPressed: widget.onClose)],
      );
    }

    return MirrorMessage(
      icon: LucideIcons.monitor,
      tone: .accent,
      title: l10n.displayConnectingTitle(name),
      body: l10n.displayConnectingBody(name),
      actions: [MessageAction(label: l10n.cancel, onPressed: stop)],
    );
  }

  Widget _live(BuildContext context, MirrorPicture picture, VoidCallback stop) {
    final abilities = context.select<ViewerViewModel, Set<ControlAbility>>(
      (viewModel) => viewModel.abilities,
    );
    final isFullScreen = context.select<StageWindowViewModel, bool>(
      (window) => window.isFullScreen,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;

    return Listener(
      behavior: .translucent,
      onPointerHover: (event) => _onHover(event.localPosition.dy),
      child: Stack(
        fit: .expand,
        children: [
          MirrorSurface(
            picture: picture,
            builder: (context, shown) => MirrorInput(
              abilities: abilities,
              onAction: viewModel.perform,
              onEscape: widget.onExitFullScreen,
              child: shown,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DisplayBar(
              shown: _barShown,
              onLeave: () => _showBar(false),
              title: l10n.displayBarTitle(widget.deviceName),
              hint: l10n.displayEscHint,
              fullScreenLabel: switch (isFullScreen) {
                true => l10n.exitFullScreen,
                false => l10n.fullScreen,
              },
              stopLabel: l10n.stop,
              onFullScreen: widget.onToggleFullScreen,
              onStop: stop,
            ),
          ),
        ],
      ),
    );
  }

  void _onHover(double y) {
    if (y <= _edge) {
      _showBar(true);
    }
  }

  void _showBar(bool shown) {
    if (_barShown == shown) {
      return;
    }

    setState(() => _barShown = shown);
  }
}
