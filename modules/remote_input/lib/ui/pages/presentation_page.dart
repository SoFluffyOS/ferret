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

/// Opened by "Present on MacBook Air": the phone as a presenter clicker.
/// It takes control like the touchpad does, and lets go when it closes.
class PresentationPage extends StatefulWidget {
  const PresentationPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.hostKind,
  });

  final String deviceId;
  final String deviceName;
  final HostKind hostKind;

  @override
  State<PresentationPage> createState() => _PresentationPageState();
}

class _PresentationPageState extends State<PresentationPage> {
  late final TouchpadViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<TouchpadViewModel>();
  }

  @override
  void dispose() {
    unawaited(_viewModel.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = context.select<TouchpadViewModel, bool>(
      (viewModel) =>
          viewModel.current?.deviceId == widget.deviceId &&
          (viewModel.current?.isActive ?? false),
    );
    final l10n = context.remoteInputL10n;
    final palette = context.palette;

    return ColoredBox(
      color: palette.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: Spacing.d12),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              PageHeader(
                title: l10n.presentTitle,
                backLabel: l10n.back,
                onBack: _back,
                actions: [
                  if (isActive)
                    GhostButton(
                      mainAxisSize: .min,
                      label: l10n.stop,
                      onPressed: _back,
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Spacing.d12),
                  child: TouchpadFrame(
                    deviceId: widget.deviceId,
                    deviceName: widget.deviceName,
                    hostKind: widget.hostKind,
                    whileActive: const PresentationFrame(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _back() => unawaited(Navigator.of(context).maybePop());
}
