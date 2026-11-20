import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/remote_input.dart';
import 'package:remote_input/remote_input.dart';

import 'helpers/fakes.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = RemoteInputFeatureUi();

    expect(ui.featureId, RemoteInputFeature.featureId);
    expect(ui.feature.id, RemoteInputFeature.featureId);
  });

  test('a computer offers control, a phone offers to be a touchpad', () {
    final computer = RemoteInputFeature(
      locker: const UnsupportedScreenLocker(),
      canBeControlled: true,
      canControl: false,
      canSwitchScreens: false,
    );
    final mac = RemoteInputFeature(
      locker: const UnsupportedScreenLocker(),
      canBeControlled: true,
      canControl: false,
      canSwitchScreens: true,
    );
    final phone = RemoteInputFeature(canBeControlled: false, canControl: true);

    expect(computer.flags, [
      RemoteInputFeature.controlFlag,
      RemoteInputFeature.screenFlag,
    ]);
    expect(mac.flags, [
      RemoteInputFeature.controlFlag,
      RemoteInputFeature.screenFlag,
      RemoteInputFeature.screenSenderFlag,
    ]);
    expect(phone.flags, [RemoteInputFeature.controllerFlag]);
  });

  test('a phone only offers the touchpad for devices that can be '
      'controlled', () async {
    final phone = RemoteInputFeature(canBeControlled: false, canControl: true);
    await phone.start(await FakeHost.create());

    expect(phone.canControlDevice(FakeSession('mac')), isTrue);
    expect(phone.canControlDevice(FakeSession('tablet', flags: [])), isFalse);
    expect(
      phone.canControlDevice(FakeSession('old', supported: false)),
      isFalse,
    );
    await phone.stop();
  });

  test('a device that is not a computer turns requests down', () async {
    final phone = RemoteInputFeature(canBeControlled: false, canControl: true);
    await phone.start(await FakeHost.create());

    final reply = await phone.onEnvelope(
      FakeSession('mac'),
      envelopeOf(ControlRequest(version: 1), expectsReply: true),
    );

    expect(
      (reply as ControlDeny?)?.reason,
      DenyReason.DENY_REASON_UNSUPPORTED,
    );
    await phone.stop();
  });

  test('envelopes reach the computer side', () async {
    final injector = FakeInjector();
    final computer = RemoteInputFeature(
      injector: () => injector,
      canBeControlled: true,
      canControl: false,
    );
    final host = await FakeHost.create();
    final pixel = FakeSession('pixel');
    host.sessions = [pixel];
    await computer.start(host);

    final reply = await computer.onEnvelope(
      pixel,
      envelopeOf(ControlRequest(version: 1), expectsReply: true),
    );
    expect(reply, isA<ControlPending>());
    await computer.controlHost?.answer(.allowOnce);

    await computer.onEnvelope(
      pixel,
      envelopeOf(InputBatch(events: [InputCodec.move(1, 2)])),
    );
    expect(injector.injected, hasLength(1));

    await computer.onEnvelope(pixel, envelopeOf(ControlStop()));
    expect(computer.controlHost?.active, isNull);

    await computer.stop();
    expect(injector.disposed, isTrue);
  });
}
