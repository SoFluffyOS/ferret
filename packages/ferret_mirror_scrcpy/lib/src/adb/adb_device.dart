/// Where a device stands with this computer's adb.
enum AdbDeviceState {
  /// Ready: debugging is on and this computer is allowed.
  ready,

  /// The device shows "Allow USB debugging?" and nobody said yes yet.
  unauthorized,

  /// Known to adb, but not answering right now.
  offline,
}

/// One line of `adb devices -l`.
class AdbDevice {
  const AdbDevice({required this.serial, required this.state, this.model});

  static final RegExp _addressSerial = RegExp(r'^(\[.+\]|[^:]+):\d+$');
  static const String _mdnsMarker = '._adb-tls-connect._tcp';

  final String serial;
  final AdbDeviceState state;

  /// The model as adb gives it, with `_` for spaces. Null before the
  /// computer is allowed.
  final String? model;

  /// A name to show: the model, or the serial without one.
  String get name => model?.replaceAll('_', ' ') ?? serial;

  /// Reached over the network: its serial is an address (`192.168.1.20:5555`)
  /// or a wireless debugging service name.
  bool get isWireless =>
      _addressSerial.hasMatch(serial) || serial.contains(_mdnsMarker);

  /// Reads the output of `adb devices -l`. Lines that aren't devices (the
  /// header, daemon notices) are left out.
  static List<AdbDevice> parseList(String output) {
    final devices = <AdbDevice>[];
    for (final line in output.split('\n')) {
      if (_parseLine(line.trim()) case final device?) {
        devices.add(device);
      }
    }

    return devices;
  }

  static AdbDevice? _parseLine(String line) {
    final fields = line.split(RegExp(r'\s+'));
    if (fields.length < 2 || line.startsWith('*')) {
      return null;
    }

    final state = _stateOf(fields[1]);
    if (state == null) {
      return null;
    }

    return AdbDevice(
      serial: fields[0],
      state: state,
      model: _valueOf(fields, 'model:'),
    );
  }

  static AdbDeviceState? _stateOf(String word) {
    return switch (word) {
      'device' => .ready,
      'unauthorized' || 'authorizing' => .unauthorized,
      'offline' || 'connecting' => .offline,
      _ => null,
    };
  }

  static String? _valueOf(List<String> fields, String prefix) {
    for (final field in fields.skip(2)) {
      if (field.startsWith(prefix)) {
        return field.substring(prefix.length);
      }
    }

    return null;
  }
}
