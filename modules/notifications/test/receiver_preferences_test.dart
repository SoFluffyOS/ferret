import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

void main() {
  const pixel = 'pixel';
  const tablet = 'tablet';

  test('every phone shows its notifications here by default', () {
    final preferences = ReceiverPreferences(MemorySettingsStore());

    expect(preferences.showsFrom(pixel), isTrue);
    expect(preferences.showsFrom(tablet), isTrue);
  });

  test('hiding one phone leaves the others on', () async {
    final preferences = ReceiverPreferences(MemorySettingsStore());

    await preferences.setShowsFrom(pixel, false);

    expect(preferences.showsFrom(pixel), isFalse);
    expect(preferences.showsFrom(tablet), isTrue);

    await preferences.setShowsFrom(pixel, true);

    expect(preferences.showsFrom(pixel), isTrue);
  });
}
