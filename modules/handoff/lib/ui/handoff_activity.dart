import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/ui/widgets/widgets.dart';
import 'package:handoff/view_models/handoff_view_model.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Handoff's lines in Home's Activity list: what other devices offer to
/// continue here, each with Open and a ✕ to let it go.
abstract final class HandoffActivity {
  /// One line per suggestion. [onOpen] continues it on this device;
  /// [onDismiss] lets it go.
  static List<ActivityItem> items(
    HandoffLocalizations l10n,
    List<Suggestion> suggestions, {
    required ValueChanged<Suggestion> onOpen,
    ValueChanged<Suggestion>? onDismiss,
  }) => [
    for (final suggestion in suggestions)
      ActivityItem(
        id: suggestion.id,
        icon: SuggestionTile.iconFor(suggestion.activity.kind),
        title: _title(l10n, suggestion),
        detail: _site(suggestion),
        at: suggestion.receivedAt,
        actions: [
          ActivityAction(label: l10n.open, onPressed: () => onOpen(suggestion)),
        ],
        onDismiss: switch (onDismiss) {
          final onDismiss? => () => onDismiss(suggestion),
          null => null,
        },
      ),
  ];

  /// Opens [suggestion] here and says so when it couldn't, or when it waits
  /// for the app to come to the front.
  static Future<void> open(
    BuildContext context,
    HandoffViewModel viewModel,
    Suggestion suggestion,
  ) async {
    final l10n = context.handoffL10n;
    final result = await viewModel.open(suggestion);
    if (!context.mounted) {
      return;
    }

    switch (result) {
      case .opened:
        return;
      case .deferred:
        context.toast(l10n.openDeferred);
      case .failed:
        context.toastError(l10n.openFailed);
    }
  }

  static String _title(HandoffLocalizations l10n, Suggestion suggestion) {
    final title = suggestion.activity.title;
    if (title.isEmpty) {
      return l10n.continueUntitledFrom(suggestion.from.name);
    }

    return l10n.continueFrom(title, suggestion.from.name);
  }

  /// The site a web page is on, without "www.". Null for anything that is
  /// not a web page, and when the title already is the site.
  static String? _site(Suggestion suggestion) {
    final uri = Uri.tryParse(suggestion.activity.uri);
    if (uri == null || !uri.scheme.startsWith('http') || uri.host.isEmpty) {
      return null;
    }

    final site = uri.host.replaceFirst(RegExp(r'^www\.'), '');
    if (site == suggestion.activity.title) {
      return null;
    }

    return site;
  }
}
