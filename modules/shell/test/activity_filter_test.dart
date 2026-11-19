import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/services.dart';

ActivityItem _line(String id, String? deviceId, int minutesAgo) => ActivityItem(
  id: id,
  icon: const IconData(0),
  title: id,
  deviceId: deviceId,
  at: DateTime(2026, 11, 19, 12).subtract(Duration(minutes: minutesAgo)),
);

void main() {
  final feed = ActivityFeed.of([
    _line('pixel old', 'pixel', 40),
    _line('iphone', 'iphone', 3),
    _line('pixel new', 'pixel', 1),
    _line('here', null, 2),
  ]);

  test('the devices come newest line first, once each', () {
    expect(feed.deviceIds, ['pixel', 'iphone']);
  });

  test('a device filter keeps only its own lines', () {
    final pixel = feed.fromDevice('pixel');

    expect(
      [for (final item in pixel.recent) item.id],
      [
        'pixel new',
        'pixel old',
      ],
    );
  });
}
