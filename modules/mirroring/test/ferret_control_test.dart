import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:ferret_phone_control/ferret_phone_control.dart';
import 'package:ferret_phone_control/testing.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:ferret_power/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protocol/mirroring.dart';
import 'package:protocol/remote_input.dart' as input;

import 'helpers/fakes.dart';

/// Control over Ferret's own route: the phone asks its owner, picks the
/// way in, and only carries out what an allowed computer sends while it
/// sees the screen. The computer turns the answers into its toolbar.
void main() {
  group('the phone', () {
    late FakeHost host;
    late FakeSession mac;
    late FakeCapture capture;
    late FakePowerPlatform power;
    late PowerCapabilities capabilities;
    late FakeControlService service;
    late MirrorSource source;
    late SourceControl control;

    Future<void> create({
      bool serviceOn = true,
      bool shizuku = false,
      Map<String, Object?>? settings,
      Duration askTimeout = const Duration(seconds: 60),
    }) async {
      host = await FakeHost.create(settings: settings);
      mac = FakeSession('mac', name: 'MacBook', flags: const ['view']);
      host.sessions = [mac];
      capture = FakeCapture();
      power = FakePowerPlatform(
        status: PowerStatus(
          supported: true,
          shizuku: switch (shizuku) {
            true => .ready,
            false => .notInstalled,
          },
        ),
      );
      capabilities = PowerCapabilities.withPlatform(power);
      await capabilities.configure(shizuku: shizuku, root: false);
      service = FakeControlService(enabled: serviceOn);
      source = MirrorSource(
        host: host,
        featureId: MirroringFeature.featureId,
        capture: capture,
        phoneControl: PhoneControl(
          power: capabilities,
          service: service,
          supported: true,
        ),
        settings: MirroringSettings(host.settings),
        texts: textsFor,
        consentTimeout: askTimeout,
      );
      await source.start();
      final sourceControl = source.control;
      if (sourceControl == null) {
        fail('A phone that can be controlled has control');
      }

      control = sourceControl;
    }

    Future<void> share() async {
      await source.onRequest(
        mac,
        StartRequest(version: 1, codecs: const [.CODEC_H264]),
      );
      await settle();
      capture.answer(.granted);
      await settle();
    }

    ControlStatus lastStatus() => mac.sentOf<ControlState>().last.status;

    ControlInput tap(double x, double y) => ControlInput(
      events: [
        for (final phase in <TouchPhase>[.TOUCH_PHASE_DOWN, .TOUCH_PHASE_UP])
          ControlEvent(
            pointer: PointerInput(phase: phase, x: x, y: y),
          ),
      ],
    );

    tearDown(() async {
      await source.dispose();
      await capabilities.dispose();
    });

    test('says right after the yes that the computer may ask', () async {
      await create();

      await share();

      final state = mac.sentOf<ControlState>().single;
      expect(state.status, ControlStatus.CONTROL_STATUS_CAN_ASK);
      expect(state.kinds, contains(ControlKind.CONTROL_KIND_POINTER));
      expect(state.buttons, contains(ControlButton.CONTROL_BUTTON_BACK));
    });

    test('without Ferret control or power-ups it needs setting up, and '
        'turning the service on tells the computer at once', () async {
      await create(serviceOn: false);
      await share();
      expect(lastStatus(), ControlStatus.CONTROL_STATUS_NEEDS_SETUP);

      await control.onAsk('mac');
      expect(control.pending, isNull, reason: 'nothing to ask about yet');

      service.turn(on: true);
      await settle();

      expect(lastStatus(), ControlStatus.CONTROL_STATUS_CAN_ASK);
    });

    test('asks its owner, and Once lets the taps through', () async {
      await create();
      await share();

      await control.onAsk('mac');
      expect(lastStatus(), ControlStatus.CONTROL_STATUS_ASKING);
      expect(mac.sentOf<ControlState>().last.timeoutSeconds, 60);
      expect(control.pending?.deviceName, 'MacBook');

      control.onInput('mac', tap(0.5, 0.5));
      await settle();
      expect(service.done, isEmpty, reason: 'no taps before the yes');

      await control.answer(.once);
      expect(lastStatus(), ControlStatus.CONTROL_STATUS_ALLOWED);
      expect(control.controller?.deviceName, 'MacBook');
      expect(service.armed, isTrue);

      control.onInput('mac', tap(0.5, 0.5));
      await settle();
      expect(service.done, ['touch:down', 'touch:up']);
      expect(MirroringSettings(host.settings).controlAlways, isEmpty);
    });

    test('Always skips the question next time', () async {
      await create();
      await share();
      await control.onAsk('mac');
      await control.answer(.always);
      await source.stop();
      await settle();

      await share();
      await control.onAsk('mac');

      expect(control.pending, isNull);
      expect(lastStatus(), ControlStatus.CONTROL_STATUS_ALLOWED);
    });

    test('No keeps the computer watching only', () async {
      await create();
      await share();
      await control.onAsk('mac');

      await control.answer(.no);
      control.onInput('mac', tap(0.2, 0.2));
      await settle();

      expect(lastStatus(), ControlStatus.CONTROL_STATUS_DENIED);
      expect(service.armed, isFalse);
      expect(service.done, isEmpty);
    });

    test('a question nobody answers times out', () async {
      await create(askTimeout: const Duration(milliseconds: 50));
      await share();
      await control.onAsk('mac');

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(control.pending, isNull);
      expect(lastStatus(), ControlStatus.CONTROL_STATUS_TIMED_OUT);
    });

    test('Stop on the phone ends control, the picture goes on', () async {
      await create();
      await share();
      await control.onAsk('mac');
      await control.answer(.once);

      await control.stop();
      control.onInput('mac', tap(0.5, 0.5));
      await settle();

      expect(lastStatus(), ControlStatus.CONTROL_STATUS_STOPPED);
      expect(service.armed, isFalse);
      expect(service.done, isEmpty);
      expect(source.active, isNotNull);
    });

    test('control ends with the picture', () async {
      await create();
      await share();
      await control.onAsk('mac');
      await control.answer(.once);

      await source.stop();
      await settle();

      expect(control.controller, isNull);
      expect(service.armed, isFalse);
    });

    test('only the computer that sees the screen can ask or send', () async {
      await create();
      await share();
      await control.onAsk('mac');
      await control.answer(.once);

      control.onInput('other', tap(0.5, 0.5));
      await control.onAsk('other');
      await settle();

      expect(service.done, isEmpty);
      expect(control.controller?.deviceId, 'mac');
    });

    test('one batch carries out at most 512 events', () async {
      await create();
      await share();
      await control.onAsk('mac');
      await control.answer(.once);

      control.onInput(
        'mac',
        ControlInput(
          events: [
            for (var index = 0; index < 600; index++)
              ControlEvent(
                button: ButtonPress(button: .CONTROL_BUTTON_BACK),
              ),
          ],
        ),
      );
      await settle();

      expect(service.done, hasLength(SourceControl.maxEventsPerBatch));
    });

    test('power-ups come first, and keys keep their shortcuts', () async {
      await create(shizuku: true);
      await share();
      await control.onAsk('mac');
      await control.answer(.once);

      control.onInput(
        'mac',
        ControlInput(
          events: [
            ControlEvent(
              key: input.KeyEvent(
                key: .KEY_C,
                pressed: true,
                modifiers: const [.MODIFIER_CONTROL],
              ),
            ),
            ControlEvent(
              pointer: PointerInput(
                phase: .TOUCH_PHASE_SCROLL,
                x: 0.5,
                y: 2,
                scrollY: 1,
              ),
            ),
            ControlEvent(text: input.TextInput(text: 'hi')),
          ],
        ),
      );
      await settle();

      expect(service.armed, isFalse);
      expect(power.injected, [
        const PowerKey(
          AndroidKeys.c,
          down: true,
          metaState: AndroidKeys.metaCtrl,
        ),
        const PowerScroll(0.5, 1, vertical: -1),
        const PowerText('hi'),
      ]);
    });
  });

  group('the computer', () {
    late FakeHost host;
    late FakeSession pixel;
    late FerretRoute route;
    late MirrorRoutes routes;
    late MirrorViewer viewer;

    setUp(() async {
      host = await FakeHost.create();
      pixel = FakeSession(
        'pixel',
        answer: (_) => StartPending(timeoutSeconds: 60),
      );
      host.sessions = [pixel];
      final settings = MirroringSettings(host.settings);
      route = FerretRoute(host: host, featureId: MirroringFeature.featureId);
      routes = MirrorRoutes(
        ferret: route,
        settings: settings,
        receiverName: () => 'MacBook',
      );
      viewer = MirrorViewer(
        routes: routes,
        createDecoder: FakeDecoder.new,
        codecs: const [.h264],
        settings: settings,
      );
    });

    tearDown(() async {
      await viewer.dispose();
      await routes.dispose();
    });

    Future<void> stream() async {
      await viewer.show('pixel');
      route.onAccept(pixel, StartAccept(version: 1, codec: .CODEC_H264));
      await settle();
    }

    ControlState allowed() => ControlState(
      status: .CONTROL_STATUS_ALLOWED,
      kinds: const [
        .CONTROL_KIND_POINTER,
        .CONTROL_KIND_KEYS,
        .CONTROL_KIND_TEXT,
        .CONTROL_KIND_BUTTONS,
      ],
      buttons: const [.CONTROL_BUTTON_BACK, .CONTROL_BUTTON_HOME],
    );

    test('an older phone that never says is view only', () async {
      await stream();

      expect(viewer.current?.control, isNull);
      expect(viewer.control, isNull);
    });

    test('asks, and gets clicks and keys once the phone says yes', () async {
      await stream();
      route.onControlState(
        pixel,
        ControlState(status: .CONTROL_STATUS_CAN_ASK),
      );
      expect(viewer.current?.control, ControlAccess.canAsk);
      expect(viewer.control, isNull);

      await viewer.askControl();
      expect(pixel.sentOf<ControlAsk>(), hasLength(1));

      route.onControlState(pixel, allowed());
      expect(viewer.current?.control, ControlAccess.allowed);
      expect(viewer.control?.abilities, {
        ControlAbility.pointer,
        ControlAbility.keys,
        ControlAbility.text,
        ControlAbility.buttons,
      });
    });

    test('what happens in one go leaves as one batch', () async {
      await stream();
      route.onControlState(pixel, allowed());
      final control = viewer.control;
      if (control == null) {
        fail('Control should be allowed');
      }

      control
        ..pointer(const MirrorPointer(phase: .down, x: 0.1, y: 0.2))
        ..pointer(const MirrorPointer(phase: .up, x: 0.1, y: 0.2))
        ..key(const MirrorKey(phase: .down, usage: 0x06, modifiers: {.control}))
        ..press(.home)
        ..press(.rotate);
      await settle();

      final batch = pixel.sentOf<ControlInput>().single;
      expect(batch.events, hasLength(4));
      expect(batch.events[0].pointer.phase, TouchPhase.TOUCH_PHASE_DOWN);
      expect(batch.events[2].key.key, input.Key.KEY_C);
      expect(batch.events[2].key.modifiers, [input.Modifier.MODIFIER_CONTROL]);
      expect(batch.events[3].button.button, ControlButton.CONTROL_BUTTON_HOME);
    });

    test('a no, or Stop on the phone, takes control away', () async {
      await stream();
      route.onControlState(pixel, allowed());

      route.onControlState(
        pixel,
        ControlState(status: .CONTROL_STATUS_STOPPED),
      );

      expect(viewer.control, isNull);
      expect(viewer.current?.control?.canAskNow, isTrue);
    });

    test('keys the phone has no use for stay here', () {
      expect(FerretControl.keyOf(0x04), input.Key.KEY_A);
      expect(FerretControl.keyOf(0x27), input.Key.KEY_DIGIT_0);
      expect(FerretControl.keyOf(0x3A), input.Key.KEY_F1);
      expect(FerretControl.keyOf(0x52), input.Key.KEY_ARROW_UP);
      expect(FerretControl.keyOf(0x39), isNull);
    });
  });
}
