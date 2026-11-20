import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_shelf/local_shelf.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'helpers/fake_drag_out.dart';
import 'helpers/test_app.dart';

/// Lets the shelf's file work finish, then draws what changed.
Future<void> settle(WidgetTester tester) async {
  for (var round = 0; round < 40; round++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
  }
}

void main() {
  late Directory root;
  late ShelfStore store;
  late Set<String> hiddenDevices;
  late ShelfViewModel viewModel;
  late FakeDragOut dragOut;
  var opened = 0;

  Future<void> setUpShelf(WidgetTester tester) async {
    await tester.runAsync(() async {
      root = Directory.systemTemp.createTempSync('shelf_widgets_test');
      store = ShelfStore(p.join(root.path, 'shelf'));
      await store.load();
    });
    hiddenDevices = {};
    opened = 0;
    dragOut = FakeDragOut();
    viewModel = ShelfViewModel(
      localDeviceId: 'mac',
      showsPreviewsFrom: (deviceId) => !hiddenDevices.contains(deviceId),
      nameOf: (deviceId) => 'Pixel 9',
      dragOut: dragOut,
    )..attach(store);
  }

  Future<void> keep(WidgetTester tester, List<String> texts) async {
    await tester.runAsync(() async {
      for (final text in texts) {
        await store.keepText(
          text,
          isLink: ShelfNames.isWebAddress(text),
          source: .copied,
        );
      }

      await pumpEventQueue();
    });
  }

  Widget bar() => ChangeNotifierProvider.value(
    value: viewModel,
    child: ShelfBoxFrame(onOpenList: () => opened++),
  );

  Widget boxApp() => testApp(
    Align(
      alignment: .bottomCenter,
      child: SizedBox(width: 380, child: bar()),
    ),
  );

  /// Presses on [finder] and moves, as a drag out starts.
  Future<void> dragFrom(WidgetTester tester, Finder finder) async {
    final gesture = await tester.startGesture(
      tester.getCenter(finder),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(0, -40));
    await gesture.up();
    await tester.pump();
  }

  Finder tile(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(ShelfTile));

  tearDown(() => root.deleteSync(recursive: true));

  testWidgets('the empty box asks for a drop', (tester) async {
    await setUpShelf(tester);
    await tester.pumpWidget(boxApp());

    expect(find.text('Drop here to keep it for later'), findsOneWidget);
    expect(find.byType(DashedOutline), findsOneWidget);

    viewModel.hover(over: true);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Drop to keep it'), findsOneWidget);
  });

  testWidgets('with items it shows each one, with its name', (tester) async {
    await setUpShelf(tester);
    await keep(tester, ['note', 'https://ex.co/a']);
    await tester.pumpWidget(boxApp());

    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('All 2'), findsOneWidget);
    expect(find.byType(ShelfThumb), findsNWidgets(2));
    expect(find.text('note'), findsOneWidget);
    expect(find.text('ex.co/a'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Open the list'));
    expect(opened, 1);
  });

  testWidgets('dragging a tile takes that one out', (tester) async {
    await setUpShelf(tester);
    await keep(tester, ['note', 'https://ex.co/a']);
    await tester.pumpWidget(boxApp());

    await dragFrom(tester, tile('ex.co/a'));
    await settle(tester);

    expect(dragOut.texts, [('https://ex.co/a', true)]);
    expect(dragOut.fileDrags, isEmpty);
  });

  testWidgets('the stack drags everything out', (tester) async {
    await setUpShelf(tester);
    await keep(tester, ['note', 'https://ex.co/a']);
    await tester.pumpWidget(boxApp());

    await dragFrom(tester, tile('All 2'));
    await settle(tester);

    expect(dragOut.fileDrags, hasLength(1));
    expect(dragOut.fileDrags.single, hasLength(2));
  });

  testWidgets('the arrow keys move the selection along the row', (
    tester,
  ) async {
    await setUpShelf(tester);
    await keep(tester, ['first', 'second', 'third']);
    await tester.pumpWidget(boxApp());
    final ids = [for (final item in viewModel.items) item.id];

    await tester.tap(tile(viewModel.items.first.name));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(viewModel.selected, {ids[1]});

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(viewModel.selected, {ids[1], ids[2]});

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(viewModel.selected, {ids[0]});

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);
    expect(viewModel.items.map((item) => item.id), [ids[1], ids[2]]);
  });

  testWidgets('a selection made with ⌘-click drags out together', (
    tester,
  ) async {
    await setUpShelf(tester);
    await keep(tester, ['first', 'second', 'third']);
    await tester.pumpWidget(boxApp());

    await tester.tap(tile('first'));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.tap(tile('third'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();

    expect(viewModel.selected, hasLength(2));
    expect(find.text('2 selected'), findsOneWidget);

    await dragFrom(tester, tile('third'));
    await settle(tester);

    expect(dragOut.fileDrags, hasLength(1));
    final names = [
      for (final path in dragOut.fileDrags.single) p.basename(path),
    ];
    expect(names, hasLength(2));
    expect(names.any((name) => name.startsWith('second')), isFalse);
  });

  testWidgets('ⓧ on a tile under the pointer takes it off', (tester) async {
    await setUpShelf(tester);
    await keep(tester, ['keep me', 'take me']);
    await tester.pumpWidget(boxApp());

    expect(find.bySemanticsLabel('Remove'), findsNothing);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(tile('take me')));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Remove'));
    await settle(tester);
    await mouse.removePointer();

    expect(find.text('take me'), findsNothing);
    expect(find.text('keep me'), findsOneWidget);
  });

  testWidgets('Clear in the box asks once more for many items', (
    tester,
  ) async {
    await setUpShelf(tester);
    await keep(tester, [for (var index = 0; index < 6; index++) 'note $index']);
    await tester.pumpWidget(boxApp());

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(find.text('Clear 6'), findsOneWidget);

    await tester.tap(find.text('Clear 6'));
    await settle(tester);

    expect(find.text('Drop here to keep it for later'), findsOneWidget);
  });

  testWidgets('hidden previews show only how many', (tester) async {
    await setUpShelf(tester);
    await keep(tester, ['a secret plan']);
    hiddenDevices = {'mac'};
    viewModel.previewsChanged();
    await tester.pumpWidget(boxApp());

    expect(find.text('1 item, hidden'), findsOneWidget);
    expect(find.byType(ShelfThumb), findsNothing);
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('the page lists items and takes one off', (tester) async {
    await setUpShelf(tester);
    await keep(tester, ['first note', 'second note']);
    await tester.pumpWidget(testApp(ShelfPage(viewModel: viewModel)));
    await tester.pump();

    expect(find.text('second note'), findsOneWidget);
    expect(find.text('Text · Copied'), findsNWidgets(2));

    await tester.tap(find.bySemanticsLabel('Remove').first);
    await settle(tester);

    expect(find.text('second note'), findsNothing);
    expect(find.text('first note'), findsOneWidget);
  });

  testWidgets('Clear asks once more for many items', (tester) async {
    await setUpShelf(tester);
    await keep(tester, [for (var index = 0; index < 6; index++) 'note $index']);
    await tester.pumpWidget(testApp(ShelfPage(viewModel: viewModel)));
    await tester.pump();

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(find.text('Clear 6'), findsOneWidget);

    await tester.tap(find.text('Clear 6'));
    await settle(tester);

    expect(find.text('Nothing on the shelf yet'), findsOneWidget);
  });

  testWidgets('Keep copies is off on the page until turned on', (
    tester,
  ) async {
    await setUpShelf(tester);
    final settings = ShelfSettings(MemorySettingsStore());
    viewModel = ShelfViewModel(localDeviceId: 'mac', settings: settings)
      ..attach(store);
    await tester.pumpWidget(testApp(ShelfPage(viewModel: viewModel)));
    await tester.pump();

    expect(find.text('Keep copies'), findsOneWidget);
    expect(
      find.text(
        "Only what you drop stays here. Ferret doesn't watch your clipboard "
        'for the shelf.',
      ),
      findsOneWidget,
    );
    expect(find.text('Keep them'), findsNothing);

    await tester.tap(find.byType(SwitchToggle));
    await tester.pumpAndSettle();
    await settle(tester);

    expect(settings.keepCopies, isTrue);
    expect(find.text('Keep them'), findsOneWidget);
    expect(find.text('Until quit'), findsOneWidget);
  });
}
