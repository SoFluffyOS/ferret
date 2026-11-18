import 'dart:io';

import 'package:drop/drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/files.dart';
import 'support/linked_devices.dart';
import 'support/test_app.dart';
import 'support/transfers.dart';

void main() {
  late LinkedDevices link;

  setUp(() async {
    final inbox = Directory.systemTemp.createTempSync('ferret_drop_ui');
    addTearDown(() => inbox.deleteSync(recursive: true));
    link = await LinkedDevices.start(
      laptopStore: folderStore(inbox),
      phoneStore: folderStore(inbox),
    );
  });

  // Built inside each test so its stream subscriptions run in the test zone.
  DropViewModel newViewModel() {
    final viewModel = DropViewModel(
      feature: link.laptop.feature,
      describeFolder: () async => '/Users/me/Downloads/Ferret',
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  Future<void> pumpCard(WidgetTester tester, {VoidCallback? onSend}) async {
    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: newViewModel(),
          child: DropHomeFrame(onSendFiles: onSend ?? () {}),
        ),
      ),
    );
    await tester.pump();
  }

  // The registry's change event lands after the first frame, so the card
  // rebuilds on the second.
  Future<void> put(WidgetTester tester, Transfer transfer) async {
    link.laptop.feature.registry.put(transfer);
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'an empty card explains how to send and offers the button',
    (tester) async {
      var picked = false;
      await pumpCard(tester, onSend: () => picked = true);

      final hint = switch (defaultTargetPlatform) {
        .android || .iOS => 'Send photos and files to your other devices.',
        _ => 'Drop files here to send them to your devices.',
      };
      expect(find.text(hint), findsOneWidget);
      await tester.tap(find.text('Send files…'));
      expect(picked, isTrue);
    },
    variant: const TargetPlatformVariant({.macOS, .android}),
  );

  testWidgets('a running transfer shows progress, speed, ETA and Cancel', (
    tester,
  ) async {
    await pumpCard(tester);
    await put(
      tester,
      sampleTransfer(
        bytesDone: 1024 * 1024,
        bytesPerSecond: 1024 * 1024,
      ),
    );

    expect(find.text('photo.jpg'), findsOneWidget);
    expect(find.text('From Pixel · 1 MB of 4 MB'), findsOneWidget);
    expect(find.text('1 MB/s · 3 s left'), findsOneWidget);
    expect(find.byType(TransferProgressBar), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('a received file offers Open and Show in folder', (
    tester,
  ) async {
    await pumpCard(tester);
    await put(
      tester,
      sampleTransfer(status: .done, bytesDone: 4 * 1024 * 1024),
    );

    expect(find.text('Saved ✓ · from Pixel'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Show in folder'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.byType(TransferProgressBar), findsNothing);
  });

  testWidgets('a received text offers Copy', (tester) async {
    await pumpCard(tester);
    await put(
      tester,
      sampleTransfer(status: .done, files: const [], text: 'See you at 6'),
    );

    expect(find.text('See you at 6'), findsOneWidget);
    expect(find.text('From Pixel'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('a failure says why in plain words', (tester) async {
    await pumpCard(tester);
    await put(
      tester,
      sampleTransfer(
        direction: .outgoing,
        status: .failed,
        failure: .disconnected,
      ),
    );

    expect(
      find.text("Pixel went offline. It continues when it's back."),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('an offer waiting for an answer shows Accept and Decline', (
    tester,
  ) async {
    await pumpCard(tester);
    await put(tester, sampleTransfer(status: .waiting, needsAnswer: true));

    expect(find.text('Pixel wants to send this'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('settings show the folder and toggle auto accept', (
    tester,
  ) async {
    final viewModel = newViewModel();
    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: const DropSettingsFrame(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Downloads › Ferret'), findsOneWidget);
    expect(find.text('/Users/me/Downloads/Ferret'), findsNothing);
    expect(find.text('Accept from my devices'), findsOneWidget);
    expect(viewModel.autoAccept, isTrue);

    await viewModel.setAutoAccept(false);
    await tester.pump();
    expect(link.laptop.settings.get<bool>(DropSettings.autoAccept), isFalse);
  });
}
