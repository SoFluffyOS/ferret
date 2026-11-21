import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
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

  test('the popover\'s corner is macOS\'s 20, and what sits in it keeps '
      'a floor', () {
    expect(Corners.popover, 20);
    expect(Corners.floatingPanel, Corners.popover);
    expect(Corners.concentric(Corners.popover, 8), 12);
    expect(Corners.concentric(12, 4), 8);
    expect(Corners.concentric(8, 4), 4);
    expect(Corners.concentric(8, 8), Corners.windowMinimum);
    expect(Corners.concentric(8, 8, minimum: 12), 12);
  });

  test('a window\'s corner is the system\'s: 16 on a Mac, 8 on Windows, 12 '
      'on Linux, and a list line 8 in from its side is concentric', () {
    debugDefaultTargetPlatformOverride = .macOS;
    expect(Corners.window, 16);
    expect(Corners.concentric(Corners.window, 8), Corners.row);
    expect(Corners.concentric(Corners.window, 4), 12);
    debugDefaultTargetPlatformOverride = .windows;
    expect(Corners.window, 8);
    debugDefaultTargetPlatformOverride = .linux;
    expect(Corners.window, 12);
    debugDefaultTargetPlatformOverride = null;
  });

  test('a control in a card shares its corner on touch screens', () {
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      expect(Corners.control, 12, reason: platform.name);
      expect(Corners.card - PageInsets.row, lessThanOrEqualTo(12));
    }
    debugDefaultTargetPlatformOverride = .android;
    expect(Corners.inner(Corners.card, PageInsets.row), Corners.control);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a button at the end of a card\'s last row is as far from the '
      'card\'s bottom as from its side; a middle row keeps its height', (
    tester,
  ) async {
    Widget button(String label) => Button(
      variant: .ghost,
      padding: const EdgeInsets.all(8),
      onPressed: () {},
      child: SizedBox.square(dimension: 16, child: Text(label)),
    );
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 320,
          child: GroupedCard(
            children: [
              const GroupedRow(title: 'First'),
              GroupedRow(title: 'Middle', trailing: button('m')),
              GroupedRow(title: 'Last', trailing: button('l')),
            ],
          ),
        ),
      ),
    );

    final card = tester.getRect(find.byType(GroupedCard));
    final last = tester.getRect(
      find.ancestor(of: find.text('l'), matching: find.byType(Button)),
    );
    expect(card.right - last.right, PageInsets.row);
    expect(card.bottom - last.bottom, PageInsets.row);

    final middle = tester.getRect(
      find.ancestor(of: find.text('m'), matching: find.byType(GroupedRow)),
    );
    final middleButton = tester.getRect(
      find.ancestor(of: find.text('m'), matching: find.byType(Button)),
    );
    expect(middle.bottom - middleButton.bottom, Spacing.d8);
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
