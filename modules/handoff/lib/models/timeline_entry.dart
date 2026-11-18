import 'dart:convert';

import 'package:handoff/models/handoff_peer.dart';
import 'package:protocol/handoff.dart';

enum TimelineDirection { sent, received }

/// One activity that went between this device and another.
class TimelineEntry {
  const TimelineEntry({
    required this.activity,
    required this.peer,
    required this.direction,
    required this.at,
  });

  final Activity activity;
  final HandoffPeer peer;
  final TimelineDirection direction;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'activity': base64Encode(activity.writeToBuffer()),
    'peer_id': peer.id,
    'peer_name': peer.name,
    'direction': direction.name,
    'at_ms': at.millisecondsSinceEpoch,
  };

  static TimelineEntry? fromJson(Object? json) {
    if (json case {
      'activity': final String encoded,
      'peer_id': final String peerId,
      'peer_name': final String peerName,
      'direction': final String directionName,
      'at_ms': final int atMs,
    }) {
      try {
        return TimelineEntry(
          activity: Activity.fromBuffer(base64Decode(encoded)),
          peer: HandoffPeer(id: peerId, name: peerName),
          direction: TimelineDirection.values.byName(directionName),
          at: .fromMillisecondsSinceEpoch(atMs),
        );
      } on Object {
        return null;
      }
    }

    return null;
  }
}
