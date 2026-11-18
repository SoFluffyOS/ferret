import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

import 'support/fakes.dart';

void main() {
  MirrorPreferences preferences([Map<String, Object?>? values]) =>
      MirrorPreferences(
        MemorySettingsStore({MirrorPreferences.enabledKey: true, ...?values}),
      );

  test('every app is mirrored by default', () {
    for (final packageName in [signal, game]) {
      expect(
        ForwardPolicy.decide(
          phoneNotification(packageName: packageName),
          preferences(),
        ),
        ForwardDecision.forward,
      );
    }
  });

  test('nothing is mirrored until mirroring is turned on', () {
    expect(
      ForwardPolicy.decide(
        phoneNotification(),
        MirrorPreferences(MemorySettingsStore()),
      ),
      ForwardDecision.disabled,
    );
  });

  test('a muted app stays on the phone', () {
    final muted = preferences({
      MirrorPreferences.appFilterKey: 'all_except',
      MirrorPreferences.excludedAppsKey: [game],
    });

    expect(
      ForwardPolicy.decide(phoneNotification(packageName: game), muted),
      ForwardDecision.appNotAllowed,
    );
    expect(
      ForwardPolicy.decide(phoneNotification(), muted),
      ForwardDecision.forward,
    );
  });

  test('only these apps leaves the others on the phone', () {
    final only = preferences({
      MirrorPreferences.appFilterKey: 'only',
      MirrorPreferences.allowedAppsKey: [game],
    });

    expect(
      ForwardPolicy.decide(phoneNotification(), only),
      ForwardDecision.appNotAllowed,
    );
    expect(
      ForwardPolicy.decide(phoneNotification(packageName: game), only),
      ForwardDecision.forward,
    );
  });

  test('noise never leaves the phone', () {
    final noisy = [
      phoneNotification(isOngoing: true),
      phoneNotification(isMedia: true),
      phoneNotification(isForegroundService: true),
      phoneNotification(isGroupSummary: true),
      phoneNotification(importance: 2),
      phoneNotification(importance: 0),
      phoneNotification(title: ' ', text: ''),
    ];

    for (final notification in noisy) {
      expect(
        ForwardPolicy.decide(notification, preferences()),
        ForwardDecision.noise,
      );
    }
  });

  test('an unknown importance is not treated as quiet', () {
    expect(ForwardPolicy.isNoise(phoneNotification(importance: -1000)), false);
  });

  test('the content hash ignores the time but not the text', () {
    final first = phoneNotification(postedAtMs: 1);
    final later = phoneNotification(postedAtMs: 2);
    final edited = phoneNotification(postedAtMs: 2, text: 'Edited');

    expect(
      ForwardPolicy.contentHash(first),
      ForwardPolicy.contentHash(later),
    );
    expect(
      ForwardPolicy.contentHash(first),
      isNot(ForwardPolicy.contentHash(edited)),
    );
  });
}
