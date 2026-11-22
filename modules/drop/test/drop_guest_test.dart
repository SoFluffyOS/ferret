import 'dart:io';

import 'package:drop/drop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interop_localsend/interop_localsend.dart';

import 'support/files.dart';
import 'support/localsend_devices.dart';

void main() {
  late LocalSendIdentity laptopIdentity;
  late LocalSendIdentity phoneIdentity;
  late Directory inbox;
  late Directory outbox;
  late SoloDevice laptop;
  late SoloDevice phone;
  late DropViewModel viewModel;

  setUpAll(() async {
    laptopIdentity = await LocalSendIdentity.generate();
    phoneIdentity = await LocalSendIdentity.generate();
  });

  setUp(() async {
    inbox = await Directory.systemTemp.createTemp('ferret_guest_in');
    outbox = await Directory.systemTemp.createTemp('ferret_guest_out');
    laptop = await SoloDevice.start(
      'Family PC',
      inbox,
      identity: laptopIdentity,
      settings: const {DropSettings.quickShareEnabled: false},
    );
    phone = await SoloDevice.start('Guest', outbox, identity: phoneIdentity);
    viewModel = DropViewModel(
      feature: laptop.feature,
      describeFolder: () async => inbox.path,
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await phone.feature.stop();
    await laptop.feature.stop();
    await inbox.delete(recursive: true);
    await outbox.delete(recursive: true);
  });

  Future<void> guestSends() async {
    final found = await phone.localSend.findAt(
      InternetAddress.loopbackIPv4,
      port: laptop.localSend.receiveState.port,
    );
    expect(found, isTrue);

    phone.localSend.sendText(
      LocalSendIds.deviceId(laptopIdentity.fingerprint),
      'Wi-Fi photos',
    );
    await until(() => laptop.transfers.firstOrNull?.needsAnswer ?? false);
    laptop.feature.answer(laptop.transfers.first.id, accept: true);
    await until(() => laptop.transfers.first.status == .done);
  }

  test('a guest can send once, then this computer closes again', () async {
    await viewModel.receiveFromGuest();
    expect(viewModel.isGuestOnce, isTrue);
    expect(laptop.localSend.receiveState.isOn, isTrue);

    await guestSends();

    await until(() => !laptop.localSend.receiveState.isOn);
    expect(viewModel.isGuestOnce, isFalse);
    expect(viewModel.isOpenToOthers, isFalse);
  });

  test('the usual window stays open after a file', () async {
    await viewModel.openToOthers();

    await guestSends();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(viewModel.isGuestOnce, isFalse);
    expect(laptop.localSend.receiveState.isOn, isTrue);
  });

  test(
    'a guest window closed without a file leaves the next one usual',
    () async {
      await viewModel.receiveFromGuest();
      expect(viewModel.isGuestOnce, isTrue);
      await viewModel.stopReceiving();
      await until(() => !viewModel.isOpenToOthers);

      await viewModel.openToOthers();
      await until(() => laptop.localSend.receiveState.isOn);
      expect(viewModel.isGuestOnce, isFalse);

      await guestSends();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(laptop.localSend.receiveState.isOn, isTrue);
    },
  );
}
