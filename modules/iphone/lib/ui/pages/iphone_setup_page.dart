import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:iphone/l10n/l10n.dart';
import 'package:iphone/ui/frames/frames.dart';

/// Pairing and picking the iPhone, opened from the home card. Expects an
/// `IphoneSettingsViewModel` above it.
class IphoneSetupPage extends StatelessWidget {
  const IphoneSetupPage({super.key});

  @override
  Widget build(BuildContext context) => FerretPage(
    title: context.iphoneL10n.title,
    children: const [IphoneSettingsFrame()],
  );
}
