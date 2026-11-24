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
    bool? isExplicit,
    this.openFailed = false,
  }) : isExplicit = isExplicit ?? direction == .sent;

  final Activity activity;
  final HandoffPeer peer;
  final TimelineDirection direction;
  final DateTime at;

  /// Sent on purpose rather than offered passively. Only these show in
  /// Activity.
  final bool isExplicit;

  /// The receiving device got it but couldn't open it.
  final bool openFailed;

  TimelineEntry copyWith({bool? openFailed}) => TimelineEntry(
    activity: activity,
    peer: peer,
    direction: direction,
    at: at,
    isExplicit: isExplicit,
    openFailed: openFailed ?? this.openFailed,
  );

  Map<String, Object?> toJson() => {
    'activity': base64Encode(activity.writeToBuffer()),
    'peer_id': peer.id,
    'peer_name': peer.name,
    'direction': direction.name,
    'at_ms': at.millisecondsSinceEpoch,
    'explicit': isExplicit,
    'open_failed': openFailed,
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
          isExplicit: switch (json['explicit']) {
            final bool explicit => explicit,
            _ => null,
          },
          openFailed: json['open_failed'] == true,
        );
      } on Object {
        return null;
      }
    }

    return null;
  }
}
