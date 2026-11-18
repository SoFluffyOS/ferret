// The harness may only touch test/screens, so packages the app gets through
// its modules are imported without listing them in pubspec.yaml.

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/protocol.dart';

/// Fills Activity with what a busy afternoon looks like, so the screens
/// show every kind of line without staging real transfers and songs.
class SampleActivityFeatureUi extends FeatureUi {
  @override
  String get featureId => 'screens.sample';

  @override
  final Feature feature = _SampleFeature();

  @override
  String title(BuildContext context) => 'Sample';

  @override
  IconData get icon => LucideIcons.sparkles;

  @override
  bool hasHomeCard(FeatureContext feature) => false;

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) {
    final now = DateTime.now();

    return [
      ActivityItem(
        id: 'media',
        icon: LucideIcons.music,
        title: 'Lo-fi mix · Pixel 9',
        detail: 'Chillhop Radio',
        pinned: true,
        actions: [
          ActivityAction(
            label: 'Pause',
            icon: LucideIcons.pause,
            onPressed: () {},
          ),
          ActivityAction(
            label: 'Next',
            icon: LucideIcons.skipForward,
            onPressed: () {},
          ),
        ],
      ),
      ActivityItem(
        id: 'transfer',
        icon: LucideIcons.arrowUp,
        title: 'Holiday.mov to Pixel 9',
        detail: 'To Pixel 9 · 26 MB of 42 MB',
        pinned: true,
        progress: 0.61,
        actions: [ActivityAction(label: 'Cancel', onPressed: () {})],
      ),
      ActivityItem(
        id: 'clip',
        icon: LucideIcons.clipboard,
        title: 'Copied on Pixel 9',
        detail: '“Meet at 6 at the usual place, bring the tickets”',
        at: now,
        actions: [ActivityAction(label: 'Copy', onPressed: () {})],
      ),
      ActivityItem(
        id: 'file',
        icon: LucideIcons.arrowDown,
        title: 'IMG_2041.jpg from Pixel 9',
        detail: 'Saved to Downloads › Ferret',
        at: now.subtract(const Duration(minutes: 2)),
        actions: [ActivityAction(label: 'Open', onPressed: () {})],
      ),
      ActivityItem(
        id: 'notification',
        icon: LucideIcons.bell,
        title: '3 notifications from Pixel 9',
        detail: 'Signal: Ana: on my way',
        at: now.subtract(const Duration(minutes: 14)),
        onTap: () {},
      ),
      ActivityItem(
        id: 'failed',
        icon: LucideIcons.triangleAlert,
        tone: .danger,
        title: 'Notes.pdf to iPad',
        detail: "Couldn't send to iPad. It went offline.",
        at: now.subtract(const Duration(hours: 3)),
        actions: [ActivityAction(label: 'Retry', onPressed: () {})],
      ),
      ActivityItem(
        id: 'ring',
        icon: LucideIcons.circleCheck,
        tone: .success,
        title: 'Pixel 9 was found',
        at: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}

class _SampleFeature extends Feature {
  @override
  String get id => 'screens.sample';

  @override
  Future<Null> onEnvelope(Session session, Envelope envelope) async => null;
}
