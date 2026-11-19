import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/keyboard_line.dart';
import 'package:shell/ui/widgets/row_action_button.dart';
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

    return _RevealOnPointerOrFocus(
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
    final actionsOwnLine =
        hasLargeText || textActions.length > _actionsBesideDetail;

    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PageInsets.row,
        vertical: Spacing.d6,
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          switch (item.leading) {
            final leading? => leading,
            null => Padding(
              padding: EdgeInsets.only(top: Spacing.d2),
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
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: textLines,
                        overflow: .ellipsis,
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
                      _IconAction(action: action),
                    if (onDismiss != null)
                      _IconAction(
                        action: ActivityAction(
                          label: context.shellL10n.activityDismiss,
                          icon: LucideIcons.x,
                          onPressed: onDismiss,
                        ),
                        muted: true,
                      ),
                  ],
                ),
                if (detail != null ||
                    (textActions.isNotEmpty && !actionsOwnLine)) ...[
                  Spacing.vertical(Spacing.d2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          detail ?? '',
                          maxLines: textLines,
                          overflow: .ellipsis,
                          style: typography.caption1.copyWith(
                            color: palette.mutedText,
                          ),
                        ),
                      ),
                      if (!actionsOwnLine)
                        for (final action in textActions) ...[
                          Spacing.h8,
                          _TextAction(
                            action: action,
                            filled: holdsPrimary,
                            isShown: showsLinks,
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
                        _TextAction(
                          action: action,
                          filled: holdsPrimary,
                          isShown: showsLinks,
                        ),
                    ],
                  ),
                ],
                if (item.progress case final progress?) ...[
                  Spacing.v6,
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
          null => _FocusableLine(focusNode: focusNode, child: row),
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
        label: action.label,
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

/// A line that opens nothing by itself still takes the keyboard, and
/// shows it has it the way a tappable line does.
class _FocusableLine extends StatefulWidget {
  const _FocusableLine({required this.focusNode, required this.child});

  final FocusNode focusNode;
  final Widget child;

  @override
  State<_FocusableLine> createState() => _FocusableLineState();
}

class _FocusableLineState extends State<_FocusableLine> {
  bool _showsFocus = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      onShowFocusHighlight: (shows) => setState(() => _showsFocus = shows),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: switch (_showsFocus) {
            true => context.palette.surface,
            false => null,
          },
          shape: Corners.shape(Corners.row),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Tells [builder] whether the pointer is over what it builds or the
/// keyboard's focus is inside it.
class _RevealOnPointerOrFocus extends StatefulWidget {
  const _RevealOnPointerOrFocus({required this.builder});

  final Widget Function(BuildContext context, bool isRevealed) builder;

  @override
  State<_RevealOnPointerOrFocus> createState() =>
      _RevealOnPointerOrFocusState();
}

class _RevealOnPointerOrFocusState extends State<_RevealOnPointerOrFocus> {
  bool _isHovered = false;
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
        child: widget.builder(context, _isHovered || _hasFocus),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.action,
    required this.filled,
    required this.isShown,
  });

  final ActivityAction action;
  final bool filled;

  /// A link that isn't shown keeps its place and can still be reached.
  final bool isShown;

  @override
  Widget build(BuildContext context) {
    if (action.primary) {
      return RowActionButton(
        label: action.label,
        isPrimary: filled,
        onPressed: action.onPressed,
      );
    }

    return Opacity(
      opacity: switch (isShown) {
        true => 1,
        false => 0,
      },
      alwaysIncludeSemantics: true,
      child: Tappable(
        onTap: action.onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Spacing.d4,
            vertical: Spacing.d2,
          ),
          child: Text(
            action.label,
            style: context.fluffyTheme.typography.caption1.copyWith(
              color: context.palette.link,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.action, this.muted = false});

  final ActivityAction action;

  /// Drawn quieter, for the ✕ that only tidies up.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      tooltip: action.label,
      onTap: action.onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Spacing.d6),
        child: Icon(
          action.icon,
          size: Spacing.d16,
          color: switch (muted) {
            true => context.palette.mutedText,
            false => context.palette.text,
          },
        ),
      ),
    );
  }
}
