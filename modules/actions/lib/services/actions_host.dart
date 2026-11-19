import 'dart:async';
import 'dart:math';

import 'package:actions/models/models.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_actions/ferret_actions.dart';
import 'package:protocol/actions.dart';

/// The computer's side of actions: what it offers, the owner's yes the
/// first time a device asks for each one, the countdown before a restart
/// or a shut down, running it, and a line about every time.
class ActionsHost {
  ActionsHost({
    required FeatureHost host,
    required this.featureId,
    required ComputerActions computer,
    required CommandRunner runner,
    required ActionsSettings settings,
    DateTime Function()? clock,
    this.consentTimeout = const Duration(seconds: 60),
    this.countdownLength = const Duration(seconds: 10),
    this.commandTimeout = const Duration(seconds: 30),
    this.leaveDelay = const Duration(milliseconds: 500),
    this.denyCooldown = const Duration(seconds: 30),
  }) : _host = host,
       _computer = computer,
       _runner = runner,
       _settings = settings,
       _clock = clock ?? DateTime.now;

  /// How many runs Activity keeps in memory.
  static const recentLength = 10;

  final String featureId;

  /// How long the owner has to answer before the device is told nobody
  /// did.
  final Duration consentTimeout;

  /// How long the owner has to cancel a restart or a shut down.
  final Duration countdownLength;

  /// How long a custom action may run.
  final Duration commandTimeout;

  /// How long sleep, restart and shut down wait after the answer went
  /// out, so it reaches the device before this computer is gone.
  final Duration leaveDelay;

  /// After a no, the same device isn't asked about again for this long.
  final Duration denyCooldown;

  final FeatureHost _host;
  final ComputerActions _computer;
  final CommandRunner _runner;
  final ActionsSettings _settings;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final Map<String, DateTime> _deniedUntil = {};
  final List<ActionRecord> _recent = [];
  final Random _random = .secure();

  StreamSubscription<String>? _settingsSubscription;
  ActionAsk? _pending;
  Completer<ActionChoice?>? _answer;
  Timer? _consentTimer;
  ActionCountdown? _countdown;
  Completer<bool>? _countdownEnd;
  Timer? _countdownTimer;
  bool _disposed = false;

  /// Fires when anything the UI shows may have changed.
  Stream<void> get changes => _changes.stream;

  bool get enabled => _settings.enabled;

  /// The device asking right now, or null.
  ActionAsk? get pending => _pending;

  /// The restart or shut down about to happen, or null.
  ActionCountdown? get countdown => _countdown;

  /// What devices ran lately, newest first, for Activity.
  List<ActionRecord> get recent => List.unmodifiable(_recent);

  List<ActionRecord> get history => _settings.history;

  List<CustomAction> get custom => _settings.custom;

  /// Everything this computer offers: what the platform can do, then the
  /// owner's own actions.
  List<OfferedAction> get offered => [
    for (final (action, id, kind) in _builtIn)
      if (_computer.supported.contains(action))
        OfferedAction(id: id, kind: kind),
    for (final action in _settings.custom)
      OfferedAction(
        id: action.id,
        kind: .ACTION_KIND_CUSTOM,
        title: action.name,
        commandLine: action.commandLine,
      ),
  ];

  /// What "Always allow" can be given for, once each: the three sound
  /// actions count as one.
  List<OfferedAction> get grantable {
    final seen = <String>{};

    return [
      for (final action in offered)
        if (seen.add(action.grantId)) action,
    ];
  }

  static const _builtIn = [
    (ComputerAction.sleep, ActionIds.sleep, ActionKind.ACTION_KIND_SLEEP),
    (ComputerAction.restart, ActionIds.restart, ActionKind.ACTION_KIND_RESTART),
    (
      ComputerAction.shutDown,
      ActionIds.shutDown,
      ActionKind.ACTION_KIND_SHUT_DOWN,
    ),
    (ComputerAction.toggleMute, ActionIds.mute, ActionKind.ACTION_KIND_MUTE),
    (
      ComputerAction.volumeUp,
      ActionIds.volumeUp,
      ActionKind.ACTION_KIND_VOLUME_UP,
    ),
    (
      ComputerAction.volumeDown,
      ActionIds.volumeDown,
      ActionKind.ACTION_KIND_VOLUME_DOWN,
    ),
  ];

  void start() {
    _settingsSubscription = _settings.changes.listen(_onSettingChanged);
  }

  Future<void> dispose() async {
    _disposed = true;
    await _settingsSubscription?.cancel();
    _consentTimer?.cancel();
    _countdownTimer?.cancel();
    _takeAnswer()?.complete(null);
    _takeCountdownEnd()?.complete(false);
    await _changes.close();
  }

  /// Tells [session]'s device what it can ask for. With actions turned
  /// off, that is nothing.
  Future<void> sendList(Session session) async {
    if (!session.supports(featureId)) {
      return;
    }

    try {
      await session.send(featureId, _list());
    } on Object catch (error) {
      printWarning('Sending the action list failed', error);
    }
  }

  bool isAllowed(String deviceId, OfferedAction action) =>
      _settings.isAllowed(deviceId, action.grantId);

  Future<void> setAllowed(
    String deviceId,
    OfferedAction action, {
    required bool allowed,
  }) => _settings.setAllowed(deviceId, action.grantId, allowed: allowed);

  Future<void> setEnabled(bool value) async {
    await _settings.setEnabled(value);
    if (value) {
      return;
    }

    _consentTimer?.cancel();
    _pending = null;
    _takeAnswer()?.complete(null);
    cancelCountdown();
  }

  Future<CustomAction> addCustom({
    required String name,
    required String commandLine,
  }) async {
    final action = CustomAction(
      id: '${ActionIds.customPrefix}${_randomId()}',
      name: name.trim(),
      commandLine: commandLine.trim(),
    );
    await _settings.setCustom([..._settings.custom, action]);

    return action;
  }

  /// Renames [id] or changes what it runs. A new command line takes back
  /// every "Always allow": devices were allowed to run the old one.
  Future<void> updateCustom(
    String id, {
    required String name,
    required String commandLine,
  }) async {
    final line = commandLine.trim();
    final before = _settings.custom.where((action) => action.id == id);
    final changedCommand = before.any((action) => action.commandLine != line);
    if (changedCommand) {
      await _settings.revokeEverywhere(id);
    }

    await _settings.setCustom([
      for (final action in _settings.custom)
        switch (action.id == id) {
          true => CustomAction(id: id, name: name.trim(), commandLine: line),
          false => action,
        },
    ]);
  }

  Future<void> removeCustom(String id) async {
    await _settings.revokeEverywhere(id);
    await _settings.setCustom([
      for (final action in _settings.custom)
        if (action.id != id) action,
    ]);
  }

  /// Runs what [session]'s device asked for: after the owner's yes when it
  /// has none yet, and after the countdown for a restart or a shut down.
  Future<RunActionReply> onRun(Session session, RunAction request) async {
    if (!_settings.enabled) {
      return RunActionReply(result: .RUN_RESULT_TURNED_OFF);
    }

    final action = offered.where((action) => action.id == request.id);
    if (action.isEmpty) {
      return RunActionReply(result: .RUN_RESULT_UNKNOWN_ACTION);
    }

    return _run(session.remoteDeviceId, action.first);
  }

  /// The owner's answer to the device asking right now.
  Future<void> answer(ActionChoice choice) async {
    final pending = _pending;
    if (pending == null) {
      return;
    }

    _consentTimer?.cancel();
    _pending = null;
    if (choice == .always) {
      await setAllowed(pending.deviceId, pending.action, allowed: true);
    }

    if (choice == .deny) {
      _deniedUntil[pending.deviceId] = _clock().add(denyCooldown);
    }

    _takeAnswer()?.complete(choice);
    _emit();
  }

  /// Stops the restart or shut down that is counting down.
  void cancelCountdown() {
    if (_countdown == null) {
      return;
    }

    _countdownTimer?.cancel();
    _countdown = null;
    _takeCountdownEnd()?.complete(false);
    _emit();
  }

  /// A device that left takes its question with it. A countdown goes on:
  /// its device asked, and the owner can still cancel here.
  void onSessionClosed(String deviceId) {
    if (_pending?.deviceId != deviceId) {
      return;
    }

    _consentTimer?.cancel();
    _pending = null;
    _takeAnswer()?.complete(null);
    _emit();
  }

  void dismissRecord(String id) {
    _recent.removeWhere((record) => record.id == id);
    _emit();
  }

  Future<void> clearHistory() async {
    _recent.clear();
    await _settings.clearHistory();
    _emit();
  }

  Future<RunActionReply> _run(String deviceId, OfferedAction action) async {
    final needsAnswer = !isAllowed(deviceId, action);
    final isBusy = _countdown != null || (needsAnswer && _pending != null);
    if (isBusy || (action.countsDown && _pending != null)) {
      return RunActionReply(result: .RUN_RESULT_BUSY);
    }

    final deviceName = _host.displayNameOf(deviceId);
    if (needsAnswer) {
      final refusal = await _ask(deviceId, deviceName, action);
      if (refusal != null) {
        return _finish(deviceId, deviceName, action, refusal);
      }
    }

    if (action.countsDown && !await _countDown(deviceId, deviceName, action)) {
      return _finish(deviceId, deviceName, action, .RUN_RESULT_CANCELLED);
    }

    if (action.leavesReach) {
      unawaited(_leave(deviceId, deviceName, action));
      return RunActionReply(result: .RUN_RESULT_DONE);
    }

    if (action.kind == .ACTION_KIND_CUSTOM) {
      return _runCustom(deviceId, deviceName, action);
    }

    final worked = await _runBuiltIn(action);
    return _finish(
      deviceId,
      deviceName,
      action,
      switch (worked) {
        true => .RUN_RESULT_DONE,
        false => .RUN_RESULT_FAILED,
      },
      // A line for every volume step would bury everything else.
      record: !worked,
    );
  }

  /// Asks the owner. Null when they said yes, otherwise why not.
  Future<RunResult?> _ask(
    String deviceId,
    String deviceName,
    OfferedAction action,
  ) async {
    final deniedUntil = _deniedUntil[deviceId];
    if (deniedUntil != null && _clock().isBefore(deniedUntil)) {
      return .RUN_RESULT_DENIED;
    }

    final answer = Completer<ActionChoice?>();
    _answer = answer;
    _pending = ActionAsk(
      deviceId: deviceId,
      deviceName: deviceName,
      action: action,
      askedAt: _clock(),
    );
    _consentTimer = Timer(consentTimeout, _onConsentTimeout);
    _emit();

    return switch (await answer.future) {
      .always || .allowOnce => null,
      .deny => .RUN_RESULT_DENIED,
      // Turned off while the question was up reads as turned off.
      null when !_settings.enabled => .RUN_RESULT_TURNED_OFF,
      null => .RUN_RESULT_NOT_ANSWERED,
    };
  }

  void _onConsentTimeout() {
    _pending = null;
    _takeAnswer()?.complete(null);
    _emit();
  }

  /// True once the countdown ran out, false when it was cancelled.
  Future<bool> _countDown(
    String deviceId,
    String deviceName,
    OfferedAction action,
  ) {
    final end = Completer<bool>();
    final startedAt = _clock();
    _countdownEnd = end;
    _countdown = ActionCountdown(
      deviceId: deviceId,
      deviceName: deviceName,
      action: action,
      startedAt: startedAt,
      endsAt: startedAt.add(countdownLength),
    );
    _countdownTimer = Timer(countdownLength, () {
      _countdown = null;
      _takeCountdownEnd()?.complete(true);
      _emit();
    });
    _emit();

    return end.future;
  }

  /// Sleep, restart, shut down: the device already has its answer.
  Future<void> _leave(
    String deviceId,
    String deviceName,
    OfferedAction action,
  ) async {
    await Future<void>.delayed(leaveDelay);
    if (_disposed) {
      return;
    }

    final worked = await _runBuiltIn(action);
    await _finish(deviceId, deviceName, action, switch (worked) {
      true => .RUN_RESULT_DONE,
      false => .RUN_RESULT_FAILED,
    });
  }

  Future<bool> _runBuiltIn(OfferedAction action) async {
    final computerAction = _builtIn
        .where((entry) => entry.$2 == action.id)
        .map((entry) => entry.$1)
        .firstOrNull;
    if (computerAction == null) {
      return false;
    }

    try {
      return await _computer.run(computerAction);
    } on Object catch (error) {
      printWarning('Running ${action.id} failed', error);
      return false;
    }
  }

  Future<RunActionReply> _runCustom(
    String deviceId,
    String deviceName,
    OfferedAction action,
  ) async {
    final command = CommandLine.resolve(CommandLine.split(action.commandLine));
    final outcome = await _runner.run(command, timeout: commandTimeout);
    final result = switch (outcome) {
      CommandOutcome(timedOut: true) => RunResult.RUN_RESULT_TIMED_OUT,
      CommandOutcome(succeeded: true) => RunResult.RUN_RESULT_DONE,
      _ => RunResult.RUN_RESULT_FAILED,
    };

    return _finish(
      deviceId,
      deviceName,
      action,
      result,
      exitCode: outcome.exitCode,
      output: outcome.lastLine,
    );
  }

  Future<RunActionReply> _finish(
    String deviceId,
    String deviceName,
    OfferedAction action,
    RunResult result, {
    int? exitCode,
    String output = '',
    bool record = true,
  }) async {
    if (record && !_disposed) {
      final entry = ActionRecord(
        deviceId: deviceId,
        deviceName: deviceName,
        actionId: action.id,
        kind: action.kind,
        title: action.title,
        at: _clock(),
        result: result,
        exitCode: exitCode,
        output: output,
      );
      _recent.insert(0, entry);
      if (_recent.length > recentLength) {
        _recent.removeLast();
      }

      await _settings.addRecord(entry);
      _emit();
    }

    return RunActionReply(result: result, exitCode: exitCode);
  }

  void _onSettingChanged(String key) {
    if (key == ActionsSettings.customKey || key == ActionsSettings.enabledKey) {
      unawaited(_announce());
    }

    _emit();
  }

  Future<void> _announce() => _host.broadcast(featureId, _list());

  ActionList _list() => ActionList(
    actions: [
      if (_settings.enabled)
        for (final action in offered) action.toProto(),
    ],
  );

  Completer<ActionChoice?>? _takeAnswer() {
    final answer = _answer;
    _answer = null;
    return answer;
  }

  Completer<bool>? _takeCountdownEnd() {
    final end = _countdownEnd;
    _countdownEnd = null;
    return end;
  }

  String _randomId() => [
    for (var index = 0; index < 8; index++)
      _random.nextInt(16).toRadixString(16),
  ].join();

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
