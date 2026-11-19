import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/actions.dart';

/// The picture for an action of [kind], the same wherever it shows.
IconData actionIcon(ActionKind kind) => switch (kind) {
  .ACTION_KIND_SLEEP => LucideIcons.moon,
  .ACTION_KIND_RESTART => LucideIcons.rotateCw,
  .ACTION_KIND_SHUT_DOWN => LucideIcons.power,
  .ACTION_KIND_MUTE => LucideIcons.volumeX,
  .ACTION_KIND_VOLUME_UP => LucideIcons.volume2,
  .ACTION_KIND_VOLUME_DOWN => LucideIcons.volume1,
  _ => LucideIcons.terminal,
};
