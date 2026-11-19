import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/l10n/l10n.dart';
import 'package:photos/ui/frames/frames.dart';
import 'package:photos/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// What a tap on "Pixel wants to see your photos" opens on the phone: the
/// switch for that computer and what Ferret may read.
class PhonePhotosPage extends StatelessWidget {
  const PhonePhotosPage({
    super.key,
    required this.viewModel,
    required this.deviceId,
    required this.deviceName,
  });

  final PhonePhotosViewModel viewModel;
  final String deviceId;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.photosL10n;

    return FerretPage(
      title: l10n.title,
      backLabel: l10n.back,
      children: [
        ChangeNotifierProvider.value(
          value: viewModel,
          child: PhonePhotosFrame(deviceId: deviceId, deviceName: deviceName),
        ),
      ],
    );
  }
}
