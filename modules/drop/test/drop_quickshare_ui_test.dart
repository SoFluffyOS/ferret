import 'dart:io';

import 'package:drop/drop.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/files.dart';
import 'support/linked_devices.dart';
import 'support/test_app.dart';
import 'support/transfers.dart';

Transfer _offer({
  TransferStatus status = .waiting,
  TransferFailure? failure,
  bool needsAnswer = true,
}) => Transfer(
  id: 'qs1',
  direction: .incoming,
  deviceId: QuickShareIds.deviceId('abcd'),
  deviceName: QuickShareIds.label('Pixel 8'),
  files: const [
    TransferFile(name: 'a.jpg', size: 1024 * 1024),
    TransferFile(name: 'b.jpg', size: 1024 * 1024),
  ],
  status: status,
  failure: failure,
  startedAt: DateTime(2026, 11, 18),
  needsAnswer: needsAnswer,
  quickShare: const QuickShareOrigin(pin: '0482', address: '192.168.1.30'),
);

void main() {
  late LinkedDevices link;

  Future<void> start({Map<String, Object?> settings = const {}}) async {
    final inbox = Directory.systemTemp.createTempSync('ferret_quickshare_ui');
    addTearDown(() => inbox.deleteSync(recursive: true));
    link = await LinkedDevices.start(
      laptopStore: folderStore(inbox),
      phoneStore: folderStore(inbox),
      laptopSettings: {DropSettings.localSendEnabled: false, ...settings},
      quickShare: QuickShareOptions(
        bindAddress: InternetAddress.loopbackIPv4,
        advertise: false,
      ),
    );
    addTearDown(link.laptop.feature.quickShare.stopReceiving);
  }

  DropViewModel newViewModel() {
    final viewModel = DropViewModel(
      feature: link.laptop.feature,
      describeFolder: () async => '/Users/me/Downloads/Ferret',
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  Future<DropViewModel> pumpCard(WidgetTester tester) async {
    final viewModel = newViewModel();
    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: DropHomeFrame(onSendFiles: () {}),
        ),
      ),
    );
    await tester.pump();
    return viewModel;
  }

  Future<void> put(WidgetTester tester, Transfer transfer) async {
    link.laptop.feature.registry.put(transfer);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Quick Share is offered as a choice, not an error', (
    tester,
  ) async {
    await start();
    await pumpCard(tester);

    expect(find.text('Show 10 min'), findsNothing);
    expect(find.textContaining("can't"), findsNothing);

    await tester.tap(find.text('Let other phones send you files'));
    await tester.pump();

    expect(find.text('Quick Share'), findsOneWidget);
    expect(
      find.text('Let Android phones without Ferret send here.'),
      findsOneWidget,
    );
    expect(find.text('Show 10 min'), findsOneWidget);
  });

  testWidgets('with Quick Share turned off the card does not mention it', (
    tester,
  ) async {
    await start(settings: {DropSettings.quickShareEnabled: false});
    await pumpCard(tester);

    expect(find.text('Quick Share'), findsNothing);
    expect(find.byType(ReceiveRow), findsNothing);
  });

  testWidgets('LocalSend and Quick Share each get their own row', (
    tester,
  ) async {
    await start(settings: {DropSettings.localSendEnabled: true});
    await pumpCard(tester);
    await tester.tap(find.text('Let other phones send you files'));
    await tester.pump();

    expect(find.byType(ReceiveRow), findsNWidgets(2));
    expect(find.text('LocalSend'), findsOneWidget);
    expect(find.text('Quick Share'), findsOneWidget);
  });

  testWidgets('turning it on shows the name and the time left', (tester) async {
    await start();
    final viewModel = await pumpCard(tester);

    await tester.runAsync(viewModel.receiveFromQuickShare);
    await tester.pump();

    expect(viewModel.quickShareState.isOn, isTrue);
    expect(viewModel.quickShareSecondsLeft, inInclusiveRange(595, 600));
    expect(find.textContaining('Visible as Laptop · '), findsOneWidget);
    expect(find.textContaining(' left'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Show 10 min'), findsNothing);

    await tester.runAsync(viewModel.stopQuickShare);
    await tester.pump();

    expect(find.text('Show 10 min'), findsOneWidget);
    expect(viewModel.quickShareSecondsLeft, isNull);
  });

  testWidgets('an offer from a phone shows the PIN to compare', (tester) async {
    await start();
    await pumpCard(tester);
    await put(tester, _offer());

    expect(
      find.text('Pixel 8 (Quick Share) wants to send this'),
      findsOneWidget,
    );
    expect(
      find.text('PIN 0482. It must match the one on Pixel 8 (Quick Share).'),
      findsOneWidget,
    );
    expect(find.text('192.168.1.30'), findsOneWidget);
    expect(find.text('a.jpg, b.jpg'), findsOneWidget);
    expect(find.text('2 files · 2 MB'), findsOneWidget);
    expect(
      find.text(
        "Pixel 8 (Quick Share) isn't paired with Ferret. "
        'Accept only if you expect it.',
      ),
      findsOneWidget,
    );
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.textContaining('Fingerprint'), findsNothing);
  });

  testWidgets('once answered, the PIN goes away', (tester) async {
    await start();
    await pumpCard(tester);
    await put(tester, _offer(status: .transferring, needsAnswer: false));

    expect(find.textContaining('PIN'), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('failures say the phone has to send again, without Retry', (
    tester,
  ) async {
    await start();
    final viewModel = await pumpCard(tester);
    await put(
      tester,
      _offer(status: .failed, failure: .connectionLost, needsAnswer: false),
    );

    expect(
      find.text(
        'The connection to Pixel 8 (Quick Share) dropped. '
        'On Pixel 8 (Quick Share): send it again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsNothing);
    expect(viewModel.canRetry(link.laptop.feature.transfers.single), isFalse);

    final texts = TransferTexts(lookupDropLocalizations(const Locale('en')));
    expect(
      texts.failure(
        _offer(status: .failed, failure: .protocol, needsAnswer: false),
      ),
      'Something went wrong with Pixel 8 (Quick Share). '
      'On Pixel 8 (Quick Share): send it again.',
    );
    expect(
      texts.failure(sampleTransfer(status: .failed, failure: .protocol)),
      contains('Try again to continue'),
    );
  });

  testWidgets('settings can turn Quick Share off', (tester) async {
    await start();
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

    expect(find.text('Work with Quick Share'), findsOneWidget);
    expect(viewModel.quickShareEnabled, isTrue);

    await viewModel.setQuickShareEnabled(false);
    await tester.pump();
    await tester.pump();

    expect(viewModel.quickShareEnabled, isFalse);
    expect(
      link.laptop.settings.get<bool>(DropSettings.quickShareEnabled),
      isFalse,
    );
    expect(find.text('Work with Quick Share'), findsOneWidget);
  });

  test('the notice for an offer carries the PIN', () async {
    await start();
    final notifier = _RecordingNotifier();
    final notices = DropNotices(
      feature: link.laptop.feature,
      notifier: notifier,
      l10n: lookupDropLocalizations(const Locale('en')),
      onOpen: (_) async {},
      onReveal: (_) async {},
      onCopy: (_) async {},
    )..start();
    addTearDown(notices.dispose);

    link.laptop.feature.registry.put(_offer());
    await pumpEventQueue();

    final notice = notifier.shown.single;
    expect(notice.title, 'Pixel 8 (Quick Share) wants to send you something');
    expect(notice.body, '2 files · PIN 0482 · 2 MB');
    expect(notice.category, DropNotices.offerCategory);
  });
}

class _RecordingNotifier implements LocalNotifier {
  final List<LocalNotice> shown = [];

  @override
  Stream<NoticeResponse> get responses => const Stream.empty();

  @override
  Future<void> show(LocalNotice notice) async => shown.add(notice);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
