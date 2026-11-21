import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The fill the button draws under its label.
Color? _fill(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(Button),
      matching: find.byType(AnimatedContainer),
    ),
  );

  return switch (container.decoration) {
    ShapeDecoration(:final color) => color,
    _ => null,
  };
}

Future<void> _pump(
  WidgetTester tester,
  Brightness brightness, {
  Widget? button,
}) => tester.pumpWidget(
  Directionality(
    textDirection: .ltr,
    child: FluffyTheme(
      data: FluffyThemeData.fallback(brightness: brightness),
      child: Center(
        child: button ?? GhostButton(label: 'Cancel', onPressed: () {}),
      ),
    ),
  ),
);

void main() {
  testWidgets('in dark mode it shows the surface under it, not black', (
    tester,
  ) async {
    await _pump(tester, .dark);
    expect(_fill(tester)?.a, 0);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('in light mode it keeps the kit fill', (tester) async {
    await _pump(tester, .light);
    expect(_fill(tester), FluffyThemeData.fallback().colors.neutral1);
  });

  testWidgets('a filled button left out of GhostFill keeps its fill', (
    tester,
  ) async {
    await _pump(
      tester,
      .dark,
      button: GhostFill(
        applies: false,
        child: Button(variant: .primary, label: 'Pair', onPressed: () {}),
      ),
    );
    expect(_fill(tester), FluffyThemeData.fallback().colors.primary);
  });
}
