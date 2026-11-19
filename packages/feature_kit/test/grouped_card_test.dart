import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color first, Color second) {
  final luminances = [
    first.computeLuminance(),
    second.computeLuminance(),
  ]..sort();
  return (luminances.last + 0.05) / (luminances.first + 0.05);
}

Widget _app(Widget child) => Directionality(
  textDirection: .ltr,
  child: FluffyTheme(
    data: FluffyThemeData.fallback(brightness: .light),
    child: Align(alignment: .topLeft, child: child),
  ),
);

void main() {
  test('a shape inside a corner shares its centre, or is square', () {
    expect(Corners.inner(12, 4), 8);
    expect(Corners.inner(16, 8), 8);
    expect(Corners.inner(12, 12), 0);
    expect(Corners.inner(12, 10), 0);
  });

  test('every place colour carries a white icon at 3:1 or better', () {
    for (final color in PlaceColor.values) {
      expect(
        _contrast(color.fill, PlaceColor.onFill),
        greaterThanOrEqualTo(3),
        reason: color.name,
      );
    }
  });

  testWidgets('rows of a grouped card are set apart by lines that start at '
      'their text, with none above the first or below the last', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 300,
          child: GroupedCard(
            children: [
              GroupedRow(title: 'Clipboard'),
              GroupedRow(title: 'Files'),
              GroupedRow(title: 'Control'),
            ],
          ),
        ),
      ),
    );

    final dividers = find.byType(FluffyDivider);
    expect(dividers, findsNWidgets(2));
    expect(
      tester.widget<FluffyDivider>(dividers.first).indent,
      tester.getTopLeft(find.text('Clipboard')).dx,
    );
    expect(
      tester.getTopLeft(dividers.first).dy,
      greaterThan(tester.getBottomLeft(find.text('Clipboard')).dy),
    );
  });

  testWidgets('a switch row is one stop that says its name and state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 300,
          child: SettingSwitchRow(
            title: 'Open at login',
            body: 'Ferret starts with your computer.',
            value: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(SettingSwitchRow)),
      isSemantics(
        label: 'Open at login\nFerret starts with your computer.',
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a first page leaves out the title its toolbar already says', (
    tester,
  ) async {
    Widget page(String toolbarTitle) => _app(
      PaneToolbarScope(
        title: toolbarTitle,
        child: Navigator(
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) =>
                const FerretPage(title: 'Activity', children: []),
          ),
        ),
      ),
    );

    await tester.pumpWidget(page('Activity'));
    expect(find.text('Activity'), findsNothing);

    await tester.pumpWidget(page('Settings'));
    expect(find.text('Activity'), findsOneWidget);
  });
}
