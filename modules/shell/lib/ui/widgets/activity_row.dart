import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/window_commands.dart';
import 'package:shell/ui/widgets/activity_focusable_line.dart';
import 'package:shell/ui/widgets/activity_icon_action.dart';
import 'package:shell/ui/widgets/activity_text_action.dart';
import 'package:shell/ui/widgets/keyboard_line.dart';
import 'package:shell/ui/widgets/reveal_on_pointer_or_focus.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One line of Activity: what happened and with which device, when, a
/// second line with the detail, and what to do about it.
class ActivityRow extends StatelessWidget {
  const ActivityRow({
    super.key,
    required this.item,
    required this.now,
    this.holdsPrimary = true,
    this.quietLinks = false,
  });

  final ActivityItem item;

  /// Whether this line may draw its primary action filled. A screen has one
  /// filled button, so every other line draws the same action outlined.
  final bool holdsPrimary;

  /// Whether the line's links stay out of sight until the pointer or the
  /// keyboard is on the line, so a column of lines isn't a column of blue
  /// words. They keep their place, their Tab stop and their name for a
  /// screen reader. Only under a pointer: a finger has no hover.
  final bool quietLinks;

  /// The moment "2 min" is counted from.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final hidesLinks =
        quietLinks &&
        switch (defaultTargetPlatform) {
          .macOS || .windows || .linux => true,
          .android || .iOS || .fuchsia => false,
        };
    if (!hidesLinks) {
      return _line(context, showsLinks: true);
    }

    return RevealOnPointerOrFocus(
      builder: (context, isRevealed) => _line(context, showsLinks: isRevealed),
    );
  }

  Widget _line(BuildContext context, {required bool showsLinks}) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final iconActions = [
      for (final action in item.actions)
        if (action.icon != null) action,
    ];
    final textActions = [
      for (final action in item.actions)
        if (action.icon == null) action,
    ];
    final detail = item.detail;
    final time = _time(context.shellL10n);
    final trailing = item.trailing;
    final onDismiss = item.onDismiss;
    // With text set large, a line and its buttons no longer share a row:
    // the words wrap and the buttons go below them.
    final hasLargeText = context.hasLargeText;
    final textLines = switch (hasLargeText) {
      true => 3,
      false => 1,
    };
    // A question is read whole: who asks and for what. At large text it
    // takes all the lines it needs.
    final int? titleLines = switch ((hasLargeText, item.needsYou)) {
      (false, true) => 2,
      (true, true) => null,
      _ => textLines,
    };
    // A problem's detail says what to do, so it gets a second line. A
    // question's says what a yes means, so it is never cut short.
    final int? detailLines = switch ((hasLargeText, item.tone)) {
      (false, _) when item.needsYou => 3,
      (true, _) when item.needsYou => null,
      (false, .warning || .danger) => 2,
      _ => textLines,
    };
    final actionsOwnLine =
        hasLargeText || textActions.length > _actionsBesideDetail;
    // Links and icons take the pointer on more height than the words next
    // to them. An icon's target reaches up and a link's reaches down, into
    // the line's own spacing, so the words stay where they were.
    final hasIcons =
        !hasLargeText && (iconActions.isNotEmpty || onDismiss != null);
    final hasLinksOnly =
        textActions.isNotEmpty && !textActions.any((action) => action.primary);
    final linksBesideDetail = hasLinksOnly && !actionsOwnLine;
    final linksEndTheLine = hasLinksOnly && item.progress == null;

    final row = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        PageInsets.row,
        switch (hasIcons) {
          true => 0,
          false => Spacing.d6,
        },
        PageInsets.row,
        switch (linksEndTheLine) {
          true => 0,
          false => Spacing.d6,
        },
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          switch (item.leading) {
            final leading? => leading,
            null => Padding(
              // Level with the title, which sits lower on a line whose
              // icons reach up.
              padding: EdgeInsets.only(
                top: switch (hasIcons) {
                  true => ActivityIconAction.rise,
                  false => Spacing.d2,
                },
              ),
              child: Icon(
                item.icon,
                size: Spacing.d16,
                color: _toneColor(palette),
              ),
            ),
          },
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Row(
                  crossAxisAlignment: switch (hasIcons) {
                    true => .end,
                    false => .center,
                  },
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: titleLines,
                        overflow: _overflow(titleLines),
                        style: typography.base2.copyWith(color: palette.text),
                      ),
                    ),
                    if (trailing != null) ...[Spacing.h8, trailing],
                    if (time != null &&
                        trailing == null &&
                        iconActions.isEmpty) ...[
                      Spacing.h8,
                      Text(
                        time,
                        style: typography.caption1.copyWith(
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                    for (final action in iconActions)
                      ActivityIconAction(action: action, reachesUp: hasIcons),
                    if (onDismiss != null)
                      ActivityIconAction(
                        action: ActivityAction(
                          label: context.shellL10n.activityDismiss,
                          icon: LucideIcons.x,
                          onPressed: onDismiss,
                        ),
                        muted: true,
                        reachesUp: hasIcons,
                      ),
                  ],
                ),
                if (detail != null ||
                    (textActions.isNotEmpty && !actionsOwnLine)) ...[
                  Spacing.vertical(switch (linksBesideDetail) {
                    true => Spacing.d4,
                    false => Spacing.d2,
                  }),
                  Row(
                    crossAxisAlignment: switch (linksBesideDetail) {
                      true => .start,
                      false => .center,
                    },
                    children: [
                      Expanded(
                        child: Text(
                          detail ?? '',
                          maxLines: detailLines,
                          overflow: _overflow(detailLines),
                          style: typography.caption1.copyWith(
                            color: palette.mutedText,
                          ),
                        ),
                      ),
                      if (!actionsOwnLine)
                        for (final action in textActions) ...[
                          Spacing.h8,
                          ActivityTextAction(
                            action: action,
                            subject: item.title,
                            filled: holdsPrimary,
                            isShown: showsLinks,
                            reachesDown: linksBesideDetail,
                          ),
                        ],
                    ],
                  ),
                ],
                if (actionsOwnLine) ...[
                  Spacing.v6,
                  Wrap(
                    spacing: Spacing.d8,
                    runSpacing: Spacing.d6,
                    crossAxisAlignment: .center,
                    children: [
                      for (final action in textActions)
                        ActivityTextAction(
                          action: action,
                          subject: item.title,
                          filled: holdsPrimary,
                          isShown: showsLinks,
                        ),
                    ],
                  ),
                ],
                if (item.progress case final progress?) ...[
                  // A link's target above already keeps the bar away.
                  if (!linksBesideDetail) Spacing.v6,
                  FluffyProgressBar(
                    value: progress.clamp(0, 1).toDouble(),
                    color: palette.accent,
                    backgroundColor: palette.surface,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final files = item.files;
    final menubar = switch (files) {
      [] => null,
      _ => context.read<FerretMenubar?>(),
    };
    final line = KeyboardLine(
      keys: _keys(menubar),
      builder: (context, focusNode) => ContextMenuRegion(
        entries: _menu(context.shellL10n, menubar),
        child: switch (item.onTap) {
          final onTap? => Tappable(
            onTap: onTap,
            focusNode: focusNode,
            child: row,
          ),
          null => ActivityFocusableLine(focusNode: focusNode, child: row),
        },
      ),
    );
    if (menubar == null) {
      return line;
    }

    // A line about files on this Mac is those files: dragged out, they go
    // to Finder or the app they land on.
    return GestureDetector(
      onPanStart: (_) => unawaited(
        menubar.startFileDrag(View.of(context).viewId, files),
      ),
      child: line,
    );
  }

  /// Enter on a line that opens nothing runs its first action instead,
  /// such as Open on a received file. Space shows the line's files in
  /// Quick Look, as in Finder.
  Map<SingleActivator, VoidCallback> _keys(FerretMenubar? menubar) {
    final firstAction = item.actions.firstOrNull;

    return {
      if (item.onTap == null && firstAction != null)
        const SingleActivator(LogicalKeyboardKey.enter): firstAction.onPressed,
      if (menubar != null)
        const SingleActivator(LogicalKeyboardKey.space): () =>
            unawaited(menubar.toggleQuickLook(item.files)),
    };
  }

  /// A right-click on the line: everything the line itself offers.
  List<MenuEntry> _menu(ShellLocalizations l10n, FerretMenubar? menubar) => [
    if (item.onTap case final onTap?)
      MenuEntry(label: l10n.activityOpen, onSelected: onTap),
    if (menubar != null)
      MenuEntry(
        label: l10n.activityQuickLook,
        icon: LucideIcons.eye,
        onSelected: () => unawaited(menubar.toggleQuickLook(item.files)),
      ),
    for (final action in item.actions)
      MenuEntry(
        label: WindowCommands.buttonInMenu(l10n, action.label),
        icon: action.icon,
        onSelected: action.onPressed,
      ),
    if (item.onDismiss case final onDismiss?)
      MenuEntry(
        label: l10n.activityDismiss,
        icon: LucideIcons.x,
        startsGroup: item.onTap != null || item.actions.isNotEmpty,
        onSelected: onDismiss,
      ),
  ];

  /// Two actions fit next to the detail; a third moves them all to a line
  /// of their own.
  static const _actionsBesideDetail = 2;

  String? _time(ShellLocalizations l10n) {
    final at = item.at;
    if (at == null || item.pinned) {
      return null;
    }

    final elapsed = now.difference(at);
    return switch (elapsed) {
      Duration(inMinutes: < 1) => l10n.activityNow,
      Duration(inHours: < 1) => l10n.activityMinutes(elapsed.inMinutes),
      Duration(inDays: < 1) => l10n.activityHours(elapsed.inHours),
      _ => l10n.activityDays(elapsed.inDays),
    };
  }

  Color _toneColor(FerretPalette palette) => switch (item.tone) {
    .normal || .muted => palette.mutedText,
    .accent => palette.link,
    .success => palette.success,
    .warning => palette.warning,
    .danger => palette.danger,
  };
}

/// Ellipsis cuts a text without a line limit to one line, so text that
/// may take all the lines it needs just wraps.
TextOverflow _overflow(int? maxLines) => switch (maxLines) {
  null => .clip,
  _ => .ellipsis,
};
