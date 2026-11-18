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
/// name and the way its screen arrives on top, the stage underneath.
/// Leaving the page stops sharing, so Back asks first while a screen is
/// shown. Nothing shares from a page that is closed.
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

  void _close() => unawaited(Navigator.of(context).maybePop());

  Future<void> _back() async {
    final isLive = _viewModel.sessionFor(widget.deviceId)?.isMirroring ?? false;
    if (!isLive) {
      _close();
      return;
    }

    final l10n = context.mirroringL10n;
    final answer = await ConfirmDialog.show(
      context,
      title: l10n.leaveTitle(widget.deviceName),
      message: l10n.leaveBody,
      negativeText: l10n.keepShowing,
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

    return ColoredBox(
      color: palette.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            if (!isFullScreen)
              Padding(
                padding: EdgeInsets.fromLTRB(
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
                        child: Icon(
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
