import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

Widget _view(Size size, Widget child) => Directionality(
  textDirection: .ltr,
  child: MediaQuery(
    data: MediaQueryData(size: size),
    child: Center(
      child: SizedBox.fromSize(
        size: size,
        child: ScreenSizeScope(child: child),
      ),
    ),
  ),
);

void main() {
  test('content is capped from large up, and only there', () {
    expect(AdaptiveContent.marginFor(.small, 380, .page), 0);
    expect(AdaptiveContent.marginFor(.normal, 800, .narrow), 0);
    expect(AdaptiveContent.marginFor(.large, 840, .page), 60);
    expect(AdaptiveContent.marginFor(.large, 600, .page), 0);
    expect(AdaptiveContent.marginFor(.extraLarge, 1120, .narrow), 320);
    expect(AdaptiveContent.marginFor(.extraLarge, 1120, .fill), 0);
  });

  testWidgets('a resize across the breakpoints keeps the state below', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.reset);
    const content = AdaptiveContent(child: _Counter());

    await tester.pumpWidget(_view(const Size(380, 560), content));
    tester.state<_CounterState>(find.byType(_Counter)).count = 7;
    expect(tester.getSize(find.byType(_Counter)).width, 380);

    await tester.pumpWidget(_view(const Size(1000, 700), content));
    expect(tester.getSize(find.byType(_Counter)).width, PaneWidths.content);
    expect(tester.state<_CounterState>(find.byType(_Counter)).count, 7);

    await tester.pumpWidget(_view(const Size(700, 700), content));
    expect(tester.getSize(find.byType(_Counter)).width, 700);
    expect(tester.state<_CounterState>(find.byType(_Counter)).count, 7);
  });

  testWidgets('a view too short for two panes is small', (tester) async {
    ScreenSize? seen;

    await tester.pumpWidget(
      _view(
        const Size(844, 390),
        Builder(
          builder: (context) {
            seen = context.screenSize;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(seen, ScreenSize.small);
  });
}
