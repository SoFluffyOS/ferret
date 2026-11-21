import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

Widget _app(Widget child) => MediaQuery(
  data: const MediaQueryData(size: Size(390, 844)),
  child: Directionality(
    textDirection: .ltr,
    child: FluffyTheme(
      data: FluffyThemeData.fallback(brightness: .light),
      child: child,
    ),
  ),
);

void main() {
  test('a dialog on a touch screen is Material 3\'s 28, its buttons\' 12 '
      'plus its inset', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(Corners.dialog, 28, reason: platform.name);
      expect(
        Corners.inner(Corners.dialog, Corners.dialogInset),
        Corners.control,
      );
    }
    debugDefaultTargetPlatformOverride = null;
  });

  test('a dialog on a computer is its buttons\' 12 plus its inset too', () {
    for (final (platform, corner) in [
      (TargetPlatform.macOS, 28.0),
      (TargetPlatform.windows, 24.0),
      (TargetPlatform.linux, 24.0),
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(Corners.dialog, corner, reason: platform.name);
      expect(Corners.control, 12, reason: platform.name);
      expect(
        Corners.inner(Corners.dialog, Corners.dialogInset),
        Corners.control,
        reason: platform.name,
      );
    }
    debugDefaultTargetPlatformOverride = null;
  });

  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  ]) {
    testWidgets('a button at a dialog\'s bottom corner is as far from the '
        'side as from the bottom, without an outline (${platform.name})', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      await _bottomCorner(tester);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('Return answers yes and Esc answers no', (tester) async {
    debugDefaultTargetPlatformOverride = .macOS;
    final answers = <ConfirmAction>[];
    for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.escape]) {
      await tester.pumpWidget(
        _dialogHost((context) async {
          answers.add(
            await FerretConfirmDialog.show(
              context,
              title: 'Shut down?',
              negativeText: 'Cancel',
              positiveText: 'Shut down',
            ),
          );
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }
    expect(answers, [ConfirmAction.positive, ConfirmAction.negative]);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Esc closes the text dialog without an answer', (tester) async {
    debugDefaultTargetPlatformOverride = .macOS;
    final answers = <String?>['not yet'];
    await tester.pumpWidget(
      _dialogHost((context) async {
        answers.add(
          await FerretTextDialog.show(
            context,
            title: 'Rename',
            labelText: 'Name',
            cancelText: 'Cancel',
            confirmText: 'Rename',
            initialValue: 'Pixel 9',
          ),
        );
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(answers, ['not yet', null]);
    expect(find.text('Rename'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}

Widget _dialogHost(Future<void> Function(BuildContext context) open) =>
    WidgetsApp(
      color: const Color(0xFFFFFFFF),
      builder: (context, _) => FluffyTheme(
        data: FluffyThemeData.fallback(brightness: .light),
        child: Navigator(
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (context, _, _) => Center(
              child: GestureDetector(
                onTap: () => open(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

Future<void> _bottomCorner(WidgetTester tester) async {
  await tester.pumpWidget(
    _app(
      FerretDialogCard(
        title: const Text('Shut down MacBook Air?'),
        content: const Text('It counts down 10 seconds first.'),
        actions: [
          Button(variant: .primary, label: 'Shut down', onPressed: () {}),
        ],
      ),
    ),
  );
  final dialog = tester.getRect(
    find
        .ancestor(
          of: find.text('Shut down MacBook Air?'),
          matching: find.byType(DecoratedBox),
        )
        .last,
  );
  final button = tester.getRect(find.byType(Button));
  expect(button.left - dialog.left, Corners.dialogInset);
  expect(dialog.bottom - button.bottom, Corners.dialogInset);
  expect(dialog.right - button.right, Corners.dialogInset);
  final shape = tester
      .widgetList<DecoratedBox>(find.byType(DecoratedBox))
      .map((box) => box.decoration)
      .whereType<ShapeDecoration>()
      .map((decoration) => decoration.shape)
      .whereType<RoundedSuperellipseBorder>()
      .firstWhere(
        (shape) => shape.borderRadius == Corners.radius(Corners.dialog),
      );
  expect(shape.side, BorderSide.none);
}
