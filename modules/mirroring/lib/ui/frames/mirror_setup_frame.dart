import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The cable steps, as a checklist that ticks itself: the helper tool
/// when it is missing, plugging in and USB debugging, then Allow on the
/// phone. The picture starts when the last one ticks. No button to try
/// again.
class MirrorSetupFrame extends StatefulWidget {
  const MirrorSetupFrame({
    super.key,
    required this.deviceName,
    required this.onCancel,
  });

  final String deviceName;
  final VoidCallback onCancel;

  @override
  State<MirrorSetupFrame> createState() => _MirrorSetupFrameState();
}

class _MirrorSetupFrameState extends State<MirrorSetupFrame> {
  bool _showsBrands = false;

  @override
  Widget build(BuildContext context) {
    final setup = context.select<ViewerViewModel, CableSetup?>(
      (viewModel) => viewModel.cableSetup,
    );
    final unsupported = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.cableUnsupported,
    );
    final waitedLong = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.cableWaitedLong,
    );
    final l10n = context.mirroringL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final caption = typography.caption1.copyWith(color: palette.mutedText);
    if (unsupported) {
      return MirrorMessage(
        icon: LucideIcons.cable,
        title: l10n.setupUnsupported,
        actions: [
          MessageAction(label: l10n.close, onPressed: widget.onCancel),
        ],
      );
    }

    final step = setup?.step;
    final needsTool = step == .installTool;
    final needsOk = step == .grantPermission;
    final found = step == .authorizeComputer || (setup?.isReady ?? false);
    final beforePhone = needsTool || needsOk;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(Spacing.d24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Spacing.d360),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Text(
                l10n.setupTitle(widget.deviceName),
                style: typography.title2.copyWith(color: palette.text),
              ),
              Spacing.v4,
              Text(l10n.setupSubtitle, style: caption),
              Spacing.v12,
              if (needsTool) _toolStep(context, setup?.help ?? .none),
              if (needsOk)
                SetupStepRow(
                  title: l10n.setupPermissionTitle(ThisComputer.here),
                  state: .now,
                  children: [
                    Text(
                      l10n.setupPermissionBody(ThisComputer.here),
                      style: caption,
                    ),
                  ],
                ),
              SetupStepRow(
                title: l10n.stepPlug(ThisComputer.here),
                state: _stateOf(done: found, waits: beforePhone),
              ),
              SetupStepRow(
                title: l10n.stepDebugging,
                state: _stateOf(done: found, waits: beforePhone),
                children: [
                  Text(l10n.stepDebuggingOn, style: caption),
                  for (final (index, line) in [
                    l10n.stepDebugging1,
                    l10n.stepDebugging2,
                    l10n.stepDebugging3,
                  ].indexed)
                    Text(
                      l10n.setupStepNumbered(index + 1, line),
                      style: caption,
                    ),
                  Spacing.v4,
                  Tappable(
                    onTap: () => setState(() => _showsBrands = !_showsBrands),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        Text(
                          l10n.brandsToggle,
                          style: caption.copyWith(color: palette.link),
                        ),
                        DirectionalIcon(
                          switch (_showsBrands) {
                            true => LucideIcons.chevronDown,
                            false => LucideIcons.chevronRight,
                          },
                          size: Spacing.d14,
                          color: palette.accent,
                        ),
                      ],
                    ),
                  ),
                  if (_showsBrands) ...[
                    Spacing.v4,
                    Text(l10n.brandsBody, style: caption),
                  ],
                ],
              ),
              SetupStepRow(
                title: switch (setup?.detail) {
                  final phone? when step == .authorizeComputer =>
                    l10n.stepAllowNamed(phone),
                  _ => l10n.stepAllow,
                },
                state: switch (step) {
                  .authorizeComputer => .now,
                  null when found => .done,
                  _ => .later,
                },
              ),
              Spacing.v12,
              Text(l10n.setupWaiting, style: caption),
              if (waitedLong && step == .enableDebugging) ...[
                Spacing.v4,
                Text(
                  l10n.setupCables,
                  style: caption.copyWith(color: palette.warning),
                ),
              ],
              Spacing.v12,
              Text(l10n.setupPrivacy(ThisComputer.here), style: caption),
              Spacing.v16,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Button(
                  variant: .ghost,
                  mainAxisSize: .min,
                  label: l10n.cancel,
                  onPressed: widget.onCancel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  StepState _stateOf({required bool done, required bool waits}) {
    if (done) {
      return .done;
    }

    if (waits) {
      return .later;
    }

    return .now;
  }

  /// The helper tool: fetched only on the owner's click, with words that
  /// say what is downloaded and from where.
  Widget _toolStep(BuildContext context, SetupHelp help) {
    final download = context.select<ViewerViewModel, ToolDownload>(
      (viewModel) => viewModel.download,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    final palette = context.palette;
    final caption = context.fluffyTheme.typography.caption1;

    return SetupStepRow(
      title: switch (help) {
        .startTool => l10n.setupStartToolTitle,
        _ => l10n.setupDownloadToolTitle,
      },
      state: .now,
      children: [
        Text(
          switch (help) {
            .download => l10n.setupDownloadToolBody,
            .startTool => l10n.setupStartToolBody(ThisComputer.here),
            .none => l10n.setupInstallToolBody(ThisComputer.here),
          },
          style: caption.copyWith(color: palette.mutedText),
        ),
        if (download == .failed) ...[
          Spacing.v4,
          Text(
            l10n.setupDownloadFailed(ThisComputer.here),
            style: caption.copyWith(color: palette.danger),
          ),
        ],
        if (help == .download) ...[
          Spacing.v8,
          Button(
            variant: .primary,
            mainAxisSize: .min,
            enable: download != .downloading,
            label: switch (download) {
              .downloading => l10n.downloading,
              .failed => l10n.tryAgain,
              .idle => l10n.download,
            },
            onPressed: () => unawaited(viewModel.downloadTool()),
          ),
        ],
      ],
    );
  }
}
