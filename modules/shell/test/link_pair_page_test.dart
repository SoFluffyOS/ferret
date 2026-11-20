import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

class _FakeEngine implements FerretEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotifier implements LocalNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('a pairing link cut short says so and offers the scanner', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShellScope(
        features: const [],
        featureContext: FeatureContext(
          engine: _FakeEngine(),
          navigatorKey: GlobalKey<NavigatorState>(),
          notifier: _FakeNotifier(),
        ),
        child: testApp(const LinkPairPage(link: 'ferret://pair')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining("That's not a Ferret code."), findsOneWidget);
    expect(find.text('Scan the code on your computer'), findsOneWidget);
  });
}
