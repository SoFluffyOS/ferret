import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

Widget _app(Widget child) => Directionality(
  textDirection: .ltr,
  child: Shortcuts(
    shortcuts: WidgetsApp.defaultShortcuts,
    child: Actions(
      actions: WidgetsApp.defaultActions,
      child: FocusScope(
        autofocus: true,
        child: FluffyTheme(
          data: FluffyThemeData.fallback(brightness: .light),
          child: Align(alignment: .topLeft, child: child),
        ),
      ),
    ),
  ),
);

/// The rings drawn around the card: a foreground side in the card's corner.
int _cardRings(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(SurfaceCard),
        matching: find.byType(DecoratedBox),
      ),
    )
    .where(
      (box) =>
          box.position == .foreground &&
          switch (box.decoration) {
            ShapeDecoration(:final RoundedSuperellipseBorder shape) =>
              shape.side.style != BorderStyle.none &&
                  shape.borderRadius == Corners.radius(Corners.card),
            _ => false,
          },
    )
    .length;

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy = .alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = .automatic;
  });

  testWidgets('a card rings itself when focused, and not when focus is on a '
      'button in it; the button then drops its outline', (tester) async {
    final keyboardFocused = <bool>[];
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 300,
          child: SurfaceCard(
            onTap: () {},
            child: ButtonFocusRing(
              builder: (context, focused) {
                keyboardFocused.add(focused);
                return Button(
                  variant: .ghost,
                  label: 'Fix',
                  borderWidth: switch (focused) {
                    true => 0,
                    false => null,
                  },
                  onPressed: () {},
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_cardRings(tester), 1);
    expect(keyboardFocused.last, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_cardRings(tester), 0);
    expect(keyboardFocused.last, isTrue);
  });
}
