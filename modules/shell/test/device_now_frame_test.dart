import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/ui.dart';

void main() {
  final now = DateTime(2026, 11, 22, 10);
  const phone = 'a1b2c3d4e5f60718';

  ActivityItem line(String id, {String? deviceId, required Duration ago}) =>
      ActivityItem(
        id: id,
        icon: const IconData(0),
        title: id,
        deviceId: deviceId,
        at: now.subtract(ago),
      );

  test('the photo that just arrived stays at the top of the Overview', () {
    final feed = ActivityFeed.of([
      line('IMG_0412.jpg', deviceId: phone, ago: const Duration(seconds: 5)),
      line('older', deviceId: phone, ago: const Duration(minutes: 1)),
    ]);

    expect(DeviceNowFrame.justFinished(feed, phone, now)?.id, 'IMG_0412.jpg');
  });

  test('only lines about this device count', () {
    final feed = ActivityFeed.of([
      line('song here', ago: const Duration(seconds: 1)),
      line('from the iPad', deviceId: 'other', ago: Duration.zero),
    ]);

    expect(DeviceNowFrame.justFinished(feed, phone, now), isNull);
  });

  test('after a couple of minutes it leaves the top to Activity', () {
    final feed = ActivityFeed.of([
      line('IMG_0412.jpg', deviceId: phone, ago: const Duration(minutes: 3)),
    ]);

    expect(DeviceNowFrame.justFinished(feed, phone, now), isNull);
  });
}
