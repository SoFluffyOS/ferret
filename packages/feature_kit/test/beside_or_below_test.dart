import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

Widget _sized(double width, Widget child) => Directionality(
  textDirection: .ltr,
  child: FluffyTheme(
    data: FluffyThemeData.fallback(brightness: .light),
    child: Align(
      alignment: .topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

const _words = SizedBox(width: 400, height: 40, key: ValueKey('words'));

Widget _control(double width) =>
    SizedBox(width: width, height: 30, key: const ValueKey('control'));

void main() {
  testWidgets('a narrow control sits at the end, centred on the words', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sized(300, BesideOrBelow(gap: 8, children: [_words, _control(60)])),
    );

    final control = tester.getRect(find.byKey(const ValueKey('control')));
    expect(control.right, 300);
    expect(control.center.dy, 20);
    expect(tester.getSize(find.byType(BesideOrBelow)).height, 40);
    expect(
      tester.getSize(find.byKey(const ValueKey('words'))).width,
      300 - 60 - 8,
    );
  });

  testWidgets('a wide control goes under the words, which keep the width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sized(300, BesideOrBelow(gap: 8, children: [_words, _control(200)])),
    );

    final words = tester.getRect(find.byKey(const ValueKey('words')));
    final control = tester.getRect(find.byKey(const ValueKey('control')));
    expect(words.width, 300);
    expect(control.left, 0);
    expect(control.top, 48);
    expect(tester.getSize(find.byType(BesideOrBelow)).height, 78);
  });

  testWidgets('a phone settings row with a long button keeps its words '
      'readable at 130% on a 320 dp screen', (tester) async {
    debugDefaultTargetPlatformOverride = .android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _sized(
        288,
        GroupedRow(
          title: 'Continue from any app',
          subtitle: 'Make Ferret your digital assistant.',
          trailing: GhostButton(
            mainAxisSize: .min,
            label: 'Open now',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final title = tester.getRect(find.text('Continue from any app'));
    final button = tester.getRect(find.text('Open now'));
    expect(title.width, greaterThan(150));
    expect(button.top, greaterThan(title.bottom));
  });
}
