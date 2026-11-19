import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_photos/ferret_photos.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/l10n/l10n.dart';
import 'package:photos/ui/widgets/widgets.dart';
import 'package:photos/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// Photos in a phone's Settings, or on the page a computer's request opens:
/// what Ferret may read, and, for [deviceId], the switch to share with it.
class PhonePhotosFrame extends StatelessWidget {
  const PhonePhotosFrame({super.key, this.deviceId, this.deviceName = ''});

  final String? deviceId;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.photosL10n;
    final access = context.select<PhonePhotosViewModel, PhotoLibraryAccess>(
      (viewModel) => viewModel.access,
    );
    final sharedWith = context.select<PhonePhotosViewModel, List<String>>(
      (viewModel) => viewModel.sharedWith,
    );
    final deviceId = this.deviceId;
    final shares = context.select<PhonePhotosViewModel, bool>(
      (viewModel) => switch (deviceId) {
        final id? => viewModel.sharesWith(id),
        null => false,
      },
    );
    final viewModel = context.read<PhonePhotosViewModel>();

    return PhoneAccessCard(
      access: access,
      sharedWith: sharedWith,
      onAllow: () => unawaited(viewModel.allow()),
      onOpenSettings: () => unawaited(viewModel.openSettings()),
      switches: [
        if (deviceId != null)
          SettingSwitchRow(
            title: l10n.permissionLabel(deviceName),
            body: l10n.permissionDetail(deviceName),
            value: shares,
            onChanged: (value) =>
                unawaited(viewModel.setSharesWith(deviceId, shared: value)),
          ),
      ],
    );
  }
}
