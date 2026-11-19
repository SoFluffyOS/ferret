import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:messages/ui/frames/phone_setup_explainer.dart';
import 'package:messages/ui/frames/phone_setup_needs_access.dart';
import 'package:messages/ui/frames/phone_setup_ready.dart';
import 'package:messages/ui/widgets/widgets.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Messages on the phone: the explainer, SMS access with a re-check when
/// the person comes back, the settings page when Android won't ask again,
/// and the RCS limit.
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
      onResume: () =>
          unawaited(context.read<PhoneSetupViewModel>().onResumed()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = context.select<PhoneSetupViewModel, SetupStage>(
      (viewModel) => viewModel.stage,
    );

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        switch (stage) {
          .unsupported => const PhoneSetupUnsupported(),
          .off => const PhoneSetupExplainer(),
          .needsAccess => const PhoneSetupNeedsAccess(),
          .ready => const PhoneSetupReady(),
        },
        if (stage != .unsupported) ...[Spacing.v12, const RcsNote()],
      ],
    );
  }
}
