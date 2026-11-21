import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/ui/frames/frames.dart';
import 'package:remote_input/ui/widgets/widgets.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The touchpad page's body: asking, waiting for the owner, the touchpad
/// and keyboard, or why it stopped with Try again. It needs a bounded
/// height, since the touchpad fills what is left.
class TouchpadFrame extends StatelessWidget {
  const TouchpadFrame({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.hostKind,
    this.whileActive,
  });

  final String deviceId;
  final String deviceName;
  final HostKind hostKind;

  /// What shows once in control, such as the presentation remote. The
  /// touchpad and keyboard when left out.
  final Widget? whileActive;

  @override
  Widget build(BuildContext context) {
    final current = context.select<TouchpadViewModel, OutgoingControl?>(
      (viewModel) => viewModel.current,
    );
    final l10n = context.remoteInputL10n;
    final viewModel = context.read<TouchpadViewModel>();
    if (current == null || current.deviceId != deviceId) {
      return Align(
        alignment: .topCenter,
        child: _Asking(text: l10n.requesting(deviceName)),
      );
    }

    final message = switch (current.phase) {
      .requesting => _Asking(text: l10n.requesting(deviceName)),
      .waitingForConsent => NoticeBlock(
        title: l10n.waitingTitle(deviceName),
        body: l10n.waitingBody(deviceName),
        isProblem: false,
        actionLabel: l10n.cancel,
        onAction: () => unawaited(Navigator.of(context).maybePop()),
      ),
      .active => whileActive ?? TouchpadControlsFrame(hostKind: hostKind),
      _ => NoticeBlock(
        title: l10n.outcome(current) ?? l10n.unreachable(deviceName),
        actionLabel: l10n.tryAgain,
        onAction: () => unawaited(viewModel.start(deviceId)),
      ),
    };
    if (current.phase == .active && whileActive != null) {
      return message;
    }

    return Align(alignment: .topCenter, child: message);
  }
}

class _Asking extends StatelessWidget {
  const _Asking({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        FluffySpinner(
          size: Spacing.d12,
          strokeWidth: Spacing.d1 + Spacing.d0,
          color: palette.accent,
        ),
        Spacing.h8,
        Expanded(
          child: Text(
            text,
            style: context.fluffyTheme.typography.body2.copyWith(
              color: palette.text,
            ),
          ),
        ),
      ],
    );
  }
}
