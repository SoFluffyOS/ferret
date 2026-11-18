import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_input/remote_input.dart';

import 'helpers/test_app.dart';

class _Sink implements TouchpadSink {
  double movedX = 0;
  double movedY = 0;
  double scrolledY = 0;
  final List<PointerButton> clicks = [];

  @override
  void move(double dx, double dy, Duration elapsed) {
    movedX += dx;
    movedY += dy;
  }

  @override
  void scroll(double dx, double dy) => scrolledY += dy;

  @override
  void click(PointerButton button) => clicks.add(button);

  @override
  void press(PointerButton button) {}

  @override
  void release(PointerButton button) {}
}

void main() {
  late _Sink sink;
  late ScrollController scroller;

  Future<void> pumpInScrollingParent(WidgetTester tester) async {
    sink = _Sink();
    scroller = ScrollController();
    addTearDown(scroller.dispose);
    await tester.pumpWidget(
      testApp(
        ListView(
          controller: scroller,
          children: [
            SizedBox(
              height: 300,
              child: TouchpadSurface(sink: sink, hint: 'Pad'),
            ),
            const SizedBox(height: 2000),
          ],
        ),
        scroll: false,
      ),
    );
  }

  testWidgets(
    'a finger dragged on the pad moves the pointer, never the page',
    (tester) async {
      await pumpInScrollingParent(tester);

      await tester.drag(
        find.byType(TouchpadSurface),
        const Offset(40, -200),
        touchSlopY: 0,
      );
      await tester.pumpAndSettle();

      expect(scroller.offset, 0);
      expect(sink.movedX, 40);
      expect(sink.movedY, -200);
    },
    variant: TargetPlatformVariant.only(.iOS),
  );

  testWidgets(
    'two fingers scroll the computer, never the page',
    (tester) async {
      await pumpInScrollingParent(tester);
      final center = tester.getCenter(find.byType(TouchpadSurface));

      final first = await tester.startGesture(center - const Offset(30, 0));
      final second = await tester.startGesture(center + const Offset(30, 0));
      for (var step = 0; step < 10; step++) {
        await first.moveBy(const Offset(0, -10));
        await second.moveBy(const Offset(0, -10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await first.up();
      await second.up();
      await tester.pumpAndSettle();

      expect(scroller.offset, 0);
      expect(sink.scrolledY, lessThanOrEqualTo(-100));
      expect(sink.movedY, 0);
    },
    variant: TargetPlatformVariant.only(.iOS),
  );

  testWidgets(
    'a tap clicks and a two-finger tap right-clicks',
    (tester) async {
      await pumpInScrollingParent(tester);
      final center = tester.getCenter(find.byType(TouchpadSurface));

      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 400));
      final first = await tester.startGesture(center);
      final second = await tester.startGesture(center + const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await first.up();
      await second.up();
      await tester.pump(const Duration(milliseconds: 600));

      expect(sink.clicks, [PointerButton.left, PointerButton.right]);
    },
    variant: TargetPlatformVariant.only(.iOS),
  );
}
