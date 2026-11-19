import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/ui/widgets/status_line.dart';

class PhoneSetupUnsupported extends StatelessWidget {
  const PhoneSetupUnsupported({super.key});

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: StatusLine(text: context.messagesL10n.noTelephony, tone: .info),
  );
}
