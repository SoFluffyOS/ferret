import 'dart:async';

import 'package:calls/ui/frames/phone_setup_explainer.dart';
import 'package:calls/ui/frames/phone_setup_needs_permission.dart';
import 'package:calls/ui/frames/phone_setup_ready.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Calls settings on the phone: the explainer, the permissions with a
/// re-check on return, and what computers can do once it is on.
class PhoneSetupFrame extends StatefulWidget {
  const PhoneSetupFrame({super.key});

  @override
  State<PhoneSetupFrame> createState() => _PhoneSetupFrameState();
}

class _PhoneSetupFrameState extends State<PhoneSetupFrame> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(context.read<PhoneSetupViewModel>().refresh()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = context.select<PhoneSetupViewModel, CallsSetupStage>(
      (viewModel) => viewModel.stage,
    );

    return switch (stage) {
      .off => const PhoneSetupExplainer(),
      .needsPermission => const PhoneSetupNeedsPermission(),
      .ready => const PhoneSetupReady(),
    };
  }
}
