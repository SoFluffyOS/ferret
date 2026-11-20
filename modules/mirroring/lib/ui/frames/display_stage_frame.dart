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
/// edge with the ways out. On a phone or tablet, fingers are the mouse
/// and a small handle at the top brings the bar. Before the first picture
/// it says it is connecting; after the last, how it ended.
class DisplayStageFrame extends StatefulWidget {
  const DisplayStageFrame({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.onClose,
    this.onToggleFullScreen,
    this.onExitFullScreen,
  });

  final String deviceId;
  final String deviceName;

  /// Closes what hosts the display, which stops it.
  final VoidCallback onClose;

  /// Null where the display always fills the screen: a phone's.
  final VoidCallback? onToggleFullScreen;
  final VoidCallback? onExitFullScreen;

  @override
  State<DisplayStageFrame> createState() => _DisplayStageFrameState();
}

class _DisplayStageFrameState extends State<DisplayStageFrame> {
  /// How close to the top edge the pointer brings the bar.
  static final double _edge = Spacing.d4;

  /// How long the bar a finger brought stays.
  static const _barTime = Duration(seconds: 6);

  bool _barShown = false;
  Timer? _hideBar;

  @override
  void dispose() {
    _hideBar?.cancel();
    super.dispose();
  }

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
        title: l10n.displayViewEnded(name, end.name, DisplayHere.value),
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
    final touch = DisplayHere.isTouch;
    final top = switch (touch) {
      true => MediaQuery.paddingOf(context).top,
      false => 0.0,
    };
    final toggleFullScreen = widget.onToggleFullScreen;

    return Listener(
      behavior: .translucent,
      onPointerHover: (event) => _onHover(event.localPosition.dy),
      child: Stack(
        fit: .expand,
        children: [
          Listener(
            onPointerDown: (_) => _showBar(false),
            child: MirrorSurface(
              picture: picture,
              builder: (context, shown) => MirrorInput(
                abilities: abilities,
                onAction: viewModel.perform,
                onEscape: widget.onExitFullScreen,
                touchPointsPerPixel: _pointsPerPixel(context),
                child: shown,
              ),
            ),
          ),
          if (touch && !_barShown)
            Positioned(
              top: top,
              left: 0,
              right: 0,
              child: Center(
                child: _Handle(
                  label: l10n.displayHandleLabel(widget.deviceName),
                  onTap: () => _showBar(true),
                ),
              ),
            ),
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: DisplayBar(
              shown: _barShown,
              onLeave: () => _showBar(false),
              title: l10n.displayBarTitle(widget.deviceName),
              hint: switch (touch) {
                true => l10n.displayTouchHint,
                false => l10n.displayEscHint,
              },
              fullScreenLabel: switch ((toggleFullScreen, isFullScreen)) {
                (null, _) => null,
                (_, true) => l10n.exitFullScreen,
                (_, false) => l10n.fullScreen,
              },
              stopLabel: l10n.stop,
              onFullScreen: toggleFullScreen,
              onStop: stop,
            ),
          ),
        ],
      ),
    );
  }

  /// Points of the computer's display per pixel here: it is made the
  /// size of this screen, at 2 pixels per point on a sharp one.
  double _pointsPerPixel(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final scale = DisplayScreen.panelOf(
      physicalSize: Size.zero,
      devicePixelRatio: ratio,
      refreshRate: 0,
    ).scale;
    return ratio / scale;
  }

  void _onHover(double y) {
    if (y <= _edge) {
      _showBar(true);
    }
  }

  void _showBar(bool shown) {
    _hideBar?.cancel();
    if (shown && DisplayHere.isTouch) {
      _hideBar = Timer(_barTime, () => _showBar(false));
    }

    if (_barShown == shown || !mounted) {
      return;
    }

    setState(() => _barShown = shown);
  }
}

/// A small grip at the top edge of a computer's display on a phone: the
/// way to its bar, where a pointer would reach the edge on a computer.
class _Handle extends StatelessWidget {
  const _Handle({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: .opaque,
        onTap: onTap,
        child: SizedBox(
          width: Spacing.d64,
          height: Spacing.d32,
          child: Center(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                // Dark on a halo of light (or the other way round), so it
                // shows on whatever the computer draws under it.
                color: palette.text.withValues(alpha: 0.6),
                shape: const StadiumBorder(),
                shadows: [
                  BoxShadow(
                    color: palette.surface.withValues(alpha: 0.8),
                    blurRadius: Spacing.d2,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: SizedBox(width: Spacing.d40, height: Spacing.d6),
            ),
          ),
        ),
      ),
    );
  }
}
