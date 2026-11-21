import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// "Let Pixel control this computer?" (or lock it) with Always, Allow once and Don't
/// allow. Answers by calling [onAnswer]; closing it answers nothing, and
/// the home card still asks.
class ConsentDialog extends StatelessWidget {
  const ConsentDialog({
    super.key,
    required this.request,
    required this.onAnswer,
  });

  final ConsentRequest request;
  final ValueChanged<ConsentChoice> onAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.remoteInputL10n;

    return FerretDialogCard(
      title: Text(l10n.consentTitleOf(request, HostKind.here)),
      content: Text(l10n.consentBodyOf(request)),
      actions: [
        Button(
          mainAxisSize: .max,
          variant: .primary,
          label: l10n.allowAlways,
          tooltip: l10n.allowAlways,
          onPressed: () => onAnswer(.always),
        ),
        Spacing.v8,
        GhostButton(
          mainAxisSize: .max,
          label: l10n.allowOnce,
          tooltip: l10n.allowOnce,
          onPressed: () => onAnswer(.allowOnce),
        ),
        Spacing.v8,
        GhostButton(
          mainAxisSize: .max,
          label: l10n.dontAllow,
          tooltip: l10n.dontAllow,
          onPressed: () => onAnswer(.deny),
        ),
      ],
    );
  }
}
