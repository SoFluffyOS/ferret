import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';

import 'helpers/fakes.dart';
import 'helpers/memory_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryDiscoveryBus bus;
  final engines = <FerretEngine>[];

  setUp(() => bus = MemoryDiscoveryBus());

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
  });

  Future<FerretEngine> startEngine(
    String name,
    MirroringFeature feature,
  ) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_MACOS,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      features: [feature],
      discovery: bus.join(),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  Future<void> until(bool Function() condition) async {
    for (var attempt = 0; attempt < 300; attempt++) {
      if (condition()) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    fail('Timed out waiting');
  }

  Future<String> pair(FerretEngine one, FerretEngine other) async {
    final handle = await one.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    if (offer == null) {
      fail('The pairing offer should parse');
    }

    offer
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await other.pairWithOffer(offer), isA<Paired>());
    await until(() => one.sessions.isNotEmpty && other.sessions.isNotEmpty);
    return one.sessions.single.remoteDeviceId;
  }

  /// The Mac that lends its desktop, and the one that becomes its display.
  Future<
    ({
      MirroringFeature pro,
      MirroringFeature air,
      FakeDisplayCapture capture,
      FakeInjector injector,
      FakeDecoder decoder,
      String airId,
    })
  >
  twoMacs({Duration hiddenDisplayLimit = const Duration(minutes: 10)}) async {
    final capture = FakeDisplayCapture();
    final injector = FakeInjector();
    final decoder = FakeDecoder();
    final pro = MirroringFeature(
      display: () => capture,
      injector: () => injector,
      decoder: FakeDecoder.new,
      codecs: const [.h264],
      canShare: false,
      canView: true,
      canExtend: true,
      canBeDisplay: false,
    );
    final air = MirroringFeature(
      display: () => FakeDisplayCapture(
        screenNow: const ScreenPanel(
          width: 2940,
          height: 1912,
          scale: 2,
          refreshHz: 120,
        ),
      ),
      decoder: () => decoder,
      codecs: const [.h264],
      canShare: false,
      canView: true,
      canExtend: false,
      canBeDisplay: true,
      hiddenDisplayLimit: hiddenDisplayLimit,
    );
    final proEngine = await startEngine('MacBook Pro', pro);
    final airEngine = await startEngine('MacBook Air', air);
    final airId = await pair(proEngine, airEngine);
    return (
      pro: pro,
      air: air,
      capture: capture,
      injector: injector,
      decoder: decoder,
      airId: airId,
    );
  }

  test('the Pro offers, the Air says yes, its screen becomes the Pro\'s '
      'display, and its pointer drives it until the Air stops', () async {
    final macs = await twoMacs();
    final display = macs.pro.display;
    final routes = macs.air.routes;
    final viewer = macs.air.viewer;
    if (display == null || routes == null || viewer == null) {
      fail('Both sides should be set up');
    }

    expect(macs.pro.flags, contains(MirrorProtocol.extendFlag));
    expect(macs.air.flags, contains(MirrorProtocol.displayFlag));
    expect(macs.pro.flags, isNot(contains(MirrorProtocol.displayFlag)));

    await display.offer(macs.airId);
    await until(() => routes.requests.isNotEmpty);
    final request = routes.requests.single;
    expect(request.display, isTrue);
    expect(request.deviceName, 'MacBook Pro');
    expect(display.current?.phase, ExtendPhase.asking);

    routes.answer(request, allow: true);
    await until(() => display.current?.phase == .extending);
    final options = macs.capture.started.single;
    expect(options.width, 2940, reason: "the Air's own screen");
    expect(options.height, 1912);
    expect(options.scale, 2);
    expect(options.refreshHz, 120);
    expect(viewer.current?.isDisplay, isTrue);

    macs.capture.play();
    await until(() => macs.decoder.frames.isNotEmpty);
    expect(macs.decoder.configs.single.width, 2560);
    await until(() => viewer.control != null);
    expect(viewer.control?.abilities, contains(ControlAbility.mouse));

    viewer.control?.pointer(
      const MirrorPointer(phase: .hover, x: 0.3, y: 0.4, buttons: 0),
    );
    viewer.control?.pointer(
      const MirrorPointer(phase: .down, x: 0.3, y: 0.4, buttons: 2),
    );
    await until(() => macs.capture.pointers.length == 2);
    expect(macs.capture.pointers.first.phase, PointerPhase.hover);
    expect(macs.capture.pointers.first.x, closeTo(0.3, 0.0001));
    expect(macs.capture.pointers.last.buttons, 2);

    await viewer.stop();
    await until(() => macs.capture.stops == 1);
    expect(display.lastRecord?.end, ExtendEnd.stoppedThere);
  });

  test('a display that can\'t be seen goes on without decoding or asking '
      'for keyframes, and asks for one on the way back', () async {
    final macs = await twoMacs();
    final display = macs.pro.display;
    final routes = macs.air.routes;
    final viewer = macs.air.viewer;
    if (display == null || routes == null || viewer == null) {
      fail('Both sides should be set up');
    }

    await display.offer(macs.airId);
    await until(() => routes.requests.isNotEmpty);
    routes.answer(routes.requests.single, allow: true);
    await until(() => display.current?.phase == .extending);
    macs.capture.play();
    await until(() => macs.decoder.frames.isNotEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final asked = macs.capture.keyframeRequests;

    viewer.setHidden(true);
    for (var index = 0; index < 20; index++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      macs.capture.emit(
        CaptureFrame(
          MirrorFrame(
            data: Uint8List.fromList([0, 0, 0, 1, 0x41, index]),
            ptsUs: 2000 + index,
            keyframe: false,
          ),
        ),
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(macs.decoder.frames, hasLength(1), reason: 'nothing decoded');
    expect(macs.capture.keyframeRequests, asked);
    expect(viewer.current?.isLive, isTrue, reason: 'the display goes on');

    viewer.setHidden(false);
    await until(() => macs.capture.keyframeRequests == asked + 1);
    macs.capture.emit(
      CaptureFrame(
        MirrorFrame(
          data: Uint8List.fromList([0, 0, 0, 1, 0x65, 9]),
          ptsUs: 9000,
          keyframe: true,
        ),
      ),
    );
    await until(() => macs.decoder.frames.length == 2);
  });

  test('a display left unseen too long stops by itself', () async {
    final macs = await twoMacs(
      hiddenDisplayLimit: const Duration(milliseconds: 300),
    );
    final display = macs.pro.display;
    final routes = macs.air.routes;
    final viewer = macs.air.viewer;
    if (display == null || routes == null || viewer == null) {
      fail('Both sides should be set up');
    }

    await display.offer(macs.airId);
    await until(() => routes.requests.isNotEmpty);
    routes.answer(routes.requests.single, allow: true);
    await until(() => display.current?.phase == .extending);
    macs.capture.play();
    await until(() => macs.decoder.frames.isNotEmpty);

    viewer
      ..setHidden(true)
      ..setHidden(false)
      ..setHidden(true);
    await until(() => viewer.current?.phase == .ended);
    expect(viewer.current?.end, ViewEnd.stoppedHere);
    await until(() => macs.capture.stops == 1);
    expect(display.lastRecord?.end, ExtendEnd.stoppedThere);
  });

  test(
    'a no on the Air ends the offer on the Pro, and nothing is made',
    () async {
      final macs = await twoMacs();
      final display = macs.pro.display;
      final routes = macs.air.routes;
      if (display == null || routes == null) {
        fail('Both sides should be set up');
      }

      await display.offer(macs.airId);
      await until(() => routes.requests.isNotEmpty);
      routes.answer(routes.requests.single, allow: false);

      await until(() => display.lastRecord != null);
      expect(display.lastRecord?.end, ExtendEnd.declined);
      expect(display.current, isNull);
      expect(macs.capture.started, isEmpty);
    },
  );

  test('Stop on the Pro takes its offer back on the Air', () async {
    final macs = await twoMacs();
    final display = macs.pro.display;
    final routes = macs.air.routes;
    if (display == null || routes == null) {
      fail('Both sides should be set up');
    }

    await display.offer(macs.airId);
    await until(() => routes.requests.isNotEmpty);
    await display.stop();

    await until(() => routes.requests.isEmpty);
    expect(display.lastRecord?.end, ExtendEnd.stoppedHere);
  });

  test('Stop on the Pro takes the display off the Air', () async {
    final macs = await twoMacs();
    final display = macs.pro.display;
    final routes = macs.air.routes;
    final viewer = macs.air.viewer;
    if (display == null || routes == null || viewer == null) {
      fail('Both sides should be set up');
    }

    await display.offer(macs.airId);
    await until(() => routes.requests.isNotEmpty);
    routes.answer(routes.requests.single, allow: true);
    await until(() => display.current?.phase == .extending);
    macs.capture.play();
    await until(() => viewer.current?.isMirroring ?? false);

    await display.stop();

    await until(() => viewer.current?.phase == .ended);
    expect(viewer.current?.end, ViewEnd.stoppedOnPhone);
    expect(macs.capture.stops, 1);
  });

  test('a phone that shares its own screen can be a Mac\'s display too: '
      'it asks, sizes the display to itself, and its taps click', () async {
    final capture = FakeDisplayCapture();
    final decoder = FakeDecoder();
    final pro = MirroringFeature(
      display: () => capture,
      injector: FakeInjector.new,
      decoder: FakeDecoder.new,
      codecs: const [.h264],
      canShare: false,
      canView: true,
      canExtend: true,
      canBeDisplay: false,
    );
    final pixel = MirroringFeature(
      capture: FakeCapture.new,
      display: () => FakeDisplayCapture(screenNow: null),
      screenPanel: () => const ScreenPanel(
        width: 1080,
        height: 2400,
        scale: 2,
        refreshHz: 90,
      ),
      decoder: () => decoder,
      codecs: const [.h264, .jpeg],
      canShare: true,
      canShareCamera: false,
      canView: false,
      canExtend: false,
      canBeDisplay: true,
    );
    final proEngine = await startEngine('MacBook Pro', pro);
    final pixelEngine = await startEngine('Pixel 7', pixel);
    final pixelId = await pair(proEngine, pixelEngine);
    final display = pro.display;
    final routes = pixel.routes;
    final viewer = pixel.viewer;
    if (display == null || routes == null || viewer == null) {
      fail('The phone should be able to show a display');
    }

    expect(pixel.flags, contains(MirrorProtocol.displayFlag));
    expect(pixel.flags, isNot(contains(MirroringFeature.viewFlag)));
    expect(routes.targets, isEmpty, reason: 'nothing else comes in');

    await display.offer(pixelId);
    await until(() => routes.requests.isNotEmpty);
    expect(routes.requests.single.display, isTrue);
    expect(
      routes.askTimeout,
      const Duration(seconds: 30),
      reason: 'the same question as on a Mac',
    );

    routes.answer(routes.requests.single, allow: true);
    await until(() => display.current?.phase == .extending);
    final options = capture.started.single;
    expect(
      (options.width, options.height, options.scale, options.refreshHz),
      (1080, 2400, 2, 90),
    );

    capture.play();
    await until(() => decoder.frames.isNotEmpty);
    await until(() => viewer.control != null);
    final control = viewer.control;
    if (control == null) {
      fail('The display should take the phone\'s fingers');
    }

    final touch = TouchMouse(send: control.pointer);
    addTearDown(touch.dispose);
    const size = Size(400, 888);
    touch
      ..down(1, const Offset(100, 200), size)
      ..up(1, const Offset(100, 200), size);
    await until(() => capture.pointers.length == 3);
    expect(
      [for (final pointer in capture.pointers) pointer.phase],
      [PointerPhase.hover, PointerPhase.down, PointerPhase.up],
    );
    expect(capture.pointers[1].x, closeTo(0.25, 0.0001));
    expect(capture.pointers[1].buttons, 1);

    await viewer.stop();
    await until(() => capture.stops == 1);
    expect(display.lastRecord?.end, ExtendEnd.stoppedThere);
  });
}
