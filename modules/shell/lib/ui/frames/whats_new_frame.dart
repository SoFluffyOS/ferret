import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// One quiet line after an update, "Updated to Ferret 0.2.0 · What's new",
/// linking the release notes. It shows for the first run after the update
/// only, and goes once opened.
class WhatsNewFrame extends StatelessWidget {
  const WhatsNewFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final version = context.select<EngineHost, String?>(
      (host) => host.updatedTo,
    );
    if (version == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.shellL10n;

    return FooterHint(
      text: l10n.whatsNewLine(version),
      actionLabel: l10n.whatsNewAction,
      onAction: () {
        unawaited(launchUrl(WhatsNew.notesFor(version)));
        context.read<EngineHost>().dismissWhatsNew();
      },
    );
  }
}
