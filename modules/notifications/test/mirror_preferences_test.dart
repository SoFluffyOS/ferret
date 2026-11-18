import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

import 'support/fakes.dart';

void main() {
  test('defaults: off, pause while in use, messaging apps', () {
    final preferences = MirrorPreferences(MemorySettingsStore());

    expect(preferences.enabled, isFalse);
    expect(preferences.skipWhileUsing, isTrue);
    expect(preferences.allowedApps, isNull);
    expect(preferences.isAllowed(signal), isTrue);
    expect(preferences.isAllowed(game), isFalse);
  });

  test('changing one app keeps the default picks', () async {
    final settings = MemorySettingsStore();
    final preferences = MirrorPreferences(settings);

    await preferences.setAllowed({game: true, signal: false});

    expect(preferences.isAllowed(game), isTrue);
    expect(preferences.isAllowed(signal), isFalse);
    expect(preferences.isAllowed('com.whatsapp'), isTrue);
    final stored = [
      ...?settings.get<List<Object?>>(MirrorPreferences.allowedAppsKey),
    ].whereType<String>().toList();
    expect(stored, [...stored]..sort());
  });

  test('picking the defaults keeps only installed messaging apps', () async {
    final source = FakeNotificationSource()
      ..apps = [
        .new(packageName: signal, name: 'Signal'),
        .new(packageName: game, name: 'Game'),
      ];
    final feature = NotificationsFeature(source: source);
    await feature.start(SettingsOnlyHost());

    await feature.pickDefaultApps();

    expect(feature.preferences.allowedApps, {signal});
  });

  test('only its own keys count as mirroring settings', () {
    expect(MirrorPreferences.owns(MirrorPreferences.enabledKey), isTrue);
    expect(MirrorPreferences.owns('clipboard.enabled'), isFalse);
  });
}
