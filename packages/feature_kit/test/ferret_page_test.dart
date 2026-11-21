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

Widget _titled(String title, FerretPageTitle style) => MediaQuery(
  data: const MediaQueryData(size: Size(400, 600)),
  child: Directionality(
    textDirection: .ltr,
    child: FluffyTheme(
      data: FluffyThemeData.fallback(brightness: .light),
      child: Navigator(
        onGenerateRoute: (_) => PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => FerretPage(
            title: title,
            titleStyle: style,
            actions: const [SizedBox(width: 80, height: 32)],
            children: const [SizedBox(height: 10)],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a first page keeps no way back while a dialog is over it', (
    tester,
  ) async {
    await tester.pumpWidget(_titled('Ferret', .large));
    expect(find.byType(DirectionalIcon), findsNothing);

    final context = tester.element(find.byType(FerretPage));
    showGeneralDialog<void>(
      context: context,
      pageBuilder: (_, _, _) => const SizedBox(width: 10, height: 10),
    ).ignore();
    await tester.pumpAndSettle();

    expect(find.byType(DirectionalIcon), findsNothing);
  });

  const longName = 'PXL_20261119_093512345.NIGHT.from-the-team-wiki-export.jpg';

  testWidgets('an inline title keeps one line and both ends of a name', (
    tester,
  ) async {
    await tester.pumpWidget(_titled(longName, .inline));

    final shown = tester.widget<Text>(find.byType(Text).first).data ?? '';
    expect(shown, contains('…'));
    expect(shown, startsWith('PXL_'));
    expect(shown, endsWith('.jpg'));
    expect(find.bySemanticsLabel(longName), findsOneWidget);
  });

  testWidgets('a large title may take two lines', (tester) async {
    await tester.pumpWidget(_titled(longName, .large));

    expect(find.textContaining(longName, findRichText: true), findsOneWidget);
  });

  testWidgets('the body ends above the on-screen keyboard', (tester) async {
    await tester.pumpWidget(_page(keyboard: 0));
    final withoutKeyboard = tester.getRect(find.byType(ListView)).bottom;

    await tester.pumpWidget(_page(keyboard: 300));
    final withKeyboard = tester.getRect(find.byType(ListView)).bottom;

    expect(withKeyboard, withoutKeyboard - 300);
  });
}
