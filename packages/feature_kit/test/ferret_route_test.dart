import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app() => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  builder: (context, _) => Navigator(
    onGenerateRoute: (_) => PageRouteBuilder<void>(
      pageBuilder: (context, _, _) => GestureDetector(
        onTap: () => Navigator.of(context).push(
          ferretRoute<void>(
            const ColoredBox(
              color: Color(0xFFFFFFFF),
              child: Center(child: Text('Second')),
            ),
          ),
        ),
        child: const Center(child: Text('First')),
      ),
    ),
  ),
);

Future<bool> _swipeGoesBack(WidgetTester tester) async {
  await tester.pumpWidget(_app());
  await tester.tap(find.text('First'));
  await tester.pumpAndSettle();
  await tester.dragFrom(const Offset(4, 300), const Offset(600, 0));
  await tester.pumpAndSettle();

  return find.text('Second').evaluate().isEmpty;
}

void main() {
  testWidgets('on iOS a swipe from the left edge goes back', (tester) async {
    debugDefaultTargetPlatformOverride = .iOS;
    final wentBack = await _swipeGoesBack(tester);
    debugDefaultTargetPlatformOverride = null;

    expect(wentBack, isTrue);
  });

  testWidgets('elsewhere a page opens at once and stays on a swipe', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = .macOS;
    final wentBack = await _swipeGoesBack(tester);
    debugDefaultTargetPlatformOverride = null;

    expect(wentBack, isFalse);
  });
}
