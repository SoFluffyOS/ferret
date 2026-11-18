import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/ui/widgets/widgets.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The touchpad page's body: asking, waiting for the owner, the touchpad
/// and keyboard, or why it stopped with Try again.
class TouchpadFrame extends StatelessWidget {
  const TouchpadFrame({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.hostKind,
  });

  final String deviceId;
  final String deviceName;
  final HostKind hostKind;

  @override
  Widget build(BuildContext context) {
    final current = context.select<TouchpadViewModel, OutgoingControl?>(
      (viewModel) => viewModel.current,
    );
    final l10n = context.remoteInputL10n;
    final viewModel = context.read<TouchpadViewModel>();
    if (current == null || current.deviceId != deviceId) {
      return _Asking(text: l10n.requesting(deviceName));
    }

    return switch (current.phase) {
      .requesting => _Asking(text: l10n.requesting(deviceName)),
      .waitingForConsent => NoticeBlock(
        title: l10n.waitingTitle(deviceName),
        body: l10n.waitingBody(deviceName),
        isProblem: false,
        actionLabel: l10n.cancel,
        onAction: () => unawaited(Navigator.of(context).maybePop()),
      ),
      .active => _Touchpad(hostKind: hostKind),
      _ => NoticeBlock(
        title: l10n.outcome(current) ?? l10n.unreachable(deviceName),
        actionLabel: l10n.tryAgain,
        onAction: () => unawaited(viewModel.start(deviceId)),
      ),
    };
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
        Icon(
          LucideIcons.loaderCircle,
          size: Spacing.d16,
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

class _Touchpad extends StatelessWidget {
  const _Touchpad({required this.hostKind});

  /// The share of the screen's height the touchpad takes.
  static const _padShare = 0.4;

  final HostKind hostKind;

  @override
  Widget build(BuildContext context) {
    final armed = context.select<TouchpadViewModel, Set<KeyModifier>>(
      (viewModel) => viewModel.armed,
    );
    final viewModel = context.read<TouchpadViewModel>();
    final l10n = context.remoteInputL10n;
    final height = MediaQuery.sizeOf(context).height * _padShare;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        TouchpadSurface(
          sink: viewModel,
          hint: l10n.touchpadHint,
          height: height,
        ),
        Spacing.v8,
        Row(
          children: [
            Expanded(
              child: HoldButton(
                label: l10n.leftButton,
                onPress: () => viewModel.press(.left),
                onRelease: () => viewModel.release(.left),
              ),
            ),
            Spacing.h8,
            Expanded(
              child: HoldButton(
                label: l10n.rightButton,
                onPress: () => viewModel.press(.right),
                onRelease: () => viewModel.release(.right),
              ),
            ),
          ],
        ),
        Spacing.v16,
        KeyboardField(
          hint: l10n.keyboardHint,
          onChanged: viewModel.typed,
          onEnter: () => viewModel.tapKey(.enter),
        ),
        Spacing.v8,
        _KeyRow(
          keys: [
            KeyChip(
              label: l10n.keyEscape,
              tooltip: l10n.keyEscape,
              onTap: () => viewModel.tapKey(.escape),
            ),
            KeyChip(
              label: l10n.keyTab,
              tooltip: l10n.keyTab,
              onTap: () => viewModel.tapKey(.tab),
            ),
            KeyChip(
              icon: LucideIcons.arrowLeft,
              tooltip: l10n.keyLeft,
              onTap: () => viewModel.tapKey(.arrowLeft),
            ),
            KeyChip(
              icon: LucideIcons.arrowUp,
              tooltip: l10n.keyUp,
              onTap: () => viewModel.tapKey(.arrowUp),
            ),
            KeyChip(
              icon: LucideIcons.arrowDown,
              tooltip: l10n.keyDown,
              onTap: () => viewModel.tapKey(.arrowDown),
            ),
            KeyChip(
              icon: LucideIcons.arrowRight,
              tooltip: l10n.keyRight,
              onTap: () => viewModel.tapKey(.arrowRight),
            ),
            KeyChip(
              icon: LucideIcons.delete,
              tooltip: l10n.keyBackspace,
              onTap: () => viewModel.tapKey(.backspace),
            ),
            KeyChip(
              icon: LucideIcons.cornerDownLeft,
              tooltip: l10n.keyEnter,
              onTap: () => viewModel.tapKey(.enter),
            ),
          ],
        ),
        Spacing.v8,
        _KeyRow(
          keys: [
            for (final modifier in KeyModifier.values)
              KeyChip(
                label: l10n.modifierLabel(modifier, hostKind),
                tooltip: l10n.modifierLabel(modifier, hostKind),
                selected: armed.contains(modifier),
                onTap: () => viewModel.toggleModifier(modifier),
              ),
          ],
        ),
        Spacing.v8,
        _KeyRow(
          keys: [
            KeyChip(
              icon: LucideIcons.skipBack,
              tooltip: l10n.mediaPrevious,
              onTap: () => viewModel.tapKey(.mediaPrevious),
            ),
            KeyChip(
              icon: LucideIcons.play,
              tooltip: l10n.mediaPlayPause,
              onTap: () => viewModel.tapKey(.mediaPlayPause),
            ),
            KeyChip(
              icon: LucideIcons.skipForward,
              tooltip: l10n.mediaNext,
              onTap: () => viewModel.tapKey(.mediaNext),
            ),
            KeyChip(
              icon: LucideIcons.volume1,
              tooltip: l10n.volumeDown,
              onTap: () => viewModel.tapKey(.volumeDown),
            ),
            KeyChip(
              icon: LucideIcons.volumeX,
              tooltip: l10n.volumeMute,
              onTap: () => viewModel.tapKey(.volumeMute),
            ),
            KeyChip(
              icon: LucideIcons.volume2,
              tooltip: l10n.volumeUp,
              onTap: () => viewModel.tapKey(.volumeUp),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.keys});

  final List<Widget> keys;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: Spacing.d6, runSpacing: Spacing.d6, children: keys);
}
