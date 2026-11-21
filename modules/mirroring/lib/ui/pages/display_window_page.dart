import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/ui/frames/frames.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// Another computer's extra display in a window of its own, full screen
/// from the start. Closing the window stops being that computer's
/// display; when it ends, the window leaves full screen to say how.
///
/// On a phone or tablet it is a page instead: the whole screen with the
/// system bars hidden, kept on, and held the way it was when the display
/// was made for it. Back asks before it stops.
class DisplayWindowPage extends StatefulWidget {
  const DisplayWindowPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.onClose,
  });

  final String deviceId;
  final String deviceName;

  /// Closes the window, or the page.
  final VoidCallback onClose;

  @override
  State<DisplayWindowPage> createState() => _DisplayWindowPageState();
}

class _DisplayWindowPageState extends State<DisplayWindowPage> {
  late final ViewerViewModel _viewModel;
  late final StageWindowViewModel _window;
  final bool _touch = DisplayHere.isTouch;
  bool _heldStill = false;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ViewerViewModel>()..openStage(widget.deviceId);
    _window = context.read<StageWindowViewModel>();
    _viewModel.addListener(_onViewer);
    if (_touch) {
      unawaited(SystemChrome.setEnabledSystemUIMode(.immersiveSticky));
      unawaited(DisplayScreen.keepOn(true));
      _lifecycle = AppLifecycleListener(
        onHide: () => _setHidden(true),
        onShow: () => _setHidden(false),
      );
    }
  }

  /// Home or another app on top: the display goes on unseen, and the
  /// screen may turn off.
  void _setHidden(bool hidden) {
    _viewModel.setHidden(hidden);
    final ended = _viewModel.sessionFor(widget.deviceId)?.phase == .ended;
    unawaited(DisplayScreen.keepOn(!hidden && !ended));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_touch || _heldStill) {
      return;
    }

    _heldStill = true;
    // The display was made this shape: turning the phone would squash it.
    final orientations = switch (MediaQuery.orientationOf(context)) {
      .portrait => const [DeviceOrientation.portraitUp],
      .landscape => const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    };
    unawaited(SystemChrome.setPreferredOrientations(orientations));
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewer);
    _lifecycle?.dispose();
    if (_lifecycle != null) {
      _viewModel.setHidden(false);
    }

    unawaited(_viewModel.leaveStage(widget.deviceId));
    if (_touch) {
      unawaited(SystemChrome.setEnabledSystemUIMode(.edgeToEdge));
      unawaited(SystemChrome.setPreferredOrientations(const []));
      unawaited(DisplayScreen.keepOn(false));
    }

    super.dispose();
  }

  void _onViewer() {
    final ended = _viewModel.sessionFor(widget.deviceId)?.phase == .ended;
    if (ended && _window.isFullScreen) {
      unawaited(_window.setFullScreen(false));
    }

    if (ended && _touch) {
      unawaited(DisplayScreen.keepOn(false));
    }
  }

  /// Back on a phone: a display that shows asks first, anything else just
  /// goes.
  Future<void> _back() async {
    final phase = _viewModel.sessionFor(widget.deviceId)?.phase;
    final showing = phase == .streaming || phase == .starting;
    if (!showing) {
      if (phase != .ended) {
        unawaited(_viewModel.stop());
      }

      widget.onClose();
      return;
    }

    final l10n = context.mirroringL10n;
    final answer = await FerretConfirmDialog.show(
      context,
      title: l10n.displayStopTitle(widget.deviceName),
      message: l10n.displayStopBody(widget.deviceName),
      negativeText: l10n.keepShowing,
      positiveText: l10n.stop,
    );
    if (answer != .positive || !mounted) {
      return;
    }

    unawaited(_viewModel.stop());
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    if (_touch) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            unawaited(_back());
          }
        },
        child: ColoredBox(
          color: context.palette.background,
          child: DisplayStageFrame(
            deviceId: widget.deviceId,
            deviceName: widget.deviceName,
            onClose: widget.onClose,
          ),
        ),
      );
    }

    return ColoredBox(
      color: context.palette.background,
      child: DisplayStageFrame(
        deviceId: widget.deviceId,
        deviceName: widget.deviceName,
        onClose: widget.onClose,
        onToggleFullScreen: () => unawaited(_window.toggleFullScreen()),
        onExitFullScreen: () => unawaited(_window.setFullScreen(false)),
      ),
    );
  }
}
