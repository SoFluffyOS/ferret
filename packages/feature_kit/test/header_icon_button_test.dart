import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

void main() {
  const card = Key('card');

  Future<void> pumpPage(
    WidgetTester tester, {
    FluffyDensity density = .touch,
    VoidCallback? onAdd,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final page = FerretPage(
      title: 'Ferret',
      actions: [
        HeaderIconButton(
          icon: LucideIcons.plus,
          tooltip: 'Add',
          nudge: HeaderIconButton.endNudge,
          onTap: onAdd,
        ),
        Spacing.h12,
        HeaderIconButton(
          icon: LucideIcons.ellipsis,
          tooltip: 'More',
          nudge: HeaderIconButton.endNudge,
          entries: [MenuEntry(label: 'Settings', onSelected: () {})],
        ),
      ],
      children: const [SizedBox(key: card, height: 40)],
    );

    await tester.pumpWidget(
      FluffyDensityScope(
        density: density,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Directionality(
            textDirection: .ltr,
            child: FluffyTheme(
              data: FluffyThemeData.fallback(brightness: .light),
              child: Navigator(
                onGenerateRoute: (_) => PageRouteBuilder<void>(
                  pageBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(PageRouteBuilder<void>(pageBuilder: (_, _, _) => page)),
    );
    await tester.pumpAndSettle();
  }

  /// Where a 20-point Lucide icon's stroke starts and ends in its box.
  Rect glyph(WidgetTester tester, IconData icon, double inset) {
    final box = tester.getRect(find.byIcon(icon));
    return Rect.fromLTRB(
      box.left + inset,
      box.top,
      box.right - inset,
      box.bottom,
    );
  }

  testWidgets('Back and ••• glyphs line up with the cards, as the title '
      'does', (tester) async {
    await pumpPage(tester);
    final content = tester.getRect(find.byKey(card));

    expect(
      glyph(tester, LucideIcons.ellipsis, HeaderIconButton.endNudge).right,
      closeTo(content.right, 0.01),
    );
    final back = tester.getRect(find.byIcon(LucideIcons.chevronLeft));
    expect(
      back.left - HeaderIconButton.backNudge,
      closeTo(content.left, 0.01),
    );
    expect(
      tester.getCenter(find.byIcon(LucideIcons.ellipsis)).dx -
          tester.getCenter(find.byIcon(LucideIcons.plus)).dx,
      32,
      reason: '+ and ••• keep the room they had',
    );
  });

  testWidgets('a finger taps 48 dp around +, out into the margin', (
    tester,
  ) async {
    var taps = 0;
    await pumpPage(tester, onAdd: () => taps++);
    final plus = tester.getCenter(find.byIcon(LucideIcons.plus));

    await tester.tapAt(plus + const Offset(0, -20));
    await tester.tapAt(plus + const Offset(-23, 0));
    expect(taps, 2);
  });

  testWidgets('the menu meets the content edge, on screen', (tester) async {
    await pumpPage(tester);
    final content = tester.getRect(find.byKey(card));

    await tester.tapAt(
      tester.getCenter(find.byIcon(LucideIcons.ellipsis)) + const Offset(20, 0),
    );
    await tester.pumpAndSettle();

    final menu = tester.getRect(
      find
          .descendant(
            of: find.byType(CompositedTransformFollower),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(menu.right, closeTo(content.right, 0.01));
  });

  testWidgets('a pointer takes the fill, not 48 dp', (tester) async {
    var taps = 0;
    await pumpPage(tester, density: .pointer, onAdd: () => taps++);
    final plus = tester.getCenter(find.byIcon(LucideIcons.plus));

    await tester.tapAt(plus + const Offset(0, -15));
    expect(taps, 1);
    await tester.tapAt(plus + const Offset(0, -20));
    expect(taps, 1);
  });
}
