import 'package:feature_kit/layout/layout.dart';
import 'package:feature_kit/theme/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final canPop = Navigator.of(context).canPop();
    final screenSize = context.screenSize;
    // A first page that names itself in its body, such as a device in a
    // window's pane, has nothing to put in a title bar.
    final hasBar = canPop || title.isNotEmpty || actions.isNotEmpty;

    return ColoredBox(
      color: palette.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            if (hasBar)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Spacing.d12,
                  Spacing.d12,
                  Spacing.d12,
                  Spacing.d4,
                ),
                child: AdaptiveContent(
                  width: width,
                  child: Row(
                    children: [
                      if (canPop)
                        Tappable(
                          tooltip: backLabel,
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Padding(
                            padding: EdgeInsets.all(Spacing.d4),
                            child: Icon(
                              LucideIcons.chevronLeft,
                              size: Spacing.d20,
                              color: palette.text,
                            ),
                          ),
                        ),
                      if (canPop) Spacing.h4,
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: title,
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
                          maxLines: 1,
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final margin = AdaptiveContent.marginFor(
                    screenSize,
                    constraints.maxWidth - Spacing.d12 * 2,
                    width,
                  );

                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      Spacing.d12 + margin,
                      switch (hasBar) {
                        true => Spacing.d4,
                        false => Spacing.d24,
                      },
                      Spacing.d12 + margin,
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
}
