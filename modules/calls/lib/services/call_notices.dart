import 'dart:async';

import 'package:calls/l10n/l10n.dart';
import 'package:calls/models/models.dart';
import 'package:calls/services/calls_control.dart';
import 'package:feature_kit/feature_kit.dart';

/// The notices of Calls on a computer: one with Answer and Decline while a
/// phone rings, gone the moment it stops, and a quiet "Missed call" when
/// nobody picked up.
class CallNotices {
  CallNotices({
    required CallsControl control,
    required LocalNotifier notifier,
    required CallsLocalizations Function() strings,
    Future<void> Function()? onOpen,
  }) : _control = control,
       _notifier = notifier,
       _strings = strings,
       _onOpen = onOpen {
    _calls = control.callEvents.listen(_onCall);
    _responses = notifier.responses.listen(_onResponse);
  }

  static const incomingCategory = 'calls.incoming';
  static const missedCategory = 'calls.missed';
  static const answerAction = 'answer';
  static const declineAction = 'decline';
  static const callBackAction = 'callBack';

  final CallsControl _control;
  final LocalNotifier _notifier;
  final CallsLocalizations Function() _strings;

  /// Brings the app to the front when a ringing notice is tapped, where the
  /// home card has Answer and Decline.
  final Future<void> Function()? _onOpen;
  final Map<String, RemoteCall> _ringing = {};

  /// The last missed call per notice, for Call back.
  final Map<String, RemoteCall> _missed = {};
  late final StreamSubscription<RemoteCall> _calls;
  late final StreamSubscription<NoticeResponse> _responses;

  static List<NoticeCategory> categories(CallsLocalizations l10n) => [
    NoticeCategory(
      id: incomingCategory,
      actions: [
        NoticeAction(id: answerAction, label: l10n.answer),
        NoticeAction(id: declineAction, label: l10n.decline),
      ],
    ),
    NoticeCategory(
      id: missedCategory,
      actions: [NoticeAction(id: callBackAction, label: l10n.callBack)],
    ),
  ];

  static String ringingId(RemoteCall call) => 'calls.ring.${call.key}';

  static String missedId(String deviceId) => 'calls.missed.$deviceId';

  static String problemId(String deviceId) => 'calls.problem.$deviceId';

  Future<void> dispose() async {
    await _calls.cancel();
    await _responses.cancel();
  }

  void _onCall(RemoteCall call) {
    final noticeId = ringingId(call);
    if (call.isRinging && call.isIncoming) {
      _showRinging(noticeId, call);
      return;
    }

    if (_ringing.remove(noticeId) == null) {
      return;
    }

    unawaited(_notifier.cancel(noticeId));
    if (call.isEnded && call.wasMissed) {
      _showMissed(call);
    }
  }

  void _showRinging(String noticeId, RemoteCall call) {
    if (!_control.showIncoming) {
      return;
    }

    final l10n = _strings();
    // The name arrives a moment after the ring; the update must not ring the
    // computer a second time.
    final isUpdate = _ringing.containsKey(noticeId);
    _ringing[noticeId] = call;

    unawaited(
      _notifier.show(
        LocalNotice(
          id: noticeId,
          channel: .incoming,
          title: l10n.callerOf(call.call),
          body: l10n.noticeIncomingBody(call.deviceName),
          category: incomingCategory,
          groupKey: 'calls.${call.deviceId}',
          silent: isUpdate,
          ringing: true,
          private: PrivateContent(
            call.deviceId,
            cover: l10n.noticeIncomingBody(call.deviceName),
          ),
        ),
      ),
    );
  }

  void _showMissed(RemoteCall call) {
    final l10n = _strings();
    final noticeId = missedId(call.deviceId);
    final number = call.call.number;
    _missed[noticeId] = call;

    unawaited(
      _notifier.show(
        LocalNotice(
          id: noticeId,
          channel: .incoming,
          title: l10n.noticeMissedTitle,
          body: l10n.noticeMissedBody(
            l10n.callerOf(call.call),
            call.deviceName,
          ),
          category: switch (number.isEmpty) {
            true => null,
            false => missedCategory,
          },
          groupKey: 'calls.${call.deviceId}',
          silent: true,
          private: PrivateContent(
            call.deviceId,
            cover: l10n.noticeMissedTitle,
          ),
          // The phone app's own "Missed call", mirrored here, says the same.
          echo: NoticeEcho({
            for (final caller in [number, call.call.contactName])
              if (caller.isNotEmpty)
                NoticeEcho.callerKey(call.deviceId, caller),
          }, wins: true),
        ),
      ),
    );
  }

  void _onResponse(NoticeResponse response) {
    if (_missed[response.noticeId] case final missed?) {
      _onMissedResponse(response, missed);
      return;
    }

    final call = _ringing[response.noticeId];
    if (call == null) {
      return;
    }

    switch (response.actionId) {
      case answerAction:
        unawaited(_run(call, _control.answer));
      case declineAction:
        unawaited(_run(call, _control.end));
      case null:
        if (_onOpen case final onOpen?) {
          unawaited(onOpen());
        }
    }
  }

  void _onMissedResponse(NoticeResponse response, RemoteCall missed) {
    switch (response.actionId) {
      case callBackAction:
        _missed.remove(response.noticeId);
        unawaited(_notifier.cancel(response.noticeId));
        unawaited(
          _run(
            missed,
            (call) => _control.dial(call.deviceId, call.call.number),
          ),
        );
      case null:
        if (_onOpen case final onOpen?) {
          unawaited(onOpen());
        }
    }
  }

  Future<void> _run(
    RemoteCall call,
    Future<CommandOutcome> Function(RemoteCall call) command,
  ) async {
    final outcome = await command(call);
    if (outcome.isOk || outcome == .noCall) {
      return;
    }

    final l10n = _strings();
    await _notifier.show(
      LocalNotice(
        id: problemId(call.deviceId),
        channel: .problems,
        title: l10n.title,
        body: l10n.outcomeText(outcome, call.deviceName),
        silent: true,
      ),
    );
  }
}
