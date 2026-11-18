import 'dart:async';
import 'dart:math';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/ui/frames/frames.dart';
import 'package:remote_input/ui/widgets/widgets.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Opened by "Use as touchpad" on a computer. Control lasts while the page
/// is open: Stop or Back ends it, and the computer lets go at once. The page
/// never scrolls, and shrinks above the on-screen keyboard.
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
    final palette = context.palette;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: !isActive,
      onPopInvokedWithResult: (didPop, _) => _leave(didPop),
      child: ColoredBox(
        color: palette.background,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: max(keyboardInset, safeBottom) + Spacing.d12,
            ),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                PageHeader(
                  title: widget.deviceName,
                  backLabel: l10n.back,
                  onBack: _back,
                  actions: [
                    if (isActive)
                      Button(
                        mainAxisSize: .min,
                        variant: .ghost,
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _back() => unawaited(Navigator.of(context).maybePop());

  /// While in control the route refuses to pop, which turns off the iOS
  /// edge swipe that would grab drags starting near the pad's edge; Back
  /// and Stop still leave through here.
  void _leave(bool didPop) {
    if (didPop) {
      return;
    }

    Navigator.of(context).pop();
  }
}
