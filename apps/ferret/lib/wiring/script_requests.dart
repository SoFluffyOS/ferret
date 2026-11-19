import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret/wiring/cli_control.dart';
import 'package:flutter/services.dart';
import 'package:scripting/scripting.dart';

/// Runs what Tasker (Android) and Shortcuts (iOS) ask for, with the same
/// commands as `ferret-cli`. Tasker can't show an answer, so a request
/// that didn't work says why in a notice; Shortcuts shows the answer
/// itself.
class ScriptRequests {
  ScriptRequests(this._engine, this._control);

  static const MethodChannel _shortcuts = MethodChannel(
    'io.sofluffy.ferret/shortcuts',
  );

  final FerretEngine _engine;
  final CliControl _control;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// Starts listening on a phone. Does nothing on a computer, which has
  /// `ferret-cli` instead.
  static ScriptRequests? attach(FerretEngine engine) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return null;
    }

    final requests = ScriptRequests(engine, CliControl.forEngine(engine));
    if (Platform.isAndroid) {
      requests._listenToTasker();
    }

    if (Platform.isIOS) {
      unawaited(requests._listenToShortcuts());
    }

    return requests;
  }

  /// Runs [request] and answers like `ferret-cli --json` would.
  Future<Map<String, Object?>> run(ScriptRequest request) async {
    final answer = await _control.handle(request.command, request.arguments);
    if (answer['ok'] == true) {
      return answer;
    }

    printWarning(
      '${request.source.name} ${request.command} failed: '
      '${answer['error'] ?? answer['result']}',
    );
    if (request.source == .tasker) {
      _engine.feature<ScriptingFeature>()?.reportFailure(
        ScriptRequestFailure(
          request: request,
          error: '${answer['error'] ?? answer['result']}',
          deviceName: switch (answer['device']) {
            final String name => name,
            _ => request.device,
          },
        ),
      );
    }

    return answer;
  }

  /// The scripting feature listens to Tasker from the first moment, so
  /// the request that started Ferret isn't lost; it runs them from here.
  void _listenToTasker() {
    _engine.feature<ScriptingFeature>()?.runRequestsWith(run);
  }

  Future<void> _listenToShortcuts() async {
    _shortcuts.setMethodCallHandler(_onShortcut);
    _subscriptions.add(_engine.deviceChanges.listen((_) => _shareDevices()));
    _shareDevices();
    try {
      await _shortcuts.invokeMethod<void>('ready');
    } on PlatformException catch (error) {
      printWarning('Shortcuts bridge is off', error);
    } on MissingPluginException {
      return;
    }
  }

  Future<Object?> _onShortcut(MethodCall call) async {
    if (call.method != 'run') {
      return null;
    }

    final request = switch (call.arguments) {
      final Map<Object?, Object?> map => ScriptRequest.fromMap(
        .shortcuts,
        map,
      ),
      _ => null,
    };
    if (request == null) {
      return {'ok': false, 'error': 'unknown_command'};
    }

    return run(request);
  }

  /// Tells Shortcuts which devices it can offer in its device picker.
  void _shareDevices() {
    final devices = [
      for (final status in _engine.devices)
        {
          'id': status.device.id,
          'name': _engine.displayNameOf(status.device.id),
        },
    ];
    unawaited(
      _shortcuts.invokeMethod<void>('setDevices', devices).catchError((_) {}),
    );
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
  }
}
