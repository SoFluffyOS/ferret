import 'package:handoff/models/handoff_peer.dart';
import 'package:protocol/handoff.dart';

/// An activity another device offered to continue here.
class Suggestion {
  const Suggestion({
    required this.activity,
    required this.from,
    required this.isExplicit,
    required this.receivedAt,
    required this.expiresAt,
  });

  final Activity activity;
  final HandoffPeer from;

  /// Sent on purpose ("Continue on…") rather than published passively.
  final bool isExplicit;
  final DateTime receivedAt;
  final DateTime expiresAt;

  String get id => activity.id;

  bool isLiveAt(DateTime now) => now.isBefore(expiresAt);
}
