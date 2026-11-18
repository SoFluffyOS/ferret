import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';
import 'package:protocol/notifications.dart';

import 'support/fakes.dart';

void main() {
  const bank = 'com.bank';

  test('defaults: off, pause while in use, every app', () {
    final preferences = MirrorPreferences(MemorySettingsStore());

    expect(preferences.enabled, isFalse);
    expect(preferences.skipWhileUsing, isTrue);
    expect(preferences.appFilter, AppFilter.APP_FILTER_ALL);
    expect(preferences.isAllowed(signal), isTrue);
    expect(preferences.isAllowed(game), isTrue);
  });

  test('all except mutes only the listed apps', () async {
    final preferences = MirrorPreferences(MemorySettingsStore());

    await preferences.setAppFilter(.APP_FILTER_ALL_EXCEPT);
    await preferences.setAllowed({game: false, bank: false});
    await preferences.setAllowed({bank: true});

    expect(preferences.excludedApps, {game});
    expect(preferences.isAllowed(game), isFalse);
    expect(preferences.isAllowed(bank), isTrue);
    expect(preferences.isAllowed(signal), isTrue);
  });

  test('only these forwards just the picked apps', () async {
    final preferences = MirrorPreferences(MemorySettingsStore());

    await preferences.setAppFilter(.APP_FILTER_ONLY);
    await preferences.setAllowed({signal: true, game: false});

    expect(preferences.isAllowed(signal), isTrue);
    expect(preferences.isAllowed(game), isFalse);
  });

  test('turning one app off under all apps mutes just that one', () async {
    final preferences = MirrorPreferences(MemorySettingsStore());

    await preferences.setAllowed({game: false});

    expect(preferences.appFilter, AppFilter.APP_FILTER_ALL_EXCEPT);
    expect(preferences.isAllowed(game), isFalse);
    expect(preferences.isAllowed(signal), isTrue);
  });

  test('each filter keeps its own list when switching', () async {
    final settings = MemorySettingsStore();
    final preferences = MirrorPreferences(settings);

    await preferences.setAppFilter(.APP_FILTER_ONLY);
    await preferences.setAllowed({signal: true});
    await preferences.setAppFilter(.APP_FILTER_ALL_EXCEPT);
    await preferences.setAllowed({game: false});
    await preferences.setAppFilter(.APP_FILTER_ONLY);

    expect(preferences.allowedApps, {signal});
    expect(preferences.excludedApps, {game});
    final stored = [
      ...?settings.get<List<Object?>>(MirrorPreferences.excludedAppsKey),
    ];
    expect(stored, [game]);
  });

  group('migration', () {
    test('old picks read as only these until migrated', () {
      final preferences = MirrorPreferences(
        MemorySettingsStore({
          MirrorPreferences.allowedAppsKey: [signal, game],
        }),
      );

      expect(preferences.needsMigration, isTrue);
      expect(preferences.appFilter, AppFilter.APP_FILTER_ONLY);
      expect(preferences.isAllowed(bank), isFalse);
    });

    test('hand-picked apps stay only these', () async {
      final preferences = MirrorPreferences(
        MemorySettingsStore({
          MirrorPreferences.allowedAppsKey: [signal, game],
        }),
      );

      await preferences.migrate({signal});

      expect(preferences.needsMigration, isFalse);
      expect(preferences.appFilter, AppFilter.APP_FILTER_ONLY);
      expect(preferences.allowedApps, {signal, game});
    });

    test('a messaging app turned off stays only these', () async {
      final preferences = MirrorPreferences(
        MemorySettingsStore({
          MirrorPreferences.allowedAppsKey: [signal],
        }),
      );

      await preferences.migrate({signal, 'com.whatsapp'});

      expect(preferences.appFilter, AppFilter.APP_FILTER_ONLY);
    });

    test('the untouched messaging defaults become all apps', () async {
      final preferences = MirrorPreferences(
        MemorySettingsStore({
          MirrorPreferences.allowedAppsKey: [signal, 'com.whatsapp'],
        }),
      );

      await preferences.migrate({signal});

      expect(preferences.appFilter, AppFilter.APP_FILTER_ALL);
      expect(preferences.isAllowed(bank), isTrue);
    });

    test('a chosen filter is never migrated', () async {
      final preferences = MirrorPreferences(
        MemorySettingsStore({
          MirrorPreferences.appFilterKey: 'only',
          MirrorPreferences.allowedAppsKey: [signal],
        }),
      );

      await preferences.migrate({signal});

      expect(preferences.needsMigration, isFalse);
      expect(preferences.appFilter, AppFilter.APP_FILTER_ONLY);
    });

    test('the phone migrates when it starts', () async {
      final source = FakeNotificationSource()
        ..apps = [
          .new(packageName: signal, name: 'Signal'),
          .new(packageName: game, name: 'Game'),
        ];
      final settings = MemorySettingsStore({
        MirrorPreferences.allowedAppsKey: [signal],
      });
      final feature = NotificationsFeature(source: source);

      await feature.start(SettingsOnlyHost(settings));
      await pumpEventQueue();

      expect(feature.preferences.appFilter, AppFilter.APP_FILTER_ALL);
    });
  });

  test('the app list says when each app last posted', () async {
    final source = FakeNotificationSource()
      ..apps = [
        .new(packageName: signal, name: 'Signal', lastPostedMs: 500),
        .new(packageName: game, name: 'Game', lastPostedMs: 100),
      ];
    final feature = NotificationsFeature(source: source);
    await feature.start(SettingsOnlyHost());

    source.post(phoneNotification(packageName: game, postedAtMs: 900));
    await pumpEventQueue();
    final apps = await feature.localApps();

    expect([for (final app in apps) app.lastPostedMs.toInt()], [500, 900]);
  });

  test('settings applied on the computer match the phone', () async {
    final settings = MemorySettingsStore();
    final preferences = MirrorPreferences(settings);
    var shown = MirrorSettings(appFilter: .APP_FILTER_ALL);
    final updates = [
      UpdateMirrorSettings(apps: [AppChoice(package: game)]),
      UpdateMirrorSettings(appFilter: .APP_FILTER_ONLY),
      UpdateMirrorSettings(
        apps: [AppChoice(package: signal, allowed: true)],
      ),
    ];

    for (final update in updates) {
      if (update.hasAppFilter()) {
        await preferences.setAppFilter(update.appFilter);
      }

      await preferences.setAllowed({
        for (final choice in update.apps) choice.package: choice.allowed,
      });
      shown = shown.withUpdate(update);
    }

    for (final package in [signal, game, bank]) {
      expect(shown.forwards(package), preferences.isAllowed(package));
    }
    expect(shown.excludedPackages, [game]);
  });

  test('phones from before filters forward their picked apps only', () {
    final settings = MirrorSettings(allowedPackages: [signal]);

    expect(settings.effectiveFilter, AppFilter.APP_FILTER_ONLY);
    expect(settings.forwards(signal), isTrue);
    expect(settings.forwards(game), isFalse);
  });

  test('only its own keys count as mirroring settings', () {
    expect(MirrorPreferences.owns(MirrorPreferences.enabledKey), isTrue);
    expect(MirrorPreferences.owns(MirrorPreferences.appFilterKey), isTrue);
    expect(MirrorPreferences.owns('clipboard.enabled'), isFalse);
  });
}
