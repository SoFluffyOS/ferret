import 'package:actions/actions.dart';
import 'package:clipboard/clipboard.dart';
import 'package:core/core.dart';
import 'package:drop/drop.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret/wiring/script_events.dart';
import 'package:find/find.dart';
import 'package:handoff/handoff.dart';
import 'package:phone_camera/phone_camera.dart';
import 'package:scripting/scripting.dart';
import 'package:wake/wake.dart';

/// A paired device as `ferret-cli` names it.
typedef CliDevice = ({String id, String name, bool isConnected});

/// The last clip that arrived from another device, as `ferret-cli
/// clipboard get` prints it.
typedef CliClip = ({String text, String from, DateTime at});

/// An action a computer offers, as `ferret-cli action` names it.
typedef CliAction = ({String id, String title});

/// How an action ran on another computer: `done`, `denied`, `timed_out`…,
/// and how a command of its owner's ended.
typedef CliActionResult = ({String result, int? exitCode});

/// How asking a phone for a picture ended: `done` with where it was saved,
/// or `declined`, `expired`….
typedef CliPicture = ({String result, String? path});

/// Answers `ferret-cli` commands (`ring`, `clipboard`, `action`, `wake`,
/// `open`, `notify`, `camera`, `watch`) from the running app, and the same commands
/// from Tasker and Shortcuts on a phone. Features never import each other,
/// so the app joins them here.
class CliControl {
  CliControl({
    required List<CliDevice> Function() devices,
    Future<String> Function(String deviceId)? ring,
    CliClip? Function()? latestClip,
    Future<String> Function(String text, String? deviceId)? sendText,
    List<CliAction> Function(String deviceId)? actionsOf,
    Future<CliActionResult> Function(String deviceId, String actionId)?
    runAction,
    Future<String> Function(String deviceId)? wake,
    Future<String> Function(String deviceId, String link)? openLink,
    Future<String> Function(String deviceId, String title, String body)? notify,
    Future<String> Function(String deviceId, List<String> paths)? sendFiles,
    Future<CliPicture> Function(String deviceId, {required bool document})?
    takePicture,
  }) : _devices = devices,
       _ring = ring,
       _latestClip = latestClip,
       _sendText = sendText,
       _actionsOf = actionsOf,
       _runAction = runAction,
       _wake = wake,
       _openLink = openLink,
       _notify = notify,
       _sendFiles = sendFiles,
       _takePicture = takePicture;

  final List<CliDevice> Function() _devices;
  final Future<String> Function(String deviceId)? _ring;
  final CliClip? Function()? _latestClip;
  final Future<String> Function(String text, String? deviceId)? _sendText;
  final List<CliAction> Function(String deviceId)? _actionsOf;
  final Future<CliActionResult> Function(String deviceId, String actionId)?
  _runAction;
  final Future<String> Function(String deviceId)? _wake;
  final Future<String> Function(String deviceId, String link)? _openLink;
  final Future<String> Function(String deviceId, String title, String body)?
  _notify;
  final Future<String> Function(String deviceId, List<String> paths)?
  _sendFiles;
  final Future<CliPicture> Function(String deviceId, {required bool document})?
  _takePicture;

  static const String ringCommand = 'ring';
  static const String clipboardGetCommand = 'clipboard_get';
  static const String clipboardSendCommand = 'clipboard_send';
  static const String actionListCommand = 'action_list';
  static const String actionRunCommand = 'action_run';
  static const String wakeCommand = 'wake';
  static const String openCommand = 'open';
  static const String notifyCommand = 'notify';
  static const String sendFilesCommand = 'send_files';
  static const String cameraCommand = 'camera';

  /// Starts answering on this computer, or returns null on phones, where
  /// there is no command line.
  static Future<AppControl?> attach(
    FerretEngine engine, {
    required bool isComputer,
  }) async {
    if (!isComputer) {
      return null;
    }

    final control = CliControl.forEngine(engine);
    final paths = await AppPaths.get();
    final server = AppControl(paths.root);
    final hub = engine.feature<ScriptingFeature>()?.events;
    final events = ScriptEvents.attach(engine);
    await server.listen(
      control.handle,
      watch: switch ((hub, events)) {
        (final hub?, final events?) => (arguments) => hub.watch(
          arguments,
          devices: events.devices,
        ),
        _ => null,
      },
    );
    return server;
  }

  factory CliControl.forEngine(FerretEngine engine) {
    final find = engine.feature<FindFeature>();
    final clipboard = engine.feature<ClipboardFeature>();
    final actions = engine.feature<ActionsFeature>();
    final wake = engine.feature<WakeFeature>();
    final handoff = engine.feature<HandoffFeature>();
    final scripting = engine.feature<ScriptingFeature>();
    final drop = engine.feature<DropFeature>();
    final camera = engine.feature<CameraFeature>();

    return CliControl(
      devices: () => [
        for (final status in engine.devices)
          (
            id: status.device.id,
            name: engine.displayNameOf(status.device.id),
            isConnected: status.isConnected,
          ),
      ],
      ring: switch (find) {
        final find? => (deviceId) async => (await find.ring(
          deviceId,
        )).phase.name,
        null => null,
      },
      latestClip: switch (clipboard) {
        final clipboard? => () => _latestReceived(clipboard),
        null => null,
      },
      sendText: switch (clipboard) {
        final clipboard? => (text, deviceId) async => (await clipboard.sendText(
          text,
          toDeviceId: deviceId,
        )).name,
        null => null,
      },
      actionsOf: switch (actions) {
        final actions? => (deviceId) => [
          for (final action in actions.actionsOf(deviceId))
            (id: action.id, title: action.title),
        ],
        null => null,
      },
      runAction: switch (actions) {
        final actions? => (deviceId, actionId) => _runOn(
          actions,
          deviceId,
          actionId,
        ),
        null => null,
      },
      wake: switch (wake) {
        final wake? => (deviceId) => _wakeWith(wake, engine, deviceId),
        null => null,
      },
      openLink: switch (handoff) {
        final handoff? => (deviceId, link) => _openWith(
          handoff,
          deviceId,
          link,
        ),
        null => null,
      },
      notify: switch (scripting) {
        final scripting? => scripting.notify,
        null => null,
      },
      sendFiles: switch (drop) {
        final drop? => (deviceId, paths) async => switch (await drop.sendFiles(
          deviceId,
          paths,
        )) {
          final _? => 'sending',
          null => 'nothing_to_send',
        },
        null => null,
      },
      takePicture: switch (camera) {
        final camera? => (deviceId, {required document}) => _pictureFrom(
          camera,
          deviceId,
          document: document,
        ),
        null => null,
      },
    );
  }

  /// Asks [deviceId] for a picture and waits until it arrived or the
  /// request ended, as Activity shows it.
  static Future<CliPicture> _pictureFrom(
    CameraFeature camera,
    String deviceId, {
    required bool document,
  }) async {
    final job = await camera.request(
      deviceId,
      kind: switch (document) {
        true => PictureKind.document,
        false => PictureKind.photo,
      },
    );
    var current = camera.jobs[job.id] ?? job;
    if (current.status.isOpen) {
      await camera.jobs.changes
          .map((_) => camera.jobs[job.id])
          .firstWhere((latest) => latest == null || !latest.status.isOpen);
      current = camera.jobs[job.id] ?? current.copyWith(status: .cancelled);
    }

    return (result: current.status.name, path: current.paths.firstOrNull);
  }

  Future<Map<String, Object?>> handle(
    String command,
    Map<String, Object?> arguments,
  ) async => switch (command) {
    ringCommand => _ringDevice(arguments),
    clipboardGetCommand => _clipboardGet(),
    clipboardSendCommand => _clipboardSend(arguments),
    actionListCommand => _actionList(arguments),
    actionRunCommand => _actionRun(arguments),
    wakeCommand => _wakeDevice(arguments),
    openCommand => _open(arguments),
    notifyCommand => _notifyDevice(arguments),
    sendFilesCommand => _sendFilesTo(arguments),
    cameraCommand => _camera(arguments),
    _ => _failure('unknown_command'),
  };

  Future<Map<String, Object?>> _camera(Map<String, Object?> arguments) async {
    final takePicture = _takePicture;
    if (takePicture == null) {
      return _failure('not_supported');
    }

    final device = _connected(arguments['device']);
    if (device case {'ok': false}) {
      return device;
    }

    final picture = await takePicture(
      '${device['id']}',
      document: arguments['kind'] == 'document',
    );
    return {
      'ok': picture.result == CaptureJobStatus.done.name,
      'device': device['device'],
      'result': picture.result,
      'path': ?picture.path,
    };
  }

  Future<Map<String, Object?>> _ringDevice(
    Map<String, Object?> arguments,
  ) async {
    final ring = _ring;
    if (ring == null) {
      return _failure('not_supported');
    }

    final match = _match(arguments['device']);
    if (match case {'ok': false}) {
      return match;
    }

    final device = _deviceOf(match);
    if (device == null) {
      return _failure('unknown_device');
    }

    if (!device.isConnected) {
      return _failure('not_connected', device: device.name);
    }

    final phase = await ring(device.id);
    return {
      'ok': phase == 'ringing' || phase == 'found',
      'device': device.name,
      'result': phase,
    };
  }

  Map<String, Object?> _clipboardGet() {
    final clip = _latestClip?.call();
    if (clip == null) {
      return _failure('no_clip');
    }

    return {
      'ok': true,
      'text': clip.text,
      'from': clip.from,
      'at': clip.at.toUtc().toIso8601String(),
    };
  }

  Future<Map<String, Object?>> _clipboardSend(
    Map<String, Object?> arguments,
  ) async {
    final sendText = _sendText;
    if (sendText == null) {
      return _failure('not_supported');
    }

    final text = switch (arguments['text']) {
      final String text => text,
      _ => '',
    };
    if (text.isEmpty) {
      return _failure('nothing_to_send');
    }

    CliDevice? device;
    if (arguments['device'] != null) {
      final match = _match(arguments['device']);
      if (match case {'ok': false}) {
        return match;
      }

      device = _deviceOf(match);
    }

    final result = await sendText(text, device?.id);
    return {
      'ok': result == 'sent',
      'result': result,
      'device': ?device?.name,
    };
  }

  Future<Map<String, Object?>> _actionList(
    Map<String, Object?> arguments,
  ) async {
    final actionsOf = _actionsOf;
    if (actionsOf == null) {
      return _failure('not_supported');
    }

    final device = _connected(arguments['device']);
    if (device case {'ok': false}) {
      return device;
    }

    return {
      'ok': true,
      'device': device['device'],
      'actions': [
        for (final action in actionsOf('${device['id']}'))
          {'id': action.id, if (action.title.isNotEmpty) 'title': action.title},
      ],
    };
  }

  Future<Map<String, Object?>> _actionRun(
    Map<String, Object?> arguments,
  ) async {
    final actionsOf = _actionsOf;
    final runAction = _runAction;
    if (actionsOf == null || runAction == null) {
      return _failure('not_supported');
    }

    final device = _connected(arguments['device']);
    if (device case {'ok': false}) {
      return device;
    }

    final deviceId = '${device['id']}';
    final name = '${device['device']}';
    final wanted = '${arguments['action'] ?? ''}'.trim().toLowerCase();
    final offered = actionsOf(deviceId);
    final action =
        offered.where((action) => action.id == wanted).firstOrNull ??
        offered
            .where((action) => action.title.toLowerCase() == wanted)
            .firstOrNull;
    if (action == null) {
      return {
        ..._failure('unknown_action', device: name),
        'actions': [for (final action in offered) action.id],
      };
    }

    final outcome = await runAction(deviceId, action.id);
    return {
      'ok': outcome.result == 'done',
      'device': name,
      'action': action.id,
      'result': outcome.result,
      'exit_code': ?outcome.exitCode,
    };
  }

  Future<Map<String, Object?>> _open(Map<String, Object?> arguments) async {
    final openLink = _openLink;
    if (openLink == null) {
      return _failure('not_supported');
    }

    final link = '${arguments['link'] ?? ''}'.trim();
    if (link.isEmpty) {
      return _failure('not_a_link');
    }

    final device = _connected(arguments['device']);
    if (device case {'ok': false}) {
      return device;
    }

    final result = await openLink('${device['id']}', link);
    return {
      'ok': result == 'opened' || result == 'suggested',
      'device': device['device'],
      'result': result,
      if (result == 'not_a_link') 'error': result,
    };
  }

  Future<Map<String, Object?>> _notifyDevice(
    Map<String, Object?> arguments,
  ) async {
    final notify = _notify;
    if (notify == null) {
      return _failure('not_supported');
    }

    final title = '${arguments['title'] ?? ''}'.trim();
    final body = '${arguments['body'] ?? ''}'.trim();
    if (title.isEmpty && body.isEmpty) {
      return _failure('nothing_to_send');
    }

    final device = _connected(arguments['device']);
    if (device case {'ok': false}) {
      return device;
    }

    final result = await notify('${device['id']}', title, body);
    return {
      'ok': result == 'shown',
      'device': device['device'],
      'result': result,
    };
  }

  Future<Map<String, Object?>> _sendFilesTo(
    Map<String, Object?> arguments,
  ) async {
    final sendFiles = _sendFiles;
    if (sendFiles == null) {
      return _failure('not_supported');
    }

    final paths = switch (arguments['paths']) {
      final List<Object?> list => [
        for (final path in list)
          if (path case final String text when text.isNotEmpty) text,
      ],
      _ => const <String>[],
    };
    if (paths.isEmpty) {
      return _failure('nothing_to_send');
    }

    final device = _connected(arguments['device']);
    if (device case {'ok': false}) {
      return device;
    }

    final result = await sendFiles('${device['id']}', paths);
    if (result != 'sending') {
      return _failure(result, device: '${device['device']}');
    }

    return {'ok': true, 'device': device['device'], 'result': result};
  }

  /// The connected device named [query] as `{ok, id, device}`, or why not.
  Map<String, Object?> _connected(Object? query) {
    final match = _match(query);
    if (match case {'ok': false}) {
      return match;
    }

    final device = _deviceOf(match);
    if (device == null) {
      return _failure('unknown_device');
    }

    if (!device.isConnected) {
      return _failure('not_connected', device: device.name);
    }

    return {'ok': true, 'id': device.id, 'device': device.name};
  }

  /// Finds the device named [query]: by id, by its exact name, then by the
  /// start of its name, ignoring case.
  Map<String, Object?> _match(Object? query) {
    if (query is! String || query.trim().isEmpty) {
      return _failure('unknown_device');
    }

    final wanted = query.trim().toLowerCase();
    final compactId = wanted.replaceAll('-', '');
    final devices = _devices();
    final byId = devices.where(
      (device) => device.id.toLowerCase().replaceAll('-', '') == compactId,
    );
    final exact = devices.where(
      (device) => device.name.toLowerCase() == wanted,
    );
    final prefix = devices.where(
      (device) => device.name.toLowerCase().startsWith(wanted),
    );
    final found = switch ((byId.toList(), exact.toList(), prefix.toList())) {
      ([final device], _, _) => [device],
      (_, [final device], _) => [device],
      (_, [], final starts) => starts,
      (_, final named, _) => named,
    };

    return switch (found) {
      [] => _failure('unknown_device'),
      [final device] => {'ok': true, 'id': device.id},
      final several => {
        ..._failure('ambiguous_device'),
        'candidates': [for (final device in several) device.name],
      },
    };
  }

  CliDevice? _deviceOf(Map<String, Object?> match) {
    final id = match['id'];
    return _devices().where((device) => device.id == id).firstOrNull;
  }

  Future<Map<String, Object?>> _wakeDevice(
    Map<String, Object?> arguments,
  ) async {
    final wake = _wake;
    if (wake == null) {
      return _failure('not_supported');
    }

    final match = _match(arguments['device']);
    if (match case {'ok': false}) {
      return match;
    }

    final device = _deviceOf(match);
    if (device == null) {
      return _failure('unknown_device');
    }

    if (device.isConnected) {
      return _failure('already_connected', device: device.name);
    }

    final result = await wake(device.id);
    if (result != 'waking') {
      return _failure(result, device: device.name);
    }

    return {'ok': true, 'device': device.name, 'result': result};
  }

  /// Sends the magic packet for [deviceId]: `waking`, `no_wake_info` when
  /// it never said how to wake it, or `not_sent`.
  static Future<String> _wakeWith(
    WakeFeature wake,
    FerretEngine engine,
    String deviceId,
  ) async {
    final device = engine.trustStore[deviceId];
    if (device == null || !wake.canWake(device)) {
      return 'no_wake_info';
    }

    final attempt = await wake.wake(deviceId);
    return switch (attempt.phase) {
      .waking => 'waking',
      _ => 'not_sent',
    };
  }

  /// Asks [deviceId] to open [link]: `opened`, `suggested`, `failed`,
  /// `unreachable`, or `not_a_link` when it isn't a web or map link.
  static Future<String> _openWith(
    HandoffFeature handoff,
    String deviceId,
    String link,
  ) async {
    final activity = ActivityFactory.fromText(link);
    if (activity == null || activity.uri.isEmpty) {
      return 'not_a_link';
    }

    return (await handoff.sendTo(deviceId, activity)).name;
  }

  static Map<String, Object?> _failure(String error, {String? device}) => {
    'ok': false,
    'error': error,
    'device': ?device,
  };

  static Future<CliActionResult> _runOn(
    ActionsFeature actions,
    String deviceId,
    String actionId,
  ) async {
    final action = actions
        .actionsOf(deviceId)
        .where((action) => action.id == actionId)
        .firstOrNull;
    if (action == null) {
      return (result: 'unknown_action', exitCode: null);
    }

    final outgoing = await actions.run(deviceId, action);
    return (
      result: switch (outgoing?.result) {
        .RUN_RESULT_DONE => 'done',
        .RUN_RESULT_DENIED => 'denied',
        .RUN_RESULT_NOT_ANSWERED => 'not_answered',
        .RUN_RESULT_BUSY => 'busy',
        .RUN_RESULT_TURNED_OFF => 'turned_off',
        .RUN_RESULT_UNKNOWN_ACTION => 'unknown_action',
        .RUN_RESULT_CANCELLED => 'cancelled',
        .RUN_RESULT_TIMED_OUT => 'timed_out',
        _ => 'failed',
      },
      exitCode: outgoing?.exitCode,
    );
  }

  /// Private clips and images never leave through the command line.
  static CliClip? _latestReceived(ClipboardFeature clipboard) {
    for (final entry in clipboard.history) {
      final isText = !entry.isImage && entry.item.text.isNotEmpty;
      if (entry.direction != .received || entry.isSensitive) {
        continue;
      }

      if (!entry.hasContent || !isText) {
        continue;
      }

      return (
        text: entry.item.text,
        from: entry.deviceNames.firstOrNull ?? '',
        at: entry.at,
      );
    }

    return null;
  }
}
