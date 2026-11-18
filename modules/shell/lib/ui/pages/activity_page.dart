import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/frames.dart';

/// Everything that happened lately, not only the last three.
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;

    return FerretPage(
      title: l10n.activityTitle,
      backLabel: l10n.back,
      children: const [ActivityFrame()],
    );
  }
}
