import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

Widget _page({required double keyboard, double homeIndicator = 0}) =>
    MediaQuery(
      data: MediaQueryData(
        viewInsets: EdgeInsets.only(bottom: keyboard),
        padding: EdgeInsets.only(bottom: homeIndicator),
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
  testWidgets('a screen reader gets the title and section titles as headings, '
      'and each line and link as its own stop', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_readPage());
    await tester.pump();

    expect(
      tester.getSemantics(find.text('Clipboard')),
      isSemantics(label: 'Clipboard', isHeader: true),
    );
    expect(
      tester.getSemantics(find.text('History')),
      isSemantics(label: 'History', isHeader: true),
    );
    expect(
      tester.getSemantics(find.text('History is empty.')),
      isSemantics(label: 'History is empty.'),
    );
    expect(
      tester.getSemantics(find.text('Clear history')),
      isSemantics(
        label: 'Clear history',
        isButton: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });
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

  testWidgets('the list runs under the home indicator and ends clear of it', (
    tester,
  ) async {
    await tester.pumpWidget(_page(keyboard: 0, homeIndicator: 20));
    final screen = tester.getRect(find.byType(Navigator)).bottom;
    expect(tester.getRect(find.byType(ListView)).bottom, screen);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Name')).bottom,
      lessThanOrEqualTo(screen - 20 - 24),
    );
  });
}

Widget _readPage() => MediaQuery(
  data: const MediaQueryData(size: Size(400, 800)),
  child: Directionality(
    textDirection: .ltr,
    child: FluffyTheme(
      data: FluffyThemeData.fallback(brightness: .light),
      child: Navigator(
        onGenerateRoute: (_) => PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => FerretPage(
            title: 'Clipboard',
            children: [
              const SectionTitle('History'),
              const Text('History is empty.'),
              TextLink(label: 'Clear history', onTap: () {}),
            ],
          ),
        ),
      ),
    ),
  ),
);
