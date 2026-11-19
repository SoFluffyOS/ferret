import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:notifications/ui/frames/phone_setup_explainer.dart';
import 'package:notifications/ui/frames/phone_setup_needs_access.dart';
import 'package:notifications/ui/frames/phone_setup_ready.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// Mirroring settings on the phone: the explainer, notification access with
/// a re-check on return, the restricted settings guide, and the options.
class PhoneSetupFrame extends StatefulWidget {
  const PhoneSetupFrame({super.key, required this.onChooseApps});

  final VoidCallback onChooseApps;

  @override
  State<PhoneSetupFrame> createState() => _PhoneSetupFrameState();
}

class _PhoneSetupFrameState extends State<PhoneSetupFrame> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(context.read<MirrorSetupViewModel>().onResumed()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = context.select<MirrorSetupViewModel, SetupStage>(
      (viewModel) => viewModel.stage,
    );

    return switch (stage) {
      .off => const PhoneSetupExplainer(),
      .needsAccess => const PhoneSetupNeedsAccess(),
      .ready => PhoneSetupReady(onChooseApps: widget.onChooseApps),
    };
  }
}
