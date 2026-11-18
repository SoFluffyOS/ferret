import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

import 'support/fakes.dart';

void main() {
  MirrorPreferences preferences([Map<String, Object?>? values]) =>
      MirrorPreferences(
        MemorySettingsStore({MirrorPreferences.enabledKey: true, ...?values}),
      );

  test('a message from a messaging app is mirrored by default', () {
    expect(
      ForwardPolicy.decide(phoneNotification(), preferences()),
      ForwardDecision.forward,
    );
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

  test('other apps stay off until picked', () {
    final notification = phoneNotification(packageName: game);

    expect(
      ForwardPolicy.decide(notification, preferences()),
      ForwardDecision.appNotAllowed,
    );
    expect(
      ForwardPolicy.decide(
        notification,
        preferences({
          MirrorPreferences.allowedAppsKey: [game],
        }),
      ),
      ForwardDecision.forward,
    );
  });

  test('an explicit list replaces the messaging defaults', () {
    expect(
      ForwardPolicy.decide(
        phoneNotification(),
        preferences({MirrorPreferences.allowedAppsKey: <String>[]}),
      ),
      ForwardDecision.appNotAllowed,
    );
  });

  test('noise never leaves the phone', () {
    final noisy = [
      phoneNotification(isOngoing: true),
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
