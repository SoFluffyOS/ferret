import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/ui/widgets/widgets.dart';

import 'helpers/test_app.dart';

void main() {
  const title = "Night Harness's display";
  const hint = 'Tap to click · Hold to right-click · Two fingers scroll';

  Future<void> pump(WidgetTester tester, double scale) async {
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    await tester.pumpWidget(
      testApp(
        SizedBox(
          width: 412,
          child: DisplayBar(
            shown: true,
            onLeave: () {},
            title: title,
            hint: hint,
            stopLabel: 'Stop',
            onStop: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the bar keeps Stop beside its words at the usual size', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, 1);

    expect(
      tester.getTopLeft(find.text('Stop')).dx,
      greaterThan(tester.getTopRight(find.text(title)).dx),
    );
  });

  testWidgets('at large text the words wrap whole and Stop goes under them', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, 2);

    final words = tester.renderObject<RenderParagraph>(find.text(hint));
    expect(words.didExceedMaxLines, isFalse);
    expect(
      tester.getTopLeft(find.text('Stop')).dy,
      greaterThan(tester.getBottomLeft(find.text(hint)).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
