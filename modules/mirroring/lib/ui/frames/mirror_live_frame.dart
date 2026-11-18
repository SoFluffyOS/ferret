import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/frames/mirror_text_field_frame.dart';
import 'package:mirroring/ui/frames/mirror_toolbar_frame.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The picture with its chrome. The toolbar floats over the bottom of the
/// picture and hides when the pointer rests; it stays under the picture
/// when the person asked to keep it; and it stands beside the picture,
/// with words, where the space is wider than tall.
class MirrorLiveFrame extends StatefulWidget {
  const MirrorLiveFrame({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.picture,
    required this.onStop,
  });

  final String deviceId;
  final String deviceName;
  final MirrorPicture picture;
  final VoidCallback onStop;

  @override
  State<MirrorLiveFrame> createState() => _MirrorLiveFrameState();
}

class _MirrorLiveFrameState extends State<MirrorLiveFrame> {
  final FocusNode _pictureFocus = FocusNode();
  bool _popupOpen = false;

  @override
  void dispose() {
    _pictureFocus.dispose();
    super.dispose();
  }

  void _setPopupOpen(bool open) {
    if (!open) {
      _pictureFocus.requestFocus();
    }

    setState(() => _popupOpen = open);
  }

  @override
  Widget build(BuildContext context) {
    final pinned = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.toolbarPinned,
    );
    final textFieldOpen = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.textFieldOpen,
    );
    final isSmall = context.screenSize == .small;

    return LayoutBuilder(
      builder: (context, constraints) {
        final beside = !isSmall && constraints.maxWidth > constraints.maxHeight;
        if (beside) {
          return Row(
            children: [
              Expanded(child: _picture(context, textFieldOpen)),
              Padding(
                padding: EdgeInsets.all(Spacing.d12),
                child: Center(
                  child: SingleChildScrollView(child: _toolbar(.vertical)),
                ),
              ),
            ],
          );
        }

        if (pinned) {
          return Column(
            children: [
              Expanded(child: _picture(context, textFieldOpen)),
              Padding(
                padding: EdgeInsets.all(Spacing.d8),
                child: _toolbar(.horizontal, canPin: true),
              ),
            ],
          );
        }

        return IdleFade(
          keepShown: _popupOpen || textFieldOpen,
          overlay: Padding(
            padding: EdgeInsets.all(Spacing.d12),
            child: _toolbar(.horizontal, canPin: true),
          ),
          child: _picture(
            context,
            textFieldOpen,
            fieldInset: Spacing.d64,
          ),
        );
      },
    );
  }

  Widget _toolbar(Axis axis, {bool canPin = false}) => MirrorToolbarFrame(
    deviceId: widget.deviceId,
    deviceName: widget.deviceName,
    axis: axis,
    canPin: canPin,
    onStop: widget.onStop,
    onPopup: _setPopupOpen,
  );

  /// The picture, what is said over it, and the field for composed text.
  /// [fieldInset] lifts the field over a toolbar that floats there.
  Widget _picture(
    BuildContext context,
    bool textFieldOpen, {
    double fieldInset = 0,
  }) {
    final abilities = context.select<ViewerViewModel, Set<ControlAbility>>(
      (viewModel) => viewModel.abilities,
    );
    final screenOff = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.current?.screenOff ?? false,
    );
    final reconnecting = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.current?.phase == .reconnecting,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    final palette = context.palette;
    final dimmed = screenOff || reconnecting;

    return Stack(
      fit: .expand,
      children: [
        MirrorSurface(
          picture: widget.picture,
          builder: (context, picture) => Stack(
            fit: .expand,
            children: [
              MirrorInput(
                focusNode: _pictureFocus,
                abilities: switch (reconnecting) {
                  true => const {},
                  false => abilities,
                },
                onAction: viewModel.perform,
                onViewOnlyTap: viewModel.noteViewOnlyTap,
                child: picture,
              ),
              if (dimmed)
                IgnorePointer(
                  child: ColoredBox(
                    color: palette.background.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
        if (reconnecting)
          _Standing(title: l10n.reconnectingTitle(widget.deviceName)),
        if (screenOff && !reconnecting)
          _Standing(
            title: l10n.screenOffTitle(widget.deviceName),
            body: l10n.screenOffBody(widget.deviceName),
            actionLabel: switch (abilities.contains(ControlAbility.buttons)) {
              true => l10n.wake,
              false => null,
            },
            onAction: () => viewModel.press(.power),
          ),
        Align(
          alignment: .topCenter,
          child: Padding(
            padding: EdgeInsets.all(Spacing.d12),
            child: _NoticeFrame(
              deviceId: widget.deviceId,
              deviceName: widget.deviceName,
            ),
          ),
        ),
        if (textFieldOpen)
          Align(
            alignment: .bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Spacing.d12,
                Spacing.d12,
                Spacing.d12,
                Spacing.d12 + fieldInset,
              ),
              child: MirrorTextFieldFrame(
                onClosed: _pictureFocus.requestFocus,
              ),
            ),
          ),
      ],
    );
  }
}

/// What is said over a picture that stands still, with a way out when
/// there is one.
class _Standing extends StatelessWidget {
  const _Standing({
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(Spacing.d24),
        child: Column(
          mainAxisSize: .min,
          children: [
            Text(
              title,
              textAlign: .center,
              style: typography.base1.copyWith(color: palette.text),
            ),
            if (body case final body?) ...[
              Spacing.v4,
              Text(
                body,
                textAlign: .center,
                style: typography.caption1.copyWith(color: palette.mutedText),
              ),
            ],
            if ((actionLabel, onAction) case (final label?, final action?)) ...[
              Spacing.v12,
              Button(
                variant: .ghost,
                mainAxisSize: .min,
                label: label,
                onPressed: action,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The one line the stage has to say over the picture right now.
class _NoticeFrame extends StatelessWidget {
  const _NoticeFrame({required this.deviceId, required this.deviceName});

  final String deviceId;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final notice = context.select<ViewerViewModel, StageNotice?>(
      (viewModel) => viewModel.notice,
    );
    final isFast = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.preset == .fast,
    );
    final cableOffers = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.cableOffers(deviceId),
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    if (notice == null) {
      return const SizedBox.shrink();
    }

    final (text, actionLabel, onAction) = switch (notice) {
      .viaCable => (l10n.noticeViaCable, null, null),
      .cableNoAsk => (l10n.noticeCableNoAsk(deviceName), null, null),
      .basicPicture => (l10n.basicPicture, null, null),
      .slow when isFast => (l10n.noticeSlowHelp(deviceName), null, null),
      .slow => (
        l10n.noticeSlow(deviceName),
        l10n.useFast,
        () => unawaited(viewModel.setPreset(.fast)),
      ),
      .viewOnly when cableOffers => (
        l10n.viewOnlyToast,
        l10n.controlWithCable,
        () => unawaited(viewModel.controlWithCable(deviceId)),
      ),
      .viewOnly => (l10n.viewOnlyBody(deviceName), null, null),
    };

    return StageNoticeBar(
      text: text,
      actionLabel: actionLabel,
      onAction: onAction,
      dismissLabel: l10n.dismiss,
      onDismiss: viewModel.dismissNotice,
    );
  }
}
