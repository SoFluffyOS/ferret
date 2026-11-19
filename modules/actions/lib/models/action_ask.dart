import 'package:actions/models/offered_action.dart';

/// A device waiting for this computer's owner to let it run an action.
class ActionAsk {
  const ActionAsk({
    required this.deviceId,
    required this.deviceName,
    required this.action,
    required this.askedAt,
  });

  final String deviceId;
  final String deviceName;
  final OfferedAction action;
  final DateTime askedAt;
}
