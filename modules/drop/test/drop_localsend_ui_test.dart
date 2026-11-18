import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:drop/drop.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interop_localsend/interop_localsend.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'support/files.dart';
import 'support/linked_devices.dart';
import 'support/test_app.dart';
import 'support/transfers.dart';

const _fingerprint =
    '3f2a91bc07de44a1000000000000000000000000000000000000000000000000';

Transfer _offer({List<TransferFile>? files}) => Transfer(
  id: 'ls1',
  direction: .incoming,
  deviceId: LocalSendIds.deviceId(_fingerprint),
  deviceName: LocalSendIds.label('Nice Orange'),
  files:
      files ??
      const [
        TransferFile(name: 'a.jpg', size: 1024 * 1024),
        TransferFile(name: 'b.jpg', size: 1024 * 1024),
        TransferFile(name: 'c.jpg', size: 1024 * 1024),
        TransferFile(name: 'd.jpg', size: 1024 * 1024),
      ],
  status: .waiting,
  startedAt: DateTime(2026, 11, 18),
  needsAnswer: true,
  localSend: const LocalSendOrigin(
    deviceModel: 'iPhone',
    fingerprint: _fingerprint,
    address: '192.168.1.20',
  ),
);

const _orange = LocalSendInfo(
  alias: 'Nice Orange',
  fingerprint: _fingerprint,
  deviceModel: 'iPhone',
  deviceType: .mobile,
  port: 53317,
  protocol: 'https',
);

void main() {
  late LocalSendIdentity identity;
  late LinkedDevices link;

  setUpAll(() async {
    identity = await LocalSendIdentity.generate();
  });

  Future<void> start({Map<String, Object?> settings = const {}}) async {
    final inbox = Directory.systemTemp.createTempSync('ferret_localsend_ui');
    addTearDown(() => inbox.deleteSync(recursive: true));
    final secrets = MemorySecretStore();
    await secrets.write('drop.localsend_identity', identity.encode());
    link = await LinkedDevices.start(
      laptopStore: folderStore(inbox),
      phoneStore: folderStore(inbox),
      laptopSettings: settings,
      laptopSecrets: secrets,
      localSend: const LocalSendOptions(
        useMulticast: false,
        scanAddresses: false,
        multicastWait: Duration.zero,
      ),
    );
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

  testWidgets('the card says receiving from LocalSend is off', (tester) async {
    await start();
    await pumpCard(tester);

    expect(find.text('Receive from LocalSend'), findsOneWidget);
    expect(
      find.text("Off. LocalSend devices can't send to this one."),
      findsOneWidget,
    );
    expect(find.text('On for 10 min'), findsOneWidget);
  });

  testWidgets('with LocalSend turned off the card does not mention it', (
    tester,
  ) async {
    await start(settings: {DropSettings.localSendEnabled: false});
    await pumpCard(tester);

    expect(find.text('Receive from LocalSend'), findsNothing);
    expect(find.text('Send files…'), findsOneWidget);
  });

  testWidgets('the row counts down, and shows a problem with a way out', (
    tester,
  ) async {
    var stopped = false;
    await tester.pumpWidget(
      testApp(
        Column(
          children: [
            ReceiveRow(
              title: 'Receive from LocalSend',
              status: 'Visible as Laptop · 9:41 left',
              actionLabel: 'Stop',
              onAction: () => stopped = true,
            ),
            ReceiveRow(
              title: 'Receive from LocalSend',
              status: 'Couldn\'t start.',
              actionLabel: 'Try again',
              hasProblem: true,
              onAction: () {},
            ),
            const ReceiveRow(
              title: 'Receive from LocalSend',
              status: 'Turning on…',
              actionLabel: '',
              onAction: null,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Visible as Laptop · 9:41 left'), findsOneWidget);
    await tester.tap(find.text('Stop'));
    expect(stopped, isTrue);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(Button), findsNWidgets(2));
  });

  testWidgets('an offer from LocalSend says who, what and how much', (
    tester,
  ) async {
    await start();
    await pumpCard(tester);
    await put(tester, _offer());

    expect(
      find.text('Nice Orange (LocalSend) wants to send this'),
      findsOneWidget,
    );
    expect(find.text('iPhone · 192.168.1.20'), findsOneWidget);
    expect(find.text('Fingerprint 3F2A 91BC 07DE 44A1'), findsOneWidget);
    expect(find.text('a.jpg, b.jpg, c.jpg and 1 more'), findsOneWidget);
    expect(find.text('4 files · 4 MB'), findsOneWidget);
    expect(
      find.text(
        "This device isn't paired with Ferret. Accept only if you expect it.",
      ),
      findsOneWidget,
    );
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('offers from paired devices stay short', (tester) async {
    await start();
    await pumpCard(tester);
    await put(tester, sampleTransfer(status: .waiting, needsAnswer: true));

    expect(find.textContaining('Fingerprint'), findsNothing);
    expect(find.textContaining("isn't paired"), findsNothing);
  });

  testWidgets('LocalSend failures say what to do', (tester) async {
    await start();
    await pumpCard(tester);
    final texts = TransferTexts(lookupDropLocalizations(const Locale('en')));
    Transfer failed(TransferFailure failure) => Transfer(
      id: 'out',
      direction: .outgoing,
      deviceId: LocalSendIds.deviceId(_fingerprint),
      deviceName: LocalSendIds.label('Nice Orange'),
      files: const [TransferFile(name: 'a.jpg', size: 10)],
      status: .failed,
      failure: failure,
      startedAt: DateTime(2026, 11, 18),
    );

    await put(tester, failed(.pinRequired));
    expect(
      find.text(
        'Nice Orange (LocalSend) asks for a PIN. Enter the one it shows.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsNothing);

    expect(
      texts.failure(failed(.busy)),
      contains('busy with another transfer'),
    );
    expect(
      texts.failure(failed(.unreachable)),
      contains('Keep LocalSend open'),
    );
    expect(texts.failure(failed(.untrusted)), contains('Nothing was sent'));
    expect(texts.failure(failed(.tooManyAttempts)), contains('wrong PINs'));
    expect(texts.countdown(const Duration(seconds: 581)), '9:41');
    expect(texts.countdown(const Duration(seconds: 5)), '0:05');
  });

  testWidgets('settings can turn LocalSend off, or keep receiving on', (
    tester,
  ) async {
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

    expect(find.text('Work with LocalSend'), findsOneWidget);
    expect(find.text('Always receive from LocalSend'), findsOneWidget);
    expect(viewModel.localSendEnabled, isTrue);
    expect(viewModel.receiveAlways, isFalse);

    await viewModel.setLocalSendEnabled(false);
    await tester.pump();
    await tester.pump();

    expect(find.text('Always receive from LocalSend'), findsNothing);
    expect(
      link.laptop.settings.get<bool>(DropSettings.localSendEnabled),
      isFalse,
    );
    expect(viewModel.canSend, isTrue);
  });

  group('the device picker', () {
    final picked = <DropTarget?>[];

    setUp(picked.clear);

    Future<void> openPicker(
      WidgetTester tester,
      DropViewModel viewModel,
    ) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFFFFFFFF),
          localizationsDelegates: const [
            DropLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: DropLocalizations.supportedLocales,
          builder: (context, _) => FluffyTheme(
            data: FluffyThemeData.fallback(),
            child: DefaultTextStyle(
              style: const TextStyle(),
              child: Navigator(
                onGenerateRoute: (_) => PageRouteBuilder<void>(
                  pageBuilder: (context, _, _) => Center(
                    child: Tappable(
                      onTap: () async => picked.add(
                        await DevicePickerDialog.show(context, viewModel),
                      ),
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('looks for LocalSend devices and explains when none answer', (
      tester,
    ) async {
      await start();
      final viewModel = newViewModel();
      await openPicker(tester, viewModel);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Send to which device?'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(
        find.text(
          'No LocalSend devices found. Open LocalSend on the other device, '
          'on the same Wi-Fi.',
        ),
        findsOneWidget,
      );
      expect(find.text('Search again'), findsOneWidget);
    });

    testWidgets('lists LocalSend devices next to paired ones, labelled', (
      tester,
    ) async {
      await start();
      final viewModel = newViewModel();
      link.laptop.feature.localSend.remember(
        _orange,
        InternetAddress('192.168.1.20'),
      );
      await openPicker(tester, viewModel);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Nice Orange'), findsOneWidget);
      expect(find.text('LocalSend · iPhone'), findsOneWidget);
      expect(find.textContaining('No LocalSend devices'), findsNothing);

      await tester.tap(find.text('Nice Orange'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(picked.single?.isLocalSend, isTrue);
      expect(find.text('Send to which device?'), findsNothing);

      final target = viewModel.localSendTargets.single;
      expect(target.isLocalSend, isTrue);
      expect(target.deviceId, LocalSendIds.deviceId(_fingerprint));
      expect(viewModel.isGone(target), isFalse);
    });
  });

  group('health', () {
    DeviceStatus status({bool connected = true}) => DeviceStatus(
      TrustedDevice(
        id: 'phone-id',
        name: 'Pixel',
        platform: .PLATFORM_ANDROID,
        formFactor: .FORM_FACTOR_PHONE,
        publicKey: Uint8List(0),
        pairedAt: DateTime(2026),
      ),
      switch (connected) {
        true => link.laptop.session,
        false => null,
      },
    );

    testWidgets('follows the last transfer, not just the connection', (
      tester,
    ) async {
      await start();
      final ui = DropFeatureUi(feature: link.laptop.feature);

      expect(ui.healthOf(status(connected: false)), isNull);
      expect(ui.healthOf(status())?.state, FeatureHealthState.ok);

      link.laptop.feature.registry.put(
        sampleTransfer(status: .failed, failure: .storage),
      );
      final failing = ui.healthOf(status());
      expect(failing?.state, FeatureHealthState.failing);
      expect(failing?.reason, contains("Couldn't write the file"));
    });

    testWidgets('someone saying no is not a failure', (tester) async {
      await start();
      final ui = DropFeatureUi(feature: link.laptop.feature);
      link.laptop.feature.registry.put(
        sampleTransfer(
          direction: .outgoing,
          status: .failed,
          failure: .declined,
        ),
      );

      expect(ui.healthOf(status())?.state, FeatureHealthState.ok);
    });

    testWidgets('a finished transfer makes it healthy again', (tester) async {
      await start();
      final ui = DropFeatureUi(feature: link.laptop.feature);
      link.laptop.feature.registry.put(
        sampleTransfer(status: .done, bytesDone: 4 * 1024 * 1024),
      );

      final health = ui.healthOf(status());
      expect(health?.state, FeatureHealthState.ok);
      expect(health?.reason, 'The last transfer went through.');
    });

    testWidgets('a transfer refreshes the card and the health chip', (
      tester,
    ) async {
      await start();
      final ui = DropFeatureUi(feature: link.laptop.feature);
      var changes = 0;
      ui.uiChanges.addListener(() => changes++);

      link.laptop.feature.registry.put(sampleTransfer(status: .failed));
      await tester.pump();

      expect(changes, greaterThan(0));
    });
  });
}
