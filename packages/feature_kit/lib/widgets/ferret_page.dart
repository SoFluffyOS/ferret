import 'package:feature_kit/layout/layout.dart';
import 'package:feature_kit/theme/theme.dart';
import 'package:feature_kit/widgets/directional_icon.dart';
import 'package:feature_kit/widgets/middle_ellipsis_text.dart';
import 'package:feature_kit/widgets/pane_toolbar_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// How a [FerretPage] shows its title.
enum FerretPageTitle {
  /// Big and bold, up to two lines: a page that is a place, such as
  /// Settings.
  large,

  /// One headline-sized line that drops the middle of a long name, beside
  /// the back button and the actions: a page about one thing, such as a
  /// photo named after its file, like a detail view in Finder or Photos.
  inline,
}

/// A full page with a title bar and a scrolling body. Pages pushed on top get
/// a back button. On a large view the body stops at [width] and is centred,
/// so nothing stretches across a window.
class FerretPage extends StatelessWidget {
  const FerretPage({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.backLabel = 'Back',
    this.status,
    this.footer,
    this.width = .page,
    this.titleStyle = .large,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  final String backLabel;

  /// One word next to the title when things aren't as usual, such as
  /// "Paused".
  final String? status;

  /// Stays at the bottom while the body scrolls, such as a one-line hint.
  final Widget? footer;

  /// How wide the body may get on a large view.
  final ContentWidth width;

  final FerretPageTitle titleStyle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final canPop = Navigator.of(context).canPop();
    final screenSize = context.screenSize;
    final side = PageInsets.side(screenSize);
    // A first page that names itself in its body, such as a device in a
    // window's pane, or that the pane's toolbar already names, has nothing
    // to put in a title bar.
    final toolbarTitle = PaneToolbarScope.titleOf(context);
    final isUnderToolbar = toolbarTitle != null;
    final isNamedAbove = !canPop && toolbarTitle == title;
    final shownTitle = switch (isNamedAbove) {
      true => '',
      false => title,
    };
    final hasBar = canPop || shownTitle.isNotEmpty || actions.isNotEmpty;

    // Without a Scaffold nothing else makes room for the on-screen
    // keyboard, and a text field near the bottom would sit under it.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return ColoredBox(
      color: palette.background,
      child: SafeArea(
        minimum: EdgeInsets.only(bottom: keyboard),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            if (hasBar)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  side,
                  Spacing.d12,
                  side,
                  Spacing.d4,
                ),
                child: AdaptiveContent(
                  width: width,
                  child: Row(
                    children: [
                      if (canPop)
                        // Its glyph, not the room around it, lines up with
                        // the page's content.
                        Transform.translate(
                          offset: Offset(-Spacing.d4, 0),
                          child: Tappable(
                            tooltip: backLabel,
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Padding(
                              padding: EdgeInsets.all(Spacing.d4),
                              child: DirectionalIcon(
                                LucideIcons.chevronLeft,
                                size: Spacing.d20,
                                color: palette.text,
                              ),
                            ),
                          ),
                        ),
                      if (canPop)
                        switch (titleStyle) {
                          .large => Spacing.h4,
                          .inline => Spacing.h8,
                        },
                      Expanded(
                        child: switch (titleStyle) {
                          .large => Text.rich(
                            TextSpan(
                              text: shownTitle,
                              children: [
                                if (status case final status?)
                                  TextSpan(
                                    text: '  $status',
                                    style: typography.base2.copyWith(
                                      color: palette.mutedText,
                                    ),
                                  ),
                              ],
                            ),
                            style: typography.title2.copyWith(
                              color: palette.text,
                            ),
                            overflow: .ellipsis,
                            maxLines: 2,
                          ),
                          .inline => MiddleEllipsisText(
                            shownTitle,
                            style: typography.headline6.copyWith(
                              color: palette.text,
                            ),
                          ),
                        },
                      ),
                      ..._spaced(actions),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final margin = AdaptiveContent.marginFor(
                    screenSize,
                    constraints.maxWidth - side * 2,
                    width,
                    textScale: context.textScale,
                  );

                  return ListView(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      side + margin,
                      switch ((hasBar, isUnderToolbar)) {
                        (true, _) when titleStyle == .inline => Spacing.d12,
                        (true, _) => Spacing.d4,
                        (false, true) => Spacing.d8,
                        (false, false) => Spacing.d24,
                      },
                      side + margin,
                      Spacing.d24,
                    ),
                    children: children,
                  );
                },
              ),
            ),
            ?footer,
          ],
        ),
      ),
    );
  }

  /// An inline title keeps its actions apart from itself and from each
  /// other, as a toolbar does; a large one keeps the tight row of icons it
  /// always had.
  List<Widget> _spaced(List<Widget> actions) => switch (titleStyle) {
    .large => actions,
    .inline => [
      for (final (index, action) in actions.indexed) ...[
        switch (index) {
          0 => Spacing.h12,
          _ => Spacing.h8,
        },
        action,
      ],
    ],
  };
}
