import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHostApi implements RemoteInputHostApi {
  NativeAccess accessNow = NativeAccess(granted: true, needsPermission: false);
  final List<List<NativeInputEvent>> injected = [];
  int requests = 0;
  int releases = 0;
  int settingsOpened = 0;

  List<NativeInputEvent> get events => [for (final batch in injected) ...batch];

  @override
  Future<NativeAccess> access() async => accessNow;

  @override
  Future<bool> requestAccess() async {
    requests++;
    return accessNow.granted;
  }

  @override
  Future<void> openAccessSettings() async => settingsOpened++;

  @override
  Future<void> inject(List<NativeInputEvent> events) async =>
      injected.add(events);

  @override
  Future<void> releaseAll() async => releases++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('macOS', () {
    test('keys carry their modifiers as flags, also on release', () async {
      final api = FakeHostApi();
      final injector = NativeInjector.macos(api: api);

      await injector.inject(const [
        KeyAction(.c, pressed: true, modifiers: {.meta, .shift}),
        KeyAction(.c, pressed: false),
      ]);

      expect(api.events, hasLength(2));
      expect(api.events.first.kind, NativeEventKind.key);
      expect(api.events.first.code, 0x08);
      expect(api.events.first.modifiers, 9);
      expect(api.events.last.pressed, isFalse);
      expect(api.events.last.modifiers, 9);
    });

    test('media keys are system events', () async {
      final api = FakeHostApi();

      await NativeInjector.macos(
        api: api,
      ).inject(const [KeyAction(.mediaNext, pressed: true)]);

      expect(api.events.single.kind, NativeEventKind.mediaKey);
      expect(api.events.single.code, 19);
    });

    test('a missing permission reads as needs permission', () async {
      final api = FakeHostApi()
        ..accessNow = NativeAccess(granted: false, needsPermission: true);
      final injector = NativeInjector.macos(api: api);

      expect(
        await injector.status(),
        const InjectorStatus.needsPermission(.quartz),
      );
      expect(
        await injector.requestAccess(),
        const InjectorStatus.needsPermission(.quartz),
      );
      expect(api.requests, 1);
    });
  });

  group('Windows', () {
    test('modifiers are pressed as keys around the key', () async {
      final api = FakeHostApi();
      final injector = NativeInjector.windows(api: api);

      await injector.inject(const [
        KeyAction(.v, pressed: true, modifiers: {.control}),
        KeyAction(.v, pressed: false),
      ]);

      expect(
        [for (final event in api.events) (event.code, event.pressed)],
        [(0x11, true), (0x56, true), (0x56, false), (0x11, false)],
      );
      expect(api.events.every((event) => event.modifiers == 0), isTrue);
    });

    test('is ready without asking', () async {
      expect(
        await NativeInjector.windows(api: FakeHostApi()).status(),
        const InjectorStatus.ready(.sendInput),
      );
    });
  });

  test('moves, clicks, scrolls and text become native events', () async {
    final api = FakeHostApi();

    await NativeInjector.macos(api: api).inject(const [
      MoveAction(4, -2),
      ButtonAction(.right, pressed: true),
      ButtonAction(.right, pressed: false),
      ScrollAction(0, 30),
      TextAction('hi'),
      TextAction(''),
    ]);

    expect(
      [for (final event in api.events) event.kind],
      [
        NativeEventKind.move,
        NativeEventKind.button,
        NativeEventKind.button,
        NativeEventKind.scroll,
        NativeEventKind.text,
      ],
    );
    expect((api.events[0].x, api.events[0].y), (4, -2));
    expect(api.events[1].code, 1);
    expect(api.events[3].y, 30);
    expect(api.events[4].text, 'hi');
  });

  test('a release of a button that is not down is skipped', () async {
    final api = FakeHostApi();

    await NativeInjector.macos(
      api: api,
    ).inject(const [ButtonAction(.left, pressed: false)]);

    expect(api.injected, isEmpty);
  });

  test('release all lets go of what is held, then asks the platform', () async {
    final api = FakeHostApi();
    final injector = NativeInjector.windows(api: api);
    await injector.inject(const [
      ButtonAction(.left, pressed: true),
      KeyAction(.a, pressed: true, modifiers: {.shift}),
    ]);
    api.injected.clear();

    await injector.releaseAll();

    expect(
      [for (final event in api.events) (event.kind, event.code, event.pressed)],
      [
        (NativeEventKind.button, 0, false),
        (NativeEventKind.key, 0x41, false),
        (NativeEventKind.key, 0x10, false),
      ],
    );
    expect(api.releases, 1);
  });

  test('a failing platform reads as unavailable', () async {
    final injector = NativeInjector.macos(api: _ThrowingApi());

    expect(await injector.status(), const InjectorStatus.unavailable(.failed));
  });
}

class _ThrowingApi extends FakeHostApi {
  @override
  Future<NativeAccess> access() => throw StateError('no plugin');
}
