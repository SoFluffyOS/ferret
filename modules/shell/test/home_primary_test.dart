import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/widgets/widgets.dart';

import 'test_app.dart';

ActivityItem _item(String id, {bool primary = false, bool pinned = false}) =>
    ActivityItem(
      id: id,
      icon: LucideIcons.download,
      title: id,
      pinned: pinned,
      actions: [
        ActivityAction(label: 'Go $id', primary: primary, onPressed: () {}),
        ActivityAction(label: 'Decline $id', onPressed: () {}),
      ],
    );

void main() {
  test('what needs an answer holds the primary before a ringing call', () {
    final offer = _item('offer', primary: true);
    final call = _item('call', primary: true, pinned: true);

    final feed = ActivityFeed(needsYou: [offer], pinned: [call], recent: []);

    expect(feed.primaryItem, same(offer));
  });

  test('a ringing call holds the primary when nothing needs an answer', () {
    final media = _item('media', pinned: true);
    final call = _item('call', primary: true, pinned: true);

    final feed = ActivityFeed(pinned: [media, call], recent: []);

    expect(feed.primaryItem, same(call));
  });

  test('only the first of two waiting lines holds the primary', () {
    final first = _item('first', primary: true);
    final second = _item('second', primary: true);

    final feed = ActivityFeed(
      needsYou: [first, second],
      pinned: [],
      recent: [],
    );

    expect(feed.primaryItem, same(first));
  });

  test('something that already happened leaves the primary to the device', () {
    final feed = ActivityFeed(
      pinned: [_item('media', pinned: true)],
      recent: [_item('received', primary: true)],
    );

    expect(feed.primaryItem, isNull);
  });

  testWidgets('a line that lost the primary draws its action outlined', (
    tester,
  ) async {
    var accepted = 0;

    await tester.pumpWidget(
      testApp(
        ActivityRow(
          now: DateTime(2026, 11, 19, 12),
          holdsPrimary: false,
          item: ActivityItem(
            id: 'call',
            icon: LucideIcons.phone,
            title: 'Ana is calling Pixel',
            pinned: true,
            actions: [
              ActivityAction(
                label: 'Answer',
                primary: true,
                onPressed: () => accepted++,
              ),
            ],
          ),
        ),
      ),
    );

    final button = tester.widget<RowActionButton>(find.byType(RowActionButton));
    expect(button.label, 'Answer');
    expect(button.isPrimary, isFalse);
    await tester.tap(find.text('Answer'));
    expect(accepted, 1);
  });
}
