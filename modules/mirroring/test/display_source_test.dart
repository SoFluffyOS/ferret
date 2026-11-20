import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart' as remote;
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';
import 'package:protocol/remote_input.dart' as wire;

import 'helpers/fakes.dart';

void main() {
  late FakeHost host;
  late FakeSession air;
  late FakeDisplayCapture capture;
  late FakeInjector injector;
  late DisplaySource source;
  late DateTime now;

  StartRequest yes({DisplayPanel? panel}) => StartRequest(
    version: 1,
    codecs: const [.CODEC_H264],
    maxWidth: 2560,
    maxHeight: 1664,
    maxFps: 60,
    source: .SOURCE_DISPLAY,
    display:
        panel ??
        DisplayPanel(width: 2560, height: 1664, scale: 2, refreshHz: 120),
  );

  Future<void> create({
    FakeDisplayCapture? mac,
    GeneratedMessage Function(GeneratedMessage request)? answer,
  }) async {
    host = await FakeHost.create();
    air = FakeSession(
      'air',
      name: 'MacBook Air',
      flags: const [MirrorProtocol.displayFlag, MirroringFeature.viewFlag],
      answer: answer ?? (_) => StartPending(timeoutSeconds: 30),
    );
    host.sessions = [air];
    capture = mac ?? FakeDisplayCapture();
    injector = FakeInjector();
    now = DateTime(2026, 11, 20, 14, 0);
    source = DisplaySource(
      host: host,
      featureId: MirroringFeature.featureId,
      capture: capture,
      injector: injector,
      clock: () => now,
    );
    await source.start();
  }

  Future<void> extend() async {
    await source.offer('air');
    await source.onRequest(air, yes());
    await settle();
  }

  setUp(create);

  tearDown(() => source.dispose());

  test('an offer asks the other Mac and waits for its owner', () async {
    await source.offer('air');

    expect(air.requests.single, isA<DisplayOffer>());
    expect(source.current?.phase, ExtendPhase.asking);
    expect(source.current?.deviceName, 'MacBook Air');
    expect(
      source.current?.answerBy,
      now.add(const Duration(seconds: 35)),
      reason: 'its own 30 seconds and a margin',
    );
    expect(capture.started, isEmpty, reason: 'nothing before the yes');
  });

  test('only a device that says it can be a display is offered one', () async {
    host.sessions = [
      FakeSession('pixel', flags: const [MirroringFeature.shareFlag]),
    ];

    await source.offer('pixel');

    expect(source.current, isNull);
    expect(source.lastRecord?.end, ExtendEnd.unsupported);
  });

  test(
    'Screen Recording is asked for first, and a no says what to do',
    () async {
      await create(
        mac: FakeDisplayCapture(
          supportNow: const DisplaySupport(
            canExtend: true,
            screenRecordingGranted: false,
            inputGranted: true,
          ),
        ),
      );

      await source.offer('air');

      expect(capture.screenRecordingAsks, 1);
      expect(air.requests, isEmpty, reason: 'nothing is offered without it');
      expect(source.lastRecord?.end, ExtendEnd.needsScreenRecording);

      await source.openScreenRecordingSettings();

      expect(capture.settingsOpened, 1);
    },
  );

  test("a Mac that can't make a display says so and offers nothing", () async {
    await create(mac: FakeDisplayCapture(supportNow: const .none()));

    await source.offer('air');

    expect(air.requests, isEmpty);
    expect(source.lastRecord?.end, ExtendEnd.cannotExtend);
  });

  test('a no from the other owner ends the offer', () async {
    await source.offer('air');

    source.onDecline(air, DisplayDecline(reason: .DENY_REASON_DENIED));

    expect(source.current, isNull);
    expect(source.lastRecord?.end, ExtendEnd.declined);
  });

  test('a busy device turns the offer down at once', () async {
    await create(answer: (_) => StartDeny(reason: .DENY_REASON_BUSY));

    await source.offer('air');

    expect(source.current, isNull);
    expect(source.lastRecord?.end, ExtendEnd.busy);
  });

  test('a device that was never offered a display is turned away', () async {
    final reply = await source.onRequest(air, yes());

    expect((reply as StartDeny).reason, DenyReason.DENY_REASON_DENIED);
    expect(capture.started, isEmpty);
  });

  test('the yes makes a display the size of its screen, says so, and lets '
      'it click and type', () async {
    await source.offer('air');
    final reply = await source.onRequest(air, yes());
    await settle();

    expect(reply, isA<StartPending>());
    final options = capture.started.single;
    expect(options.width, 2560);
    expect(options.height, 1664);
    expect(options.scale, 2);
    expect(options.refreshHz, 120);
    expect(options.name, 'MacBook Air');
    expect(options.serial, DisplaySource.serialOf('air'));
    expect(source.current?.phase, ExtendPhase.extending);
    expect(source.current?.startedAt, now);
    expect(air.sentOf<StartAccept>().single.codec, Codec.CODEC_H264);
    final control = air.sentOf<ControlState>().single;
    expect(control.status, ControlStatus.CONTROL_STATUS_ALLOWED);
    expect(control.kinds, contains(ControlKind.CONTROL_KIND_MOUSE));
  });

  test('without Accessibility the picture goes, and the pointer waits for '
      'setup', () async {
    await create(
      mac: FakeDisplayCapture(
        supportNow: const DisplaySupport(
          canExtend: true,
          screenRecordingGranted: true,
          inputGranted: false,
        ),
      ),
    );

    await extend();

    expect(capture.inputAsks, 1, reason: 'asked once, with the offer');
    expect(
      air.sentOf<ControlState>().single.status,
      ControlStatus.CONTROL_STATUS_NEEDS_SETUP,
    );

    await source.onInput(
      'air',
      ControlInput(
        events: [
          ControlEvent(
            pointer: PointerInput(phase: .TOUCH_PHASE_DOWN, x: 0.5, y: 0.5),
          ),
        ],
      ),
    );

    expect(capture.pointers, isEmpty);
  });

  test('the display goes out as a stream config and frames', () async {
    await extend();

    capture.play();
    await settle();

    final config = air.sentOf<StreamConfig>().single;
    expect(config.width, 2560);
    expect(config.height, 1664);
    expect(config.sps, [0x67, 0x64]);
    final frame = air.sentOf<Frame>().single;
    expect(frame.keyframe, isTrue);
    expect(frame.configId, config.configId);
  });

  test(
    'the pointer lands on the display, keys and text go to this Mac',
    () async {
      await extend();

      await source.onInput(
        'air',
        ControlInput(
          events: [
            ControlEvent(
              pointer: PointerInput(
                phase: .TOUCH_PHASE_HOVER,
                x: 0.25,
                y: 0.75,
              ),
            ),
            ControlEvent(
              pointer: PointerInput(
                phase: .TOUCH_PHASE_DOWN,
                x: 0.25,
                y: 0.75,
                button: .MOUSE_BUTTON_RIGHT,
              ),
            ),
            ControlEvent(
              pointer: PointerInput(
                phase: .TOUCH_PHASE_SCROLL,
                x: 0.5,
                y: 0.5,
                scrollY: 2,
              ),
            ),
            ControlEvent(
              key: wire.KeyEvent(
                key: .KEY_C,
                pressed: true,
                modifiers: const [.MODIFIER_META],
              ),
            ),
            ControlEvent(text: wire.TextInput(text: 'héllo')),
          ],
        ),
      );

      expect(capture.pointers.map((pointer) => pointer.phase), [
        PointerPhase.hover,
        PointerPhase.down,
        PointerPhase.scroll,
      ]);
      expect(capture.pointers.first.x, 0.25);
      expect(capture.pointers.first.y, 0.75);
      expect(capture.pointers[1].buttons, 2, reason: 'the secondary button');
      expect(capture.pointers.last.scrollY, 100, reason: 'two notches');
      final key = injector.injected.first as remote.KeyAction;
      expect(key.key, remote.InputKey.c);
      expect(key.modifiers, {remote.KeyModifier.meta});
      expect((injector.injected.last as remote.TextAction).text, 'héllo');
    },
  );

  test('another device gets no say over the display', () async {
    await extend();

    await source.onInput(
      'pixel',
      ControlInput(
        events: [
          ControlEvent(
            pointer: PointerInput(phase: .TOUCH_PHASE_DOWN, x: 0.5, y: 0.5),
          ),
        ],
      ),
    );

    expect(capture.pointers, isEmpty);
  });

  test('Stop here takes the display away and tells the other Mac', () async {
    await extend();

    await source.stop();

    expect(capture.stops, 1);
    expect(
      air.sentOf<Stop>().single.reason,
      StopReason.STOP_REASON_STOPPED_ON_SOURCE,
    );
    expect(source.current, isNull);
    expect(source.lastRecord?.end, ExtendEnd.stoppedHere);
    expect(source.lastRecord?.startedAt, now);
  });

  test('Stop there takes the display away too', () async {
    await extend();

    await source.onStop(air);

    expect(capture.stops, 1);
    expect(air.sentOf<Stop>(), isEmpty);
    expect(source.lastRecord?.end, ExtendEnd.stoppedThere);
  });

  test('a dropped connection never leaves the display behind', () async {
    await extend();

    await source.onSessionClosed('air');

    expect(capture.stops, 1);
    expect(source.lastRecord?.end, ExtendEnd.lostConnection);
  });

  test('cancelling the offer takes it back on the other Mac', () async {
    await source.offer('air');

    await source.stop();

    expect(
      air.sentOf<Stop>().single.reason,
      StopReason.STOP_REASON_STOPPED_ON_SOURCE,
    );
    expect(source.current, isNull);
    expect(capture.stops, 0, reason: 'there was no display yet');
  });

  test('a display that failed to start says no to the other Mac', () async {
    await create(mac: FakeDisplayCapture(startSucceeds: false));

    await extend();

    expect(
      air.sentOf<StartDeny>().single.reason,
      DenyReason.DENY_REASON_FAILED,
    );
    expect(source.lastRecord?.end, ExtendEnd.failed);
  });

  test('the capture ending on this Mac ends the display there', () async {
    await extend();

    capture.emit(const CaptureEnded(.endedBySystem));
    await settle();

    expect(
      air.sentOf<Stop>().single.reason,
      StopReason.STOP_REASON_SYSTEM_ENDED,
    );
    expect(source.lastRecord?.end, ExtendEnd.systemEnded);
  });

  test('a device keeps the same display serial', () {
    expect(DisplaySource.serialOf('air'), DisplaySource.serialOf('air'));
    expect(
      DisplaySource.serialOf('air'),
      isNot(DisplaySource.serialOf('pro')),
    );
    expect(DisplaySource.serialOf('air'), greaterThan(0));
  });
}
