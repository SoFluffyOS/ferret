import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

void main() {
  Widget app(Widget child, {FluffyDensity density = .touch}) =>
      FluffyDensityScope(
        density: density,
        child: FluffyTheme(
          data: FluffyThemeData.fallback(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: child),
          ),
        ),
      );

  Widget icon(VoidCallback onTap) => OutsetTouchTarget(
    child: Tappable(
      onTap: onTap,
      child: const SizedBox.square(key: Key('icon'), dimension: 16),
    ),
  );

  testWidgets('a finger taps 48 dp around a 16 dp icon that lays out at '
      '16', (tester) async {
    var taps = 0;
    await tester.pumpWidget(app(icon(() => taps++)));

    final box = tester.getRect(find.byType(OutsetTouchTarget));
    expect(box.size, const Size.square(16));
    expect(tester.getRect(find.byKey(const Key('icon'))), box);

    await tester.tapAt(box.center + const Offset(-23, -23));
    await tester.tapAt(box.center + const Offset(23, 23));
    expect(taps, 2);
    await tester.tapAt(box.center + const Offset(0, 25));
    expect(taps, 2, reason: 'nothing past the 48 dp square');
  });

  testWidgets('a button keeps its touch look, without the square in the '
      'layout', (tester) async {
    await tester.pumpWidget(
      app(Button(variant: .secondary, label: 'Rename', onPressed: () {})),
    );
    final grown = tester.getSize(find.byType(Button));
    final label = tester.getSize(find.text('Rename'));

    await tester.pumpWidget(
      app(
        OutsetTouchTarget(
          child: Button(variant: .secondary, label: 'Rename', onPressed: () {}),
        ),
      ),
    );

    expect(grown.height, Spacing.d48);
    expect(tester.getSize(find.text('Rename')), label);
    expect(
      tester.getSize(find.byType(OutsetTouchTarget)).height,
      lessThan(grown.height),
    );
  });

  testWidgets('a pointer gets what it lays out', (tester) async {
    var taps = 0;
    await tester.pumpWidget(app(icon(() => taps++), density: .pointer));

    final box = tester.getRect(find.byType(OutsetTouchTarget));
    expect(box.size, const Size.square(16));
    await tester.tapAt(box.center + const Offset(0, 10));
    expect(taps, 0);
  });
}
