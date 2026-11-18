import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/services.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// How an attempt ended, and the one button that fits that ending: Show
/// again after a stop, Ask again after a no (once the phone would listen),
/// Try again only after a failure. A paired phone that isn't connected
/// gets its two ways in instead.
class MirrorEndedFrame extends StatelessWidget {
  const MirrorEndedFrame({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.end,
    this.onClose,
    this.clock,
  });

  final String deviceId;
  final String deviceName;
  final ViewEnd end;

  /// Closes what hosts the stage. Null where there is nothing to close.
  final VoidCallback? onClose;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final endedAt = context.select<ViewerViewModel, DateTime?>(
      (viewModel) => viewModel.sessionFor(deviceId)?.endedAt,
    );
    final isPaired = context.select<ViewerViewModel, bool>(
      (viewModel) =>
          viewModel.sessionFor(deviceId)?.target.ferretDeviceId != null,
    );
    final hasCable = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.hasCable,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    void again() => unawaited(viewModel.again(deviceId));
    final close = [
      if (onClose case final onClose?)
        MessageAction(label: l10n.close, onPressed: onClose),
    ];

    if (end == .notConnected && isPaired) {
      return MirrorMessage(
        icon: LucideIcons.wifiOff,
        title: l10n.endNotConnectedTitle(deviceName),
        body: l10n.endNotConnectedBody(deviceName),
        actions: [
          ...close,
          if (hasCable)
            MessageAction(
              label: l10n.how,
              primary: true,
              onPressed: () => viewModel.openCableGuide(deviceId),
            ),
        ],
        children: [
          _caption(context, l10n.notConnectedWaits(deviceName)),
          if (hasCable) ...[
            Spacing.v16,
            _caption(context, l10n.orDivider),
            Spacing.v16,
            Text(
              l10n.plugInTitle(deviceName),
              textAlign: .center,
              style: context.fluffyTheme.typography.base1.copyWith(
                color: context.palette.text,
              ),
            ),
            _caption(context, l10n.plugInBody),
          ],
        ],
      );
    }

    if (end == .denied && endedAt != null) {
      return Countdown(
        until: endedAt.add(MirrorViewer.denyCooldown),
        clock: clock,
        builder: (context, left) => MirrorMessage(
          icon: LucideIcons.smartphone,
          tone: .warning,
          title: l10n.endTitle(end, deviceName),
          body: l10n.endBody(end, deviceName),
          actions: [
            ...close,
            MessageAction(
              label: l10n.askAgain,
              primary: true,
              onPressed: switch (left > Duration.zero) {
                true => null,
                false => again,
              },
            ),
          ],
          children: [
            if (left > Duration.zero)
              _caption(context, l10n.askAgainIn(Countdown.clockText(left))),
          ],
        ),
      );
    }

    return MirrorMessage(
      icon: _iconOf(end),
      tone: _toneOf(end),
      title: l10n.endTitle(end, deviceName),
      body: l10n.endBody(end, deviceName),
      actions: [
        ...close,
        MessageAction(
          label: switch (end) {
            .stoppedHere || .stoppedOnPhone || .systemEnded => l10n.showAgain,
            .denied ||
            .timedOut ||
            .busy ||
            .turnedOff ||
            .cannotAsk => l10n.askAgain,
            _ => l10n.tryAgain,
          },
          primary: true,
          onPressed: again,
        ),
      ],
    );
  }

  Widget _caption(BuildContext context, String text) => Padding(
    padding: EdgeInsets.only(top: Spacing.d4),
    child: Text(
      text,
      textAlign: .center,
      style: context.fluffyTheme.typography.caption1.copyWith(
        color: context.palette.mutedText,
      ),
    ),
  );

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
