import 'package:notifications/models/models.dart';

/// What a receiving device can do with mirrored notifications.
abstract interface class MirrorControl {
  /// What connected phones send.
  Stream<MirrorEvent> get mirrorEvents;

  /// Dismisses notification [key] on [deviceId].
  Future<bool> dismiss(String deviceId, String key);

  /// Runs action [actionId] of notification [key] on [deviceId].
  Future<bool> invokeAction(
    String deviceId,
    String key,
    String actionId, {
    String? replyText,
  });
}
