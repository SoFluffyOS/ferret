import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/shell.dart';

FeatureAction _action(String id, {void Function()? onPressed}) => FeatureAction(
  id: id,
  label: id,
  icon: LucideIcons.circle,
  onPressed: onPressed ?? () {},
);

List<String?> _ids(List<FeatureAction> actions) => [
  for (final action in actions) action.id,
];

void main() {
  final actions = [
    _action('drop.send_files'),
    _action('clipboard.send'),
    _action('find.ring'),
    _action('mirroring.show_screen'),
  ];

  test('nothing moves before an action was used three times', () {
    final ordered = DeviceActionUsage.learnedOrder(actions, {'find.ring': 2});

    expect(_ids(ordered), _ids(actions));
  });

  test('the most used action moves first, the others keep their places', () {
    final ordered = DeviceActionUsage.learnedOrder(actions, {
      'clipboard.send': 3,
      'mirroring.show_screen': 5,
    });

    expect(_ids(ordered), [
      'mirroring.show_screen',
      'drop.send_files',
      'clipboard.send',
      'find.ring',
    ]);
  });

  test('a tie keeps the order the features gave', () {
    final ordered = DeviceActionUsage.learnedOrder(actions, {
      'find.ring': 4,
      'clipboard.send': 4,
    });

    expect(_ids(ordered).first, 'clipboard.send');
  });

  test('pressing an action counts it for that device only', () async {
    final settings = MemorySettingsStore();
    final usage = DeviceActionUsage(settings);
    var rang = 0;
    final arranged = usage.arrange('pixel', [
      _action('drop.send_files'),
      _action('find.ring', onPressed: () => rang++),
    ]);

    for (var press = 0; press < 3; press++) {
      arranged.last.onPressed?.call();
      await Future<void>.delayed(Duration.zero);
    }

    expect(rang, 3);
    expect(settings.get<Map<String, dynamic>>('shell.device_actions.pixel'), {
      'find.ring': 3,
    });
    expect(usage.countsFor('mac'), isEmpty);
    expect(_ids(usage.arrange('pixel', actions)).first, 'find.ring');
  });
}
