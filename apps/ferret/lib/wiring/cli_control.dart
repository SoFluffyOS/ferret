import 'package:clipboard/clipboard.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:find/find.dart';

/// A paired device as `ferret-cli` names it.
typedef CliDevice = ({String id, String name, bool isConnected});

/// The last clip that arrived from another device, as `ferret-cli
/// clipboard get` prints it.
typedef CliClip = ({String text, String from, DateTime at});

/// Answers `ferret-cli ring` and `ferret-cli clipboard` from the running
/// app. Find and Clipboard never import each other, so the app joins them
/// here.
class CliControl {
  CliControl({
    required List<CliDevice> Function() devices,
    Future<String> Function(String deviceId)? ring,
    CliClip? Function()? latestClip,
    Future<String> Function(String text, String? deviceId)? sendText,
  }) : _devices = devices,
       _ring = ring,
       _latestClip = latestClip,
       _sendText = sendText;

  final List<CliDevice> Function() _devices;
  final Future<String> Function(String deviceId)? _ring;
  final CliClip? Function()? _latestClip;
  final Future<String> Function(String text, String? deviceId)? _sendText;

  static const String ringCommand = 'ring';
  static const String clipboardGetCommand = 'clipboard_get';
  static const String clipboardSendCommand = 'clipboard_send';

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
    await server.listen(control.handle);
    return server;
  }

  factory CliControl.forEngine(FerretEngine engine) {
    final find = engine.feature<FindFeature>();
    final clipboard = engine.feature<ClipboardFeature>();

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
    );
  }

  Future<Map<String, Object?>> handle(
    String command,
    Map<String, Object?> arguments,
  ) async => switch (command) {
    ringCommand => _ringDevice(arguments),
    clipboardGetCommand => _clipboardGet(),
    clipboardSendCommand => _clipboardSend(arguments),
    _ => _failure('unknown_command'),
  };

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

  static Map<String, Object?> _failure(String error, {String? device}) => {
    'ok': false,
    'error': error,
    'device': ?device,
  };

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
