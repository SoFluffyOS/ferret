import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';
import 'package:protocol/scripting.dart';
import 'package:scripting/models/models.dart';
import 'package:scripting/services/services.dart';

/// Lets scripts reach your devices: carries `ferret-cli notify` to another
/// device, which shows it only when its owner allowed scripts from this
/// one. The events for `ferret-cli watch` and hooks gather in [events].
class ScriptingFeature extends Feature {
  ScriptingFeature({
    ScriptEventHub? events,
    NoticeLimit? limit,
    this.requestTimeout = const Duration(seconds: 10),
  }) : events = events ?? ScriptEventHub(),
       _limit = limit ?? NoticeLimit();

  static const featureId = 'scripting';

  /// Flag in [FeatureSupport]: this device can show script notices.
  static const noticesFlag = 'notices';

  static const int maxTitleLength = 120;
  static const int maxBodyLength = 500;

  final ScriptEventHub events;
  final Duration requestTimeout;
  final NoticeLimit _limit;
  final StreamController<ScriptNoticeArrived> _notices = .broadcast();
  final StreamController<ScriptRequestFailure> _failures = .broadcast();
  final List<ScriptRequest> _waiting = [];
  Future<void> Function(ScriptRequest request)? _runner;

  /// How many requests from before the app was ready wait for it.
  static const int maxWaiting = 8;

  @override
  String get id => featureId;

  @override
  List<String> get flags => const [noticesFlag];

  ScriptingSettings get settings => ScriptingSettings(host.settings);

  /// Notices from other devices' scripts that may show here.
  Stream<ScriptNoticeArrived> get notices => _notices.stream;

  /// Tasker or Shortcuts requests that didn't work, to say why on screen.
  Stream<ScriptRequestFailure> get failures => _failures.stream;

  /// A request from Tasker or Shortcuts, run once the app is ready (see
  /// [runRequestsWith]), such as one that started Ferret.
  void receive(ScriptRequest request) {
    final runner = _runner;
    if (runner == null) {
      if (_waiting.length < maxWaiting) {
        _waiting.add(request);
      }

      return;
    }

    unawaited(runner(request));
  }

  /// Runs every request [receive] got, the waiting ones first.
  void runRequestsWith(Future<void> Function(ScriptRequest request) runner) {
    _runner = runner;
    final waiting = [..._waiting];
    _waiting.clear();
    for (final request in waiting) {
      unawaited(runner(request));
    }
  }

  /// Says on screen that [failure] happened. The app calls it after it ran
  /// a request from Tasker, which can't show an answer itself.
  void reportFailure(ScriptRequestFailure failure) {
    if (_failures.isClosed) {
      return;
    }

    _failures.add(failure);
  }

  @override
  Future<void> stop() async {
    await _notices.close();
    await _failures.close();
    await events.dispose();
  }

  /// Asks [deviceId] to show a notice. Answers `shown`, `not_allowed`,
  /// `too_many`, `empty`, `not_supported` or `unreachable`.
  Future<String> notify(String deviceId, String title, String body) async {
    final session = host.sessionFor(deviceId);
    if (session == null) {
      return 'unreachable';
    }

    if (!session.supports(featureId)) {
      return 'not_supported';
    }

    try {
      final reply = await session.call(
        featureId,
        ScriptNotice(
          title: _cut(title, maxTitleLength),
          body: _cut(body, maxBodyLength),
        ),
        ScriptNoticeReply.new,
        timeout: requestTimeout,
      );
      return switch (reply.result) {
        .SCRIPT_NOTICE_RESULT_SHOWN => 'shown',
        .SCRIPT_NOTICE_RESULT_NOT_ALLOWED => 'not_allowed',
        .SCRIPT_NOTICE_RESULT_TOO_MANY => 'too_many',
        .SCRIPT_NOTICE_RESULT_EMPTY => 'empty',
        _ => 'failed',
      };
    } on Object catch (error) {
      printWarning('Script notice to $deviceId got no answer', error);
      return 'unreachable';
    }
  }

  @override
  Future<void> onPairedDevices(Set<String> deviceIds) =>
      host.settings.keepOnlyPaired([ScriptingSettings.notifyKey], deviceIds);

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    if (payloadOf(envelope, ScriptNotice.new) case final notice?) {
      return ScriptNoticeReply(result: _receive(session, notice));
    }

    return null;
  }

  ScriptNoticeResult _receive(Session session, ScriptNotice notice) {
    final deviceId = session.remoteDeviceId;
    final title = _cut(notice.title.trim(), maxTitleLength);
    final body = _cut(notice.body.trim(), maxBodyLength);
    if (!settings.allowsNotices(deviceId)) {
      return .SCRIPT_NOTICE_RESULT_NOT_ALLOWED;
    }

    if (title.isEmpty && body.isEmpty) {
      return .SCRIPT_NOTICE_RESULT_EMPTY;
    }

    if (!_limit.allow(deviceId)) {
      return .SCRIPT_NOTICE_RESULT_TOO_MANY;
    }

    _notices.add(
      ScriptNoticeArrived(
        deviceId: deviceId,
        deviceName: host.displayNameOf(deviceId),
        title: title,
        body: body,
      ),
    );
    return .SCRIPT_NOTICE_RESULT_SHOWN;
  }

  static String _cut(String text, int length) {
    final characters = text.runes.toList();
    if (characters.length <= length) {
      return text;
    }

    return String.fromCharCodes(characters.take(length));
  }
}
