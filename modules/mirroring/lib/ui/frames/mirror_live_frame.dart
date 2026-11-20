import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/frames/mirror_text_field_frame.dart';
import 'package:mirroring/ui/frames/mirror_toolbar_frame.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The picture with its chrome, none of it on the picture. In the
/// picture's own window the toolbar sits in the window's top bar and goes
/// quiet when the pointer rests; elsewhere it stands under the picture or
/// beside it, whichever leaves the picture bigger. A notice comes above
/// the picture and the keyboard field under it: the picture gets smaller
/// for them rather than being covered.
class MirrorLiveFrame extends StatefulWidget {
  const MirrorLiveFrame({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.picture,
    required this.onStop,
    this.inWindow = false,
    this.onDragWindow,
  });

  final String deviceId;
  final String deviceName;
  final MirrorPicture picture;
  final VoidCallback onStop;

  /// The stage is the picture's own window, which keeps a bar above the
  /// picture for the toolbar.
  final bool inWindow;

  /// Moves that window, from a press on its bar.
  final VoidCallback? onDragWindow;

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
    final textFieldOpen = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.textFieldOpen,
    );
    if (widget.inWindow) {
      return _window(context, textFieldOpen);
    }

    final isSmall = context.screenSize == .small;
    final picture = Size(
      widget.picture.width.toDouble(),
      widget.picture.height.toDouble(),
    );
    final aspect = picture.width / picture.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final place = StageLayout.placeFor(
          space: constraints.biggest,
          picture: picture,
          belowExtent: Spacing.d56,
          besideExtent: Spacing.d200,
          isSmall: isSmall,
        );
        final stage = _stage(context, textFieldOpen);
        if (place == .beside) {
          return Padding(
            padding: EdgeInsets.only(bottom: Spacing.d12),
            child: Row(
              mainAxisAlignment: .center,
              children: [
                Flexible(
                  child: SizedBox(
                    width: (constraints.maxHeight - Spacing.d12) * aspect,
                    child: stage,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Spacing.d16),
                  child: Center(
                    child: SingleChildScrollView(child: _toolbar(.beside)),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          mainAxisAlignment: .center,
          children: [
            Flexible(
              child: SizedBox(
                height: constraints.maxWidth / aspect,
                child: stage,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(Spacing.d8),
              child: _toolbar(.below),
            ),
          ],
        );
      },
    );
  }

  /// The window's bar on top with the toolbar in it, the picture filling
  /// the rest. The toolbar fades when the pointer rests, unless it is
  /// kept; its room stays either way.
  Widget _window(BuildContext context, bool textFieldOpen) {
    final pinned = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.toolbarPinned,
    );

    return IdleFade(
      keepShown: pinned || _popupOpen || textFieldOpen,
      builder: (context, shown, onChrome) => Column(
        crossAxisAlignment: .stretch,
        children: [
          MirrorWindowBar(
            title: widget.deviceName,
            onDragStart: widget.onDragWindow,
            trailing: MouseRegion(
              onEnter: (_) => onChrome(true),
              onExit: (_) => onChrome(false),
              child: IgnorePointer(
                ignoring: !shown,
                child: AnimatedOpacity(
                  opacity: switch (shown) {
                    true => 1,
                    false => 0,
                  },
                  duration: FluffyDurations.normal,
                  child: _toolbar(.bar),
                ),
              ),
            ),
          ),
          Expanded(child: _stage(context, textFieldOpen)),
        ],
      ),
    );
  }

  Widget _toolbar(ToolbarPlace place) => MirrorToolbarFrame(
    deviceId: widget.deviceId,
    deviceName: widget.deviceName,
    place: place,
    onStop: widget.onStop,
    onPopup: _setPopupOpen,
  );

  /// The notice above the picture, the picture, and the field for
  /// composed text under it.
  Widget _stage(BuildContext context, bool textFieldOpen) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _NoticeFrame(deviceId: widget.deviceId, deviceName: widget.deviceName),
      Expanded(child: _picture(context)),
      if (textFieldOpen)
        Padding(
          padding: EdgeInsets.all(Spacing.d8),
          child: Center(
            child: MirrorTextFieldFrame(onClosed: _pictureFocus.requestFocus),
          ),
        ),
    ],
  );

  /// The picture and what is said over it while it stands still.
  Widget _picture(BuildContext context) {
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
              GhostButton(
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

/// The one line the stage has to say right now, above the picture.
class _NoticeFrame extends StatelessWidget {
  const _NoticeFrame({required this.deviceId, required this.deviceName});

  final String deviceId;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final notice = context.select<ViewerViewModel, StageNotice?>(
      (viewModel) => viewModel.notice,
    );
    final canGoFaster = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.presetRestarts && viewModel.preset != .fast,
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
      .basicPicture => (l10n.basicPicture(ThisComputer.here), null, null),
      .slow when canGoFaster => (
        l10n.noticeSlow(deviceName),
        l10n.useFast,
        () => unawaited(viewModel.setPreset(.fast)),
      ),
      .slow => (l10n.noticeSlowHelp(deviceName), null, null),
      .viewOnly when cableOffers => (
        l10n.viewOnlyToast,
        l10n.controlWithCable,
        () => unawaited(viewModel.controlWithCable(deviceId)),
      ),
      .viewOnly => (l10n.viewOnlyBody(deviceName), null, null),
      .screenshotSaved => (
        l10n.screenshotSaved(viewModel.screenshotFolder),
        switch (defaultTargetPlatform) {
          .macOS => l10n.showInFinder,
          _ => l10n.showInFolder,
        },
        () => unawaited(viewModel.revealScreenshot()),
      ),
      .screenshotFailed => (l10n.screenshotFailed, null, null),
      .controlAsking => (
        l10n.noticeControlAsking(deviceName, ThisComputer.here),
        null,
        null,
      ),
      .controlAllowed => (l10n.noticeControlAllowed(deviceName), null, null),
      .controlDenied => (l10n.noticeControlDenied(deviceName), null, null),
      .controlTimedOut => (l10n.noticeControlTimedOut(deviceName), null, null),
      .controlStopped => (l10n.noticeControlStopped(deviceName), null, null),
    };

    return Padding(
      padding: EdgeInsets.all(Spacing.d8),
      child: Center(
        child: StageNoticeBar(
          text: text,
          actionLabel: actionLabel,
          onAction: onAction,
          dismissLabel: l10n.dismiss,
          onDismiss: viewModel.dismissNotice,
        ),
      ),
    );
  }
}
