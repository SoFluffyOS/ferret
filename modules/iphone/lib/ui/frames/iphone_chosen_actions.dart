import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:iphone/l10n/l10n.dart';
import 'package:iphone/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Buttons under the chosen iPhone: try again, or pick another one.
class IphoneChosenActions extends StatelessWidget {
  const IphoneChosenActions({super.key, this.showRetry = false});

  final bool showRetry;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<IphoneSettingsViewModel>();
    final l10n = context.iphoneL10n;

    return Padding(
      padding: EdgeInsets.only(top: Spacing.d8),
      child: Wrap(
        spacing: Spacing.d8,
        runSpacing: Spacing.d8,
        children: [
          if (showRetry)
            GhostButton(
              mainAxisSize: .min,
              label: l10n.tryAgain,
              onPressed: () => unawaited(viewModel.retry()),
            ),
          GhostButton(
            mainAxisSize: .min,
            label: l10n.forget,
            onPressed: () => unawaited(viewModel.forget()),
          ),
        ],
      ),
    );
  }
}
