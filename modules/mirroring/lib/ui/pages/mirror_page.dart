import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/frames/frames.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Hosts the mirror stage where it has no window of its own: the device's
/// name and the way its screen arrives on top, the stage underneath. In a
/// window's pane the stage is all there is, because the window is named
/// after it already. Leaving the page stops sharing, so Back asks first
/// while a screen is shown. Nothing shares from a page that is closed.
class MirrorPage extends StatefulWidget {
  const MirrorPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
    this.clock,
  });

  final String deviceId;
  final String deviceName;
  final DateTime Function()? clock;

  @override
  State<MirrorPage> createState() => _MirrorPageState();
}

class _MirrorPageState extends State<MirrorPage> {
  late final ViewerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ViewerViewModel>()..openStage(widget.deviceId);
    unawaited(_viewModel.refreshWindow());
  }

  @override
  void dispose() {
    unawaited(_viewModel.leaveStage(widget.deviceId));
    super.dispose();
  }

  /// Goes back where the page was pushed. In a pane there is nowhere to
  /// go back to: the stage lets go, and the section shows its launcher.
  void _close() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      unawaited(navigator.maybePop());
      return;
    }

    unawaited(_viewModel.leaveStage(widget.deviceId));
  }

  Future<void> _back() async {
    final session = _viewModel.sessionFor(widget.deviceId);
    final isLive = session?.isMirroring ?? false;
    if (!isLive) {
      _close();
      return;
    }

    final l10n = context.mirroringL10n;
    final isCamera = session?.isCamera ?? false;
    final answer = await ConfirmDialog.show(
      context,
      title: switch (isCamera) {
        true => l10n.cameraLeaveTitle(widget.deviceName),
        false => l10n.leaveTitle(widget.deviceName),
      },
      message: switch (isCamera) {
        true => l10n.cameraLeaveBody,
        false => l10n.leaveBody,
      },
      negativeText: switch (isCamera) {
        true => l10n.cameraKeep,
        false => l10n.keepShowing,
      },
      positiveText: l10n.stop,
    );
    if (answer == .positive && mounted) {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFullScreen = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.isFullScreen,
    );
    final way = context.select<ViewerViewModel, MirrorWay?>((viewModel) {
      final session = viewModel.sessionFor(widget.deviceId);
      if (session == null || !session.isLive) {
        return null;
      }

      return session.way;
    });
    final l10n = context.mirroringL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final hasBar = !isFullScreen && Navigator.of(context).canPop();

    return ColoredBox(
      color: palette.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            if (hasBar)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  Spacing.d12,
                  Spacing.d12,
                  Spacing.d12,
                  Spacing.d4,
                ),
                child: Row(
                  children: [
                    Tappable(
                      tooltip: l10n.back,
                      onTap: () => unawaited(_back()),
                      child: Padding(
                        padding: EdgeInsets.all(Spacing.d4),
                        child: DirectionalIcon(
                          LucideIcons.chevronLeft,
                          size: Spacing.d20,
                          color: palette.text,
                        ),
                      ),
                    ),
                    Spacing.h4,
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: widget.deviceName,
                          children: [
                            if (way != null)
                              TextSpan(
                                text: '  ${l10n.wayName(way)}',
                                style: typography.base2.copyWith(
                                  color: palette.mutedText,
                                ),
                              ),
                          ],
                        ),
                        style: typography.title2.copyWith(color: palette.text),
                        overflow: .ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: MirrorStageFrame(
                deviceId: widget.deviceId,
                deviceName: widget.deviceName,
                onClose: _close,
                clock: widget.clock,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
