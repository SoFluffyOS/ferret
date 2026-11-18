import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/services/services.dart';
import 'package:messages/ui/frames/frames.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// Messages setup on its own page, opened from the phone's home card.
class PhoneSetupPage extends StatelessWidget {
  const PhoneSetupPage({super.key, required this.service});

  final SourceService service;

  @override
  Widget build(BuildContext context) {
    final l10n = context.messagesL10n;

    return FerretPage(
      title: l10n.title,
      backLabel: l10n.back,
      children: [
        ChangeNotifierProvider(
          create: (_) => PhoneSetupViewModel(service),
          child: const PhoneSetupFrame(),
        ),
      ],
    );
  }
}
