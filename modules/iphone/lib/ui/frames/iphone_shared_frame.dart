import 'package:flutter/widgets.dart';
import 'package:iphone/l10n/l10n.dart';
import 'package:iphone/ui/widgets/widgets.dart';
import 'package:iphone/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What a connected iPhone holds back, with the way to turn it on.
class IphoneSharedFrame extends StatelessWidget {
  const IphoneSharedFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationsNotShared = context
        .select<IphoneSettingsViewModel, bool>(
          (viewModel) => viewModel.notificationsNotShared,
        );
    final mediaNotShared = context.select<IphoneSettingsViewModel, bool>(
      (viewModel) => viewModel.mediaNotShared,
    );
    final deviceName = context.select<IphoneSettingsViewModel, String>(
      (viewModel) => viewModel.link.deviceName,
    );
    final l10n = context.iphoneL10n;
    final device = switch (deviceName.isEmpty) {
      true => l10n.yourIphone,
      false => deviceName,
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (notificationsNotShared) ...[
          Spacing.v8,
          NoticeBlock(title: l10n.notificationsNotShared(device)),
        ],
        if (mediaNotShared) ...[
          Spacing.v8,
          NoticeBlock(title: l10n.mediaNotShared(device)),
        ],
      ],
    );
  }
}
