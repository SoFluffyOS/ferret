import 'dart:typed_data';

import 'package:feature_kit/services/private_content.dart';
import 'package:feature_kit/services/search_text.dart';

/// Where a notice belongs, so people can tune each kind in system settings
/// instead of turning everything off.
enum NoticeChannel {
  /// Files being sent or received.
  transfers,

  /// Things another device sent here, such as mirrored notifications or calls.
  incoming,

  /// "Continue on this device" suggestions. Quiet by default.
  suggestions,

  /// Ringing a lost device. Loud, may override Do Not Disturb.
  find,

  /// A device can't connect and why.
  problems,
}

/// A button on a notice. [isReply] asks for text, such as replying to a
/// message.
class NoticeAction {
  const NoticeAction({
    required this.id,
    required this.label,
    this.isReply = false,
    this.opensApp = false,
  });

  final String id;
  final String label;
  final bool isReply;

  /// Brings Ferret to the front, for an answer that goes on in the app or
  /// in a system prompt: showing a screen, letting the camera on, opening
  /// a file. Other buttons do their work where the notice is, without
  /// unlocking the phone or opening anything.
  final bool opensApp;
}

/// A named set of actions notices can use, such as `message` with Reply and
/// Dismiss. macOS and iOS need every set before the first notice, so features
/// declare theirs in [FeatureUi.noticeCategories].
class NoticeCategory {
  const NoticeCategory({required this.id, required this.actions});

  /// Unique across features; prefix it with the feature id, such as
  /// `notifications.message`.
  final String id;
  final List<NoticeAction> actions;
}

/// What a notice is about, so two features telling the same news show it
/// once: a text seen by Messages and by the mirrored Google Messages
/// notification, or a missed call seen by Calls and by the phone app's
/// notification. Notices with a key in common within a couple of minutes
/// are one notice; the one that [wins] stays.
class NoticeEcho {
  const NoticeEcho(this.keys, {this.wins = false});

  /// A text [body] that arrived on [deviceId].
  NoticeEcho.text(String deviceId, String body, {bool wins = false})
    : this({textKey(deviceId, body)}, wins: wins);

  final Set<String> keys;

  /// This notice is the better of the two, such as Messages' own notice,
  /// whose Reply sends a text and which opens the conversation.
  final bool wins;

  static String textKey(String deviceId, String body) =>
      'text/$deviceId/${_plain(body)}';

  /// Who called, as a name or a number; numbers match on their last digits.
  static String callerKey(String deviceId, String caller) {
    final digits = caller.replaceAll(RegExp(r'\D'), '');
    final who = switch (digits.length >= _callerDigits) {
      true => digits.substring(digits.length - _callerDigits),
      false => _plain(caller),
    };
    return 'caller/$deviceId/$who';
  }

  static const _callerDigits = 8;
  static const _keptLength = 160;

  static String _plain(String text) {
    final folded = SearchText.fold(text.trim()).replaceAll(RegExp(r'\s+'), ' ');
    return switch (folded.length > _keptLength) {
      true => folded.substring(0, _keptLength),
      false => folded,
    };
  }
}

/// A local system notification shown by a feature.
class LocalNotice {
  const LocalNotice({
    required this.id,
    required this.channel,
    required this.title,
    this.body = '',
    this.category,
    this.groupKey,
    this.image,
    this.silent = false,
    this.progress,
    this.ongoing = false,
    this.ringing = false,
    this.private,
    this.public = false,
    this.echo,
  });

  /// Unique per notice; showing the same id again updates it.
  final String id;
  final NoticeChannel channel;
  final String title;
  final String body;

  /// The [NoticeCategory] whose actions this notice shows, if any.
  final String? category;

  /// Notices with the same key are grouped, such as all from one device.
  final String? groupKey;

  /// A small PNG, such as the source app's icon.
  final Uint8List? image;
  final bool silent;

  /// 0 to 1 for a progress bar, such as a file transfer.
  final double? progress;

  /// Stays until the feature cancels it and can't be swiped away, such as
  /// "Controlled by Pixel · Stop".
  final bool ongoing;

  /// Rings until someone answers, like an incoming call: Windows shows it
  /// as a call, which stays on screen and gets through Do not disturb's
  /// priority list.
  final bool ringing;

  /// Set when the title, body or image say something private, such as a
  /// mirrored notification or a text.
  final PrivateContent? private;

  /// Says nothing private and must stay readable everywhere: in full on a
  /// locked phone, and while the phone's screen is shared, where Android
  /// hides the rest. For a question asked during sharing, such as "Let
  /// MacBook control Pixel?", and "Controlled by MacBook · Stop".
  final bool public;

  /// Set when another feature may tell the same news; see [NoticeEcho].
  final NoticeEcho? echo;

  /// This notice with [private]'s cover as its title, [body] in place of
  /// the content and no image. Actions stay, so a call can still be
  /// answered.
  LocalNotice covered(String body) => LocalNotice(
    id: id,
    channel: channel,
    title: private?.cover ?? title,
    body: body,
    category: category,
    groupKey: groupKey,
    silent: silent,
    progress: progress,
    ongoing: ongoing,
    ringing: ringing,
  );
}

/// Someone tapped a notice or one of its actions.
class NoticeResponse {
  const NoticeResponse({required this.noticeId, this.actionId, this.replyText});

  final String noticeId;

  /// Null when the notice itself was tapped.
  final String? actionId;
  final String? replyText;
}

/// Shows local notifications for features. The app owns the one
/// implementation, so features never fight over the notification plugin.
abstract interface class LocalNotifier {
  Future<void> show(LocalNotice notice);

  Future<void> cancel(String id);

  /// Taps and actions on notices, for features to handle by notice id.
  Stream<NoticeResponse> get responses;
}
