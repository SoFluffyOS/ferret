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

/// The body of the mirror page: the phone's screen once it shows, and
/// before and after that, where things stand and what to do.
class MirrorViewFrame extends StatelessWidget {
  const MirrorViewFrame({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  final String deviceId;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final phase = context.select<ViewerViewModel, ViewPhase?>(
      (viewModel) => _sessionOf(viewModel)?.phase,
    );
    final end = context.select<ViewerViewModel, ViewEnd?>(
      (viewModel) => _sessionOf(viewModel)?.end,
    );
    final picture = context.select<ViewerViewModel, MirrorPicture?>(
      (viewModel) => viewModel.picture,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;

    if (phase == .ended && end != null) {
      return MirrorMessage(
        icon: _iconOf(end),
        tone: _toneOf(end),
        title: l10n.endTitle(end, deviceName),
        body: l10n.endBody(end, deviceName),
        actionLabel: l10n.tryAgain,
        onAction: () => unawaited(viewModel.start(deviceId)),
      );
    }

    if (phase == .waitingForPhone) {
      return MirrorMessage(
        icon: LucideIcons.smartphone,
        tone: .accent,
        title: l10n.waitingTitle(deviceName),
        body: l10n.waitingBody(deviceName),
        actionLabel: l10n.cancel,
        onAction: () => unawaited(viewModel.stop()),
      );
    }

    if (phase == .streaming && picture != null) {
      return _Picture(picture: picture);
    }

    if (phase == .starting || phase == .streaming) {
      return MirrorMessage(
        icon: LucideIcons.screenShare,
        tone: .success,
        title: l10n.startingTitle(deviceName),
        body: l10n.startingBody,
      );
    }

    return MirrorMessage(
      icon: LucideIcons.screenShare,
      title: l10n.requestingTitle(deviceName),
      body: l10n.requestingBody,
    );
  }

  ViewSession? _sessionOf(ViewerViewModel viewModel) {
    final current = viewModel.current;
    if (current == null || current.deviceId != deviceId) {
      return null;
    }

    return current;
  }

  IconData _iconOf(ViewEnd end) => switch (end) {
    .stoppedHere ||
    .stoppedOnPhone ||
    .systemEnded => LucideIcons.screenShareOff,
    .notConnected || .lostConnection || .noAnswer => LucideIcons.wifiOff,
    .denied || .timedOut || .busy || .turnedOff => LucideIcons.smartphone,
    _ => LucideIcons.triangleAlert,
  };

  FeatureTone _toneOf(ViewEnd end) => switch (end) {
    .stoppedHere || .stoppedOnPhone || .systemEnded => .muted,
    .denied || .timedOut || .busy || .turnedOff => .warning,
    _ => .danger,
  };
}

class _Picture extends StatelessWidget {
  const _Picture({required this.picture});

  final MirrorPicture picture;

  @override
  Widget build(BuildContext context) {
    final actualSize = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.actualSize,
    );
    final screenOff = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.current?.screenOff ?? false,
    );
    final deviceName = context.select<ViewerViewModel, String>(
      (viewModel) => viewModel.current?.deviceName ?? '',
    );
    final l10n = context.mirroringL10n;

    return Stack(
      fit: .expand,
      children: [
        MirrorSurface(picture: picture, actualSize: actualSize),
        if (screenOff)
          Align(
            alignment: .topCenter,
            child: Padding(
              padding: EdgeInsets.all(Spacing.d12),
              child: SurfaceCard(
                child: Text(
                  '${l10n.screenOffTitle(deviceName)}\n${l10n.screenOffBody}',
                  textAlign: .center,
                  style: context.fluffyTheme.typography.caption1.copyWith(
                    color: context.palette.text,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
