import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:updates/l10n/l10n.dart';
import 'package:updates/ui/widgets/widgets.dart';
import 'package:updates/view_models/view_models.dart';

/// The release notes of the newer Ferret, with Install where Ferret
/// installs itself. Wider in a window, so the notes read as a page.
abstract final class WhatsNewDialog {
  static Future<void> show(
    BuildContext context, {
    required UpdatesViewModel viewModel,
  }) async {
    final release = viewModel.release;
    if (release == null) {
      return;
    }

    final fluffyTheme = context.fluffyTheme;
    final l10n = context.updatesL10n;
    final controller = ScrollController();
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: l10n.close,
        barrierColor: FluffyColors.barrier,
        transitionDuration: FluffyDurations.dialogTransition,
        transitionBuilder: (context, animation, _, child) =>
            FluffyDialogTransition(animation: animation, child: child),
        pageBuilder: (context, _, _) => FluffyTheme(
          data: fluffyTheme,
          child: WhatsNewCard(
            version: release.versionText,
            notes: release.notes,
            controller: controller,
            canInstall:
                viewModel.kind.installsItself && viewModel.phase == .available,
            onInstall: () {
              Navigator.of(context).pop();
              unawaited(viewModel.install());
            },
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}

/// The dialog itself, apart from how it opens, so it can be drawn alone.
class WhatsNewCard extends StatelessWidget {
  const WhatsNewCard({
    super.key,
    required this.version,
    required this.notes,
    required this.controller,
    required this.canInstall,
    required this.onInstall,
  });

  final String version;
  final String notes;
  final ScrollController controller;
  final bool canInstall;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final l10n = context.updatesL10n;
    void close() => Navigator.of(context).pop();
    final closeButton = GhostFill(
      child: Button(
        variant: switch (canInstall) {
          true => .ghost,
          false => .primary,
        },
        label: switch (canInstall) {
          true => l10n.later,
          false => l10n.close,
        },
        titleExpand: .shrink,
        mainAxisSize: .max,
        onPressed: close,
      ),
    );

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: Focus(
        autofocus: true,
        child: FerretDialogCard(
          maxWidth: switch (context.screenSize) {
            .small => null,
            _ => Spacing.d440,
          },
          title: Text(l10n.whatsNewTitle(version)),
          content: RawScrollbar(
            controller: controller,
            child: SingleChildScrollView(
              controller: controller,
              child: ReleaseNotesText(notes, empty: l10n.noNotes),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(child: closeButton),
                if (canInstall) ...[
                  Spacing.h8,
                  Expanded(
                    child: Button(
                      variant: .primary,
                      label: l10n.install,
                      tooltip: l10n.installTooltip(version),
                      semanticLabel: l10n.installTooltip(version),
                      titleExpand: .shrink,
                      mainAxisSize: .max,
                      onPressed: onInstall,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
