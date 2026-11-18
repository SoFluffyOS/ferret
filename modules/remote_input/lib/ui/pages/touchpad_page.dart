import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/ui/frames/frames.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Opened by "Use as touchpad" on a computer. Control lasts while the page
/// is open: Stop or Back ends it, and the computer lets go at once.
class TouchpadPage extends StatefulWidget {
  const TouchpadPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.hostKind,
  });

  final String deviceId;
  final String deviceName;
  final HostKind hostKind;

  @override
  State<TouchpadPage> createState() => _TouchpadPageState();
}

class _TouchpadPageState extends State<TouchpadPage> {
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

    return FerretPage(
      title: widget.deviceName,
      backLabel: l10n.back,
      actions: [
        if (isActive)
          Button(
            variant: .secondary,
            label: l10n.stop,
            onPressed: () => unawaited(Navigator.of(context).maybePop()),
          ),
      ],
      children: [
        TouchpadFrame(
          deviceId: widget.deviceId,
          deviceName: widget.deviceName,
          hostKind: widget.hostKind,
        ),
      ],
    );
  }
}
