import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:fixnum/fixnum.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/services/services.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/handoff.dart';
import 'package:protocol/protocol.dart';

/// The engine side of Handoff: sends what the user is doing to other
/// devices, and keeps what they offer as suggestions or opens it.
///
/// Passive activities ([publish]) become quiet suggestions on the other
/// devices that expire and are replaced by the next one. Explicit ones
/// ([sendTo]) open right away, or become a suggestion with a notice when the
/// receiver turned automatic opening off.
class HandoffFeature extends Feature {
  HandoffFeature({
    this.opener,
    DateTime Function()? clock,
    this.passiveLifetime = const Duration(minutes: 5),
    this.explicitLifetime = const Duration(minutes: 30),
    this.sendTimeout = const Duration(seconds: 15),
  }) : _now = clock ?? DateTime.now;

  static const featureId = 'handoff';

  /// Opens activities on this device; without one, everything that arrives
  /// becomes a suggestion.
  final ActivityOpener? opener;
  final Duration passiveLifetime;
  final Duration explicitLifetime;
  final Duration sendTimeout;

  static const _rememberedOutcomes = 100;

  final DateTime Function() _now;
  final SuggestionBoard _board = .new();
  final Map<String, ContinueOutcome> _outcomes = {};
  final Map<String, SendOutcome> _sendProblems = {};
  final StreamController<void> _changes = .broadcast();
  final StreamController<Suggestion> _arrivals = .broadcast();
  final StreamController<Suggestion> _removals = .broadcast();
  final StreamController<TimelineEntry> _autoOpened = .broadcast();
  late final HandoffTimeline _timeline;
  Timer? _expiryTimer;

  @override
  String get id => featureId;

  @override
  List<String> get flags => const ['send', 'receive', 'passive'];

  /// Fires when suggestions or the timeline change.
  Stream<void> get changes => _changes.stream;

  /// Explicit sends that weren't opened automatically, to show as a notice.
  Stream<Suggestion> get arrivals => _arrivals.stream;

  /// Suggestions that went away (opened, dismissed, expired, withdrawn).
  Stream<Suggestion> get removals => _removals.stream;

  /// Explicit sends this device opened as they arrived, for a quiet
  /// confirmation where opening shows nothing, such as copied text.
  Stream<TimelineEntry> get autoOpened => _autoOpened.stream;

  List<Suggestion> get suggestions => _board.live(_now());

  List<TimelineEntry> get timeline => _timeline.entries;

  bool get passiveEnabled =>
      host.settings.get<bool>(HandoffSettings.passive) ??
      HandoffSettings.passiveDefault;

  bool get opensAutomatically =>
      host.settings.get<bool>(HandoffSettings.openAutomatically) ??
      HandoffSettings.openAutomaticallyDefault;

  @override
  Future<void> onStart() async {
    _timeline = HandoffTimeline(host.settings)..load();
  }

  @override
  Future<void> stop() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }

  Future<void> setPassiveEnabled(bool enabled) async {
    await host.settings.set(HandoffSettings.passive, enabled);
    _changes.add(null);
    if (enabled) {
      return;
    }

    _removeAll(_board.live(_now()).where((item) => !item.isExplicit));
  }

  Future<void> setOpensAutomatically(bool enabled) async {
    await host.settings.set(HandoffSettings.openAutomatically, enabled);
    _changes.add(null);
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    final from = HandoffPeer.fromInfo(
      session.remoteDeviceId,
      session.remoteDevice,
      name: host.displayNameOf(session.remoteDeviceId),
    );

    if (payloadOf(envelope, PublishActivity.new) case final publish?) {
      await receivePublished(from, publish.activity);
      return null;
    }

    if (payloadOf(envelope, ContinueActivity.new) case final request?) {
      final outcome = await receiveContinue(from, request.activity);
      return ContinueResult(outcome: outcome);
    }

    if (payloadOf(envelope, ClearActivity.new) case final clear?) {
      receiveClear(from, clear.activityId);
      return null;
    }

    printDebug('Handoff ignored ${envelope.type} from ${from.id}');
    return null;
  }

  /// Offers [activity] as a quiet suggestion to the devices where the user
  /// is active (all of them when none says). Returns how many got it.
  Future<int> publish(Activity activity) async {
    if (!passiveEnabled) {
      return 0;
    }

    final stamped = _stamp(activity, passiveLifetime);
    var delivered = 0;
    for (final session in passiveTargets(host.sessions)) {
      try {
        await session.send(featureId, PublishActivity(activity: stamped));
        delivered++;
      } on Object catch (error) {
        printWarning('Handoff publish to ${session.remoteDeviceId}', error);
      }
    }

    return delivered;
  }

  /// Withdraws a published activity, or all of them with an empty id.
  Future<void> clearPublished([String activityId = '']) =>
      host.broadcast(featureId, ClearActivity(activityId: activityId));

  /// What went wrong with the last thing sent to [deviceId]:
  /// [SendOutcome.failed] when it arrived but couldn't be opened there,
  /// [SendOutcome.unreachable] when it never arrived. Null when it went
  /// through.
  SendOutcome? lastSendProblem(String deviceId) => _sendProblems[deviceId];

  /// Asks [deviceId] to continue [activity] now.
  Future<SendOutcome> sendTo(String deviceId, Activity activity) async {
    final session = host.sessionFor(deviceId);
    if (session == null || !session.supports(featureId)) {
      return .unreachable;
    }

    final outcome = await _sendTo(session, activity);
    final problem = switch (outcome) {
      .failed || .unreachable => outcome,
      .opened || .suggested => null,
    };
    if (_sendProblems[deviceId] == problem) {
      return outcome;
    }

    switch (problem) {
      case final problem?:
        _sendProblems[deviceId] = problem;
      case null:
        _sendProblems.remove(deviceId);
    }

    _changes.add(null);
    return outcome;
  }

  Future<SendOutcome> _sendTo(Session session, Activity activity) async {
    final deviceId = session.remoteDeviceId;
    final stamped = _stamp(activity, explicitLifetime);
    final outcome = await _ask(session, stamped);
    if (outcome == .unreachable) {
      return outcome;
    }

    await _timeline.add(
      TimelineEntry(
        activity: stamped,
        peer: HandoffPeer.fromInfo(
          deviceId,
          session.remoteDevice,
          name: host.displayNameOf(deviceId),
        ),
        direction: .sent,
        at: _now(),
        openFailed: outcome == .failed,
      ),
    );
    _changes.add(null);
    return outcome;
  }

  Future<SendOutcome> _ask(Session session, Activity activity) async {
    final deviceId = session.remoteDeviceId;
    try {
      final result = await session.call(
        featureId,
        ContinueActivity(activity: activity),
        ContinueResult.new,
        timeout: sendTimeout,
      );
      return switch (result.outcome) {
        .CONTINUE_OUTCOME_OPENED => .opened,
        .CONTINUE_OUTCOME_SUGGESTED => .suggested,
        _ => .failed,
      };
    } on RemoteErrorException catch (error) {
      printWarning('Handoff to $deviceId was refused', error);
      return .failed;
    } on Object catch (error) {
      printWarning('Handoff to $deviceId got no answer', error);
      return .unreachable;
    }
  }

  /// A passive activity arrived from [from].
  Future<void> receivePublished(HandoffPeer from, Activity activity) async {
    if (!passiveEnabled || !_isUsable(activity)) {
      return;
    }

    final lifetime = _lifetimeOf(activity, passiveLifetime);
    if (lifetime <= Duration.zero) {
      return;
    }

    final now = _now();
    _add(
      Suggestion(
        activity: activity,
        from: from,
        isExplicit: false,
        receivedAt: now,
        expiresAt: now.add(lifetime),
      ),
    );
    await _timeline.add(
      TimelineEntry(
        activity: activity,
        peer: from,
        direction: .received,
        at: now,
      ),
    );
    _changes.add(null);
  }

  /// An explicit "continue now" arrived from [from]. Opens it, or keeps it
  /// as a suggestion and announces it on [arrivals]: also when opening it
  /// failed, so it isn't lost.
  Future<ContinueOutcome> receiveContinue(
    HandoffPeer from,
    Activity activity,
  ) async {
    if (_outcomes[activity.id] case final earlier?) {
      return earlier;
    }

    if (!_isUsable(activity)) {
      return .CONTINUE_OUTCOME_FAILED;
    }

    final now = _now();
    final opened = await _openRightAway(activity);
    final outcome = switch (opened) {
      .opened => ContinueOutcome.CONTINUE_OUTCOME_OPENED,
      .failed => ContinueOutcome.CONTINUE_OUTCOME_FAILED,
      .deferred => ContinueOutcome.CONTINUE_OUTCOME_SUGGESTED,
    };
    final entry = TimelineEntry(
      activity: activity,
      peer: from,
      direction: .received,
      at: now,
      isExplicit: true,
      openFailed: opened == .failed,
    );
    await _timeline.add(entry);
    _remember(activity.id, outcome);
    if (outcome == .CONTINUE_OUTCOME_OPENED) {
      _autoOpened.add(entry);
    }

    if (outcome != .CONTINUE_OUTCOME_OPENED) {
      final suggestion = Suggestion(
        activity: activity,
        from: from,
        isExplicit: true,
        receivedAt: now,
        expiresAt: now.add(explicitLifetime),
        openFailed: opened == .failed,
      );
      _add(suggestion);
      _arrivals.add(suggestion);
    }

    _changes.add(null);
    return outcome;
  }

  /// [from] withdrew one of its activities, or all with an empty id.
  void receiveClear(HandoffPeer from, String activityId) {
    final removed = _board.clearFrom(from.id, activityId: activityId);
    if (removed.isEmpty) {
      return;
    }

    _announceRemoved(removed);
  }

  /// Opens a suggestion here. It goes away once opened.
  Future<OpenResult> open(Suggestion suggestion) async {
    final result = await _tryOpen(suggestion.activity);
    if (result == .opened) {
      dismiss(suggestion.id);
      await _markOpened(suggestion.id);
    }

    return result;
  }

  /// Opens what [entry] in the timeline is about again, here.
  Future<OpenResult> reopen(TimelineEntry entry) async {
    final result = await _tryOpen(entry.activity);
    if (result == .opened && entry.direction == .received) {
      dismiss(entry.activity.id);
      await _markOpened(entry.activity.id);
    }

    return result;
  }

  /// Lets [entry] go from the timeline, and from Activity with it.
  Future<void> forget(TimelineEntry entry) async {
    await _timeline.remove(entry);
    _changes.add(null);
  }

  void dismiss(String activityId) {
    if (_board.remove(activityId) case final removed?) {
      _announceRemoved([removed]);
    }
  }

  Future<void> clearTimeline() async {
    await _timeline.clear();
    _changes.add(null);
  }

  /// Where a passive activity goes: devices whose user is active right now,
  /// or every device that offers handoff when none reports being active.
  static List<Session> passiveTargets(List<Session> sessions) {
    final candidates = [
      for (final session in sessions)
        if (session.supports(featureId)) session,
    ];
    final active = [
      for (final session in candidates)
        if (session.remotePresence.userActive) session,
    ];
    if (active.isEmpty) {
      return candidates;
    }

    return active;
  }

  Future<OpenResult> _openRightAway(Activity activity) async {
    if (opener == null || !opensAutomatically) {
      return .deferred;
    }

    return _tryOpen(activity);
  }

  Future<OpenResult> _tryOpen(Activity activity) async {
    final opener = this.opener;
    if (opener == null) {
      return .failed;
    }

    try {
      return await opener.open(activity);
    } on Object catch (error) {
      printWarning('Handoff could not open an activity', error);
      return .failed;
    }
  }

  Activity _stamp(Activity activity, Duration lifetime) {
    final now = _now().millisecondsSinceEpoch;
    final stamped = activity.deepCopy()..sourceDeviceId = host.localDevice.id;
    if (stamped.id.isEmpty) {
      stamped.id = ActivityFactory.newId();
    }

    if (stamped.createdAtMs == Int64.ZERO) {
      stamped.createdAtMs = Int64(now);
    }

    if (stamped.expiresAtMs == Int64.ZERO) {
      stamped.expiresAtMs = stamped.createdAtMs + lifetime.inMilliseconds;
    }

    return stamped;
  }

  /// How long a suggestion lives here, measured from now so clocks that
  /// disagree between devices don't matter.
  Duration _lifetimeOf(Activity activity, Duration limit) {
    if (activity.createdAtMs == Int64.ZERO ||
        activity.expiresAtMs == Int64.ZERO) {
      return limit;
    }

    final asked = Duration(
      milliseconds: (activity.expiresAtMs - activity.createdAtMs).toInt(),
    );
    if (asked > limit) {
      return limit;
    }

    return asked;
  }

  bool _isUsable(Activity activity) {
    if (activity.id.isEmpty) {
      return false;
    }

    if (activity.text.length > ActivityFactory.maxTextLength ||
        activity.state.length > ActivityFactory.maxStateBytes) {
      return false;
    }

    return activity.uri.isNotEmpty ||
        activity.deepLink.isNotEmpty ||
        activity.fallbackWebUri.isNotEmpty ||
        activity.text.isNotEmpty;
  }

  void _add(Suggestion suggestion) {
    final replaced = _board.add(suggestion);
    _announceRemoved(replaced, notify: false);
  }

  void _removeAll(Iterable<Suggestion> suggestions) {
    final removed = [
      for (final suggestion in suggestions.toList())
        ?_board.remove(suggestion.id),
    ];
    _announceRemoved(removed);
  }

  void _announceRemoved(List<Suggestion> removed, {bool notify = true}) {
    for (final suggestion in removed) {
      _removals.add(suggestion);
    }

    if (notify && removed.isNotEmpty) {
      _changes.add(null);
    }

    _scheduleExpiry();
  }

  /// A link that couldn't open by itself was opened by hand after all.
  Future<void> _markOpened(String activityId) async {
    final failed = _timeline.entries.where(
      (entry) =>
          entry.activity.id == activityId &&
          entry.direction == .received &&
          entry.openFailed,
    );
    if (failed.firstOrNull case final entry?) {
      await _timeline.add(entry.copyWith(openFailed: false));
      _changes.add(null);
    }
  }

  void _remember(String activityId, ContinueOutcome outcome) {
    _outcomes[activityId] = outcome;
    while (_outcomes.length > _rememberedOutcomes) {
      _outcomes.remove(_outcomes.keys.first);
    }
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    final next = _board.nextExpiry;
    if (next == null) {
      return;
    }

    final wait = next.difference(_now()) + const Duration(milliseconds: 50);
    _expiryTimer = Timer(switch (wait.isNegative) {
      true => Duration.zero,
      false => wait,
    }, _onExpiry);
  }

  void _onExpiry() {
    final expired = _board.prune(_now());
    if (expired.isEmpty) {
      _scheduleExpiry();
      return;
    }

    _announceRemoved(expired);
  }
}
