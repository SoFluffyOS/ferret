import 'package:flutter/widgets.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// "Let Pixel control this computer?" with Always, Allow once and Don't
/// allow. Answers by calling [onAnswer]; closing it answers nothing, and
/// the home card still asks.
class ConsentDialog extends StatelessWidget {
  const ConsentDialog({
    super.key,
    required this.deviceName,
    required this.onAnswer,
  });

  final String deviceName;
  final ValueChanged<ConsentChoice> onAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.remoteInputL10n;

    return DialogCard(
      title: Text(l10n.consentTitle(deviceName)),
      content: Text(l10n.consentBody(deviceName)),
      actions: [
        Button(
          mainAxisSize: .min,
          variant: .primary,
          label: l10n.allowAlways,
          tooltip: l10n.allowAlways,
          onPressed: () => onAnswer(.always),
        ),
        Spacing.v8,
        Button(
          mainAxisSize: .min,
          variant: .ghost,
          label: l10n.allowOnce,
          tooltip: l10n.allowOnce,
          onPressed: () => onAnswer(.allowOnce),
        ),
        Spacing.v8,
        Button(
          mainAxisSize: .min,
          variant: .ghost,
          label: l10n.dontAllow,
          tooltip: l10n.dontAllow,
          onPressed: () => onAnswer(.deny),
        ),
      ],
    );
  }
}
