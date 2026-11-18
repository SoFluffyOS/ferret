import 'package:calls/feature/calls_feature.dart';
import 'package:calls/l10n/l10n.dart';
import 'package:calls/ui/frames/frames.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Calls setup on its own page, opened from the phone's home card.
class PhoneSetupPage extends StatelessWidget {
  const PhoneSetupPage({super.key, required this.feature});

  final CallsFeature feature;

  @override
  Widget build(BuildContext context) {
    final l10n = context.callsL10n;

    return FerretPage(
      title: l10n.title,
      backLabel: l10n.back,
      children: [
        ChangeNotifierProvider(
          create: (_) => PhoneSetupViewModel(feature),
          child: const PhoneSetupFrame(),
        ),
      ],
    );
  }
}
