import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

Widget _page({required double keyboard}) => MediaQuery(
  data: MediaQueryData(
    viewInsets: EdgeInsets.only(bottom: keyboard),
  ),
  child: Directionality(
    textDirection: .ltr,
    child: FluffyTheme(
      data: FluffyThemeData.fallback(brightness: .light),
      child: Navigator(
        onGenerateRoute: (_) => PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => const FerretPage(
            title: 'Device',
            children: [SizedBox(height: 2000), Text('Name')],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('the body ends above the on-screen keyboard', (tester) async {
    await tester.pumpWidget(_page(keyboard: 0));
    final withoutKeyboard = tester.getRect(find.byType(ListView)).bottom;

    await tester.pumpWidget(_page(keyboard: 300));
    final withKeyboard = tester.getRect(find.byType(ListView)).bottom;

    expect(withKeyboard, withoutKeyboard - 300);
  });
}
