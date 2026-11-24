import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/ui/widgets/widgets.dart';
import 'package:handoff/view_models/handoff_view_model.dart';
import 'package:protocol/handoff.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Handoff's lines in Home's Activity list: what other devices offer to
/// continue here, each with Open and a ✕ to let it go, and what was sent
/// between devices, kept with the history so it is still there after a
/// restart.
abstract final class HandoffActivity {
  /// One line per suggestion. [onOpen] continues it on this device;
  /// [onDismiss] lets it go. One that couldn't open by itself also offers
  /// [onCopy].
  static List<ActivityItem> items(
    HandoffLocalizations l10n,
    List<Suggestion> suggestions, {
    required ValueChanged<Suggestion> onOpen,
    ValueChanged<Suggestion>? onDismiss,
    ValueChanged<Suggestion>? onCopy,
  }) => [
    for (final suggestion in suggestions)
      ActivityItem(
        id: suggestion.id,
        icon: SuggestionTile.iconFor(suggestion.activity.kind),
        title: _title(l10n, suggestion),
        detail: switch (suggestion.openFailed) {
          true => _label(suggestion.activity),
          false => _site(suggestion.activity),
        },
        at: suggestion.receivedAt,
        deviceId: suggestion.from.id,
        tone: switch (suggestion.openFailed) {
          true => .warning,
          false => .normal,
        },
        actions: [
          if (onCopy != null && suggestion.openFailed)
            ActivityAction(
              label: l10n.copy,
              onPressed: () => onCopy(suggestion),
            ),
          ActivityAction(label: l10n.open, onPressed: () => onOpen(suggestion)),
        ],
        onDismiss: switch (onDismiss) {
          final onDismiss? => () => onDismiss(suggestion),
          null => null,
        },
      ),
  ];

  /// One line per link or text sent on purpose, in [entries], except those
  /// [items] already shows as a suggestion with the id in [shown].
  static List<ActivityItem> history(
    HandoffLocalizations l10n,
    List<TimelineEntry> entries, {
    Set<String> shown = const {},
    required ValueChanged<TimelineEntry> onOpen,
    required ValueChanged<TimelineEntry> onCopy,
    required ValueChanged<TimelineEntry> onForget,
  }) => [
    for (final entry in entries)
      if (entry.isExplicit && !shown.contains(entry.activity.id))
        ActivityItem(
          id: 'handoff.${entry.direction.name}.${entry.activity.id}',
          icon: SuggestionTile.iconFor(entry.activity.kind),
          title: _historyTitle(l10n, entry),
          detail: _label(entry.activity),
          at: entry.at,
          deviceId: entry.peer.id,
          tone: switch (entry.openFailed) {
            true => .warning,
            false => .muted,
          },
          actions: [
            if (entry.direction == .received) ...[
              ActivityAction(label: l10n.copy, onPressed: () => onCopy(entry)),
              ActivityAction(label: l10n.open, onPressed: () => onOpen(entry)),
            ],
          ],
          onDismiss: () => onForget(entry),
          private: _private(entry, _historyTitle(l10n, entry)),
        ),
  ];

  /// Opens [entry] here again, and says so when it couldn't.
  static Future<void> reopen(
    BuildContext context,
    HandoffViewModel viewModel,
    TimelineEntry entry,
  ) async {
    final l10n = context.handoffL10n;
    final result = await viewModel.reopen(entry);
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

  /// Puts the link or text of [activity] on the clipboard.
  static Future<void> copy(
    BuildContext context,
    HandoffViewModel viewModel,
    Activity activity,
  ) async {
    final l10n = context.handoffL10n;
    await viewModel.copy(activity);
    if (!context.mounted) {
      return;
    }

    context.toast(l10n.copied);
  }

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
    if (suggestion.openFailed) {
      return l10n.activityReceivedNotOpened(suggestion.from.name);
    }

    final title = suggestion.activity.title;
    if (title.isEmpty) {
      return l10n.continueUntitledFrom(suggestion.from.name);
    }

    return l10n.continueFrom(title, suggestion.from.name);
  }

  static String _historyTitle(HandoffLocalizations l10n, TimelineEntry entry) {
    final name = entry.peer.name;
    return switch ((entry.direction, entry.openFailed)) {
      (.sent, false) => l10n.activitySent(name),
      (.sent, true) => l10n.activitySentNotOpened(name),
      (.received, false) => l10n.activityReceived(name),
      (.received, true) => l10n.activityReceivedNotOpened(name),
    };
  }

  /// The title, with the site after it for a web page on another site.
  static String _label(Activity activity) {
    final site = _site(activity);
    if (site == null || activity.title.isEmpty) {
      return switch (activity.title) {
        '' => site ?? activity.uri,
        final title => title,
      };
    }

    return '${activity.title} · $site';
  }

  /// Text another device sent is as private as a clip; a link is not.
  static PrivateContent? _private(TimelineEntry entry, String title) {
    if (entry.direction != .received ||
        entry.activity.kind != .ACTIVITY_KIND_TEXT) {
      return null;
    }

    return PrivateContent(entry.peer.id, cover: title);
  }

  /// The site a web page is on, without "www.". Null for anything that is
  /// not a web page, and when the title already is the site.
  static String? _site(Activity activity) {
    final uri = Uri.tryParse(activity.uri);
    if (uri == null || !uri.scheme.startsWith('http') || uri.host.isEmpty) {
      return null;
    }

    final site = uri.host.replaceFirst(RegExp(r'^www\.'), '');
    if (site == activity.title) {
      return null;
    }

    return site;
  }
}
