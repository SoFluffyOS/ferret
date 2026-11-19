import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';

/// Settings saved by older builds keep meaning what they meant: someone who
/// comes back after a few updates finds what they had turned on still on.
void main() {
  MirroringSettings stored(Map<String, Object?> values) =>
      MirroringSettings(MemorySettingsStore(values));

  test('the old shared switch on keeps the cable and default receivers', () {
    final settings = stored({MirroringSettings.moreWaysKey: true});

    expect(settings.lookForCable, isTrue);
    expect(settings.receiverOn('airplay', byDefault: true), isTrue);
    expect(settings.receiverOn('cast', byDefault: false), isFalse);
  });

  test('a choice made since wins over the old switch', () {
    final settings = stored({
      MirroringSettings.moreWaysKey: true,
      MirroringSettings.lookForCableKey: false,
      '${MirroringSettings.receiverKeyPrefix}airplay': false,
    });

    expect(settings.lookForCable, isFalse);
    expect(settings.receiverOn('airplay', byDefault: true), isFalse);
  });

  test('without the old switch everything stays off', () {
    final settings = stored({});

    expect(settings.lookForCable, isFalse);
    expect(settings.receiverOn('airplay', byDefault: true), isFalse);
  });

  test('keys from removed options and unknown values fall back quietly', () {
    final settings = stored({
      'mirroring.actual_size': true,
      MirroringSettings.qualityKey: 'ultra_from_the_future',
      MirroringSettings.historyKey: 'not a list',
    });

    expect(settings.quality, QualityPreset.auto);
    expect(settings.history, isEmpty);
    expect(settings.enabled, isTrue);
  });
}
