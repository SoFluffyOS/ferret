import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class _Probe extends StatelessWidget {
  const _Probe(this.builds);

  final List<ScreenSize> builds;

  @override
  Widget build(BuildContext context) {
    builds.add(context.screenSize);
    return const SizedBox.shrink();
  }
}

Widget _sized(double width, Widget child) => MediaQuery(
  data: MediaQueryData(size: Size(width, 600)),
  child: child,
);

void main() {
  testWidgets('two scopes give two sizes at once, each from its own width', (
    tester,
  ) async {
    final popover = <ScreenSize>[];
    final window = <ScreenSize>[];

    await tester.pumpWidget(
      Column(
        children: [
          _sized(380, ScreenSizeScope(child: _Probe(popover))),
          _sized(960, ScreenSizeScope(child: _Probe(window))),
        ],
      ),
    );

    expect(popover.last, ScreenSize.small);
    expect(window.last, ScreenSize.large);
  });

  testWidgets('a resize rebuilds only when the breakpoint changes', (
    tester,
  ) async {
    final builds = <ScreenSize>[];
    final probe = ScreenSizeScope(child: _Probe(builds));

    await tester.pumpWidget(_sized(900, probe));
    await tester.pumpWidget(_sized(1000, probe));
    expect(builds, [ScreenSize.large]);

    await tester.pumpWidget(_sized(1300, probe));
    expect(builds, [ScreenSize.large, ScreenSize.larger]);
  });

  testWidgets('without a scope the size follows the view', (tester) async {
    final builds = <ScreenSize>[];

    await tester.pumpWidget(_sized(700, _Probe(builds)));

    expect(builds.last, ScreenSize.normal);
  });
}
