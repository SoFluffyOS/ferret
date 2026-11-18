import 'package:ferret_find/ferret_find.dart';
import 'package:ferret_find/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps abilities and marks iOS as ignoring the silent switch', () async {
    final find = PigeonFind(api: _FakeHostApi(), isIos: true);

    final abilities = await find.abilities();

    expect(abilities.controlsVolume, isTrue);
    expect(abilities.needsDndAccess, isTrue);
    expect(abilities.dndAccessGranted, isFalse);
    expect(abilities.showsOwnAlert, isTrue);
    expect(abilities.ignoresSilentSwitch, isTrue);
  });

  test('reads and applies the volume both ways', () async {
    final api = _FakeHostApi()
      ..audio = PlatformAudio(
        volume: 3,
        maxVolume: 7,
        muted: false,
        interruptionFilter: 2,
        quiet: true,
      );
    final find = PigeonFind(api: api, isIos: false);

    final audio = await find.readAudio();
    await find.applyAudio(const AudioState(volume: 7, maxVolume: 7));

    expect(
      audio,
      const AudioState(
        volume: 3,
        maxVolume: 7,
        interruptionFilter: 2,
        quiet: true,
      ),
    );
    expect(api.applied?.volume, 7);
    expect(api.applied?.interruptionFilter, AudioState.unknownFilter);
  });

  test('passes the alert and reports native stops', () async {
    final api = _FakeHostApi();
    final find = PigeonFind(api: api, isIos: false);
    final stops = <AlertStop>[];
    final subscription = find.stops.listen(stops.add);

    await find.startAlert(
      const RingAlert(
        title: 'Ringing',
        body: 'Laptop is looking for this phone',
        foundItLabel: 'Found it',
        maxDuration: Duration(minutes: 2),
        flashTorch: true,
      ),
    );
    find
      ..onAlertStopped('volume_key')
      ..onAlertStopped('something else')
      ..onAlertStopped('found');
    await Future<void>.delayed(Duration.zero);

    expect(api.alert?.maxSeconds, 120);
    expect(api.alert?.flashTorch, isTrue);
    expect(api.alert?.silent, isFalse);
    expect(stops, [AlertStop.volumeKey, AlertStop.found]);
    await subscription.cancel();
  });
}

class _FakeHostApi extends FindHostApi {
  PlatformAudio? audio;
  PlatformAudio? applied;
  PlatformAlert? alert;

  @override
  Future<PlatformRingAbilities> abilities() async => PlatformRingAbilities(
    controlsVolume: true,
    needsDndAccess: true,
    dndAccessGranted: false,
    fullScreenAllowed: true,
    hasTorch: true,
    ringsInBackground: true,
    showsOwnAlert: true,
  );

  @override
  Future<PlatformAudio?> readAudio() async => audio;

  @override
  Future<void> applyAudio(PlatformAudio audio) async => applied = audio;

  @override
  Future<void> startAlert(PlatformAlert alert) async => this.alert = alert;

  @override
  Future<void> stopAlert() async => alert = null;
}
