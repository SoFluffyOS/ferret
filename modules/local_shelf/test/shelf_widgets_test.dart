import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_shelf/local_shelf.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

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
  var opened = 0;

  Future<void> setUpShelf(WidgetTester tester) async {
    await tester.runAsync(() async {
      root = Directory.systemTemp.createTempSync('shelf_widgets_test');
      store = ShelfStore(p.join(root.path, 'shelf'));
      await store.load();
    });
    hiddenDevices = {};
    opened = 0;
    viewModel = ShelfViewModel(
      localDeviceId: 'mac',
      showsPreviewsFrom: (deviceId) => !hiddenDevices.contains(deviceId),
      nameOf: (deviceId) => 'Pixel 9',
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
    child: ShelfBarFrame(onOpen: () => opened++),
  );

  tearDown(() => root.deleteSync(recursive: true));

  testWidgets('the empty bar asks for a drop', (tester) async {
    await setUpShelf(tester);
    await tester.pumpWidget(
      testApp(Align(alignment: .bottomCenter, child: bar())),
    );

    expect(find.text('Drop here to keep it for later'), findsOneWidget);

    viewModel.hover(over: true);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Drop to keep it'), findsOneWidget);
  });

  testWidgets('with items it counts them and opens on a click', (
    tester,
  ) async {
    await setUpShelf(tester);
    await keep(tester, ['note', 'https://example.com']);
    await tester.pumpWidget(
      testApp(Align(alignment: .bottomCenter, child: bar())),
    );

    expect(find.text('2 items'), findsOneWidget);
    expect(find.byType(ShelfThumb), findsNWidgets(2));

    await tester.tap(find.text('2 items'));
    expect(opened, 1);
  });

  testWidgets('hidden previews show only how many', (tester) async {
    await setUpShelf(tester);
    await keep(tester, ['a secret plan']);
    hiddenDevices = {'mac'};
    viewModel.previewsChanged();
    await tester.pumpWidget(
      testApp(Align(alignment: .bottomCenter, child: bar())),
    );

    expect(find.text('1 item, hidden'), findsOneWidget);
    expect(find.byType(ShelfThumb), findsNothing);
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
}
