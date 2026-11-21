import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

Widget _app(Widget child) => MediaQuery(
  data: const MediaQueryData(size: Size(390, 844)),
  child: Directionality(
    textDirection: .ltr,
    child: FluffyTheme(
      data: FluffyThemeData.fallback(brightness: .light),
      child: child,
    ),
  ),
);

void main() {
  test('a dialog on a touch screen is Material 3\'s 28, its buttons\' 12 '
      'plus its inset', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(Corners.dialog, 28, reason: platform.name);
      expect(
        Corners.inner(Corners.dialog, Corners.dialogInset),
        Corners.control,
      );
    }
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a button at a dialog\'s bottom corner is as far from the side '
      'as from the bottom', (tester) async {
    debugDefaultTargetPlatformOverride = .android;
    await tester.pumpWidget(
      _app(
        FerretDialogCard(
          title: const Text('Shut down MacBook Air?'),
          content: const Text('It counts down 10 seconds first.'),
          actions: [
            Button(variant: .primary, label: 'Shut down', onPressed: () {}),
          ],
        ),
      ),
    );
    final dialog = tester.getRect(
      find
          .ancestor(
            of: find.text('Shut down MacBook Air?'),
            matching: find.byType(DecoratedBox),
          )
          .last,
    );
    final button = tester.getRect(find.byType(Button));
    expect(button.left - dialog.left, Corners.dialogInset);
    expect(dialog.bottom - button.bottom, Corners.dialogInset);
    expect(dialog.right - button.right, Corners.dialogInset);
    debugDefaultTargetPlatformOverride = null;
  });
}
