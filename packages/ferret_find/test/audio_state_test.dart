import 'package:ferret_find/ferret_find.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the loudest state lifts Do Not Disturb only when allowed', () {
    const state = AudioState(
      volume: 2,
      maxVolume: 7,
      muted: true,
      interruptionFilter: 3,
      quiet: true,
    );

    final kept = state.loudest(liftDoNotDisturb: false);
    final lifted = state.loudest(liftDoNotDisturb: true);

    expect(kept.volume, 7);
    expect(kept.muted, isFalse);
    expect(kept.interruptionFilter, 3);
    expect(lifted.interruptionFilter, AudioState.filterAll);
    expect(lifted.isLoudest, isTrue);
  });

  test('an unknown filter stays unknown', () {
    const state = AudioState(volume: 10, maxVolume: 100);

    expect(
      state.loudest(liftDoNotDisturb: true).interruptionFilter,
      AudioState.unknownFilter,
    );
  });

  test('round trips through JSON and rejects anything else', () {
    const state = AudioState(
      volume: 4,
      maxVolume: 15,
      muted: true,
      interruptionFilter: 2,
    );

    expect(AudioState.fromJson(state.toJson()), state);
    expect(AudioState.fromJson(null), isNull);
    expect(AudioState.fromJson({'volume': 'loud'}), isNull);
  });

  test('ringing on silent needs volume control and, on Android, access', () {
    const android = RingAbilities(controlsVolume: true, needsDndAccess: true);
    const granted = RingAbilities(
      controlsVolume: true,
      needsDndAccess: true,
      dndAccessGranted: true,
    );
    const iphone = RingAbilities(ignoresSilentSwitch: true);
    const linux = RingAbilities();

    expect(android.canRingWhenSilent, isFalse);
    expect(android.missingDndAccess, isTrue);
    expect(granted.canRingWhenSilent, isTrue);
    expect(iphone.canRingWhenSilent, isTrue);
    expect(linux.canRingWhenSilent, isFalse);
  });
}
