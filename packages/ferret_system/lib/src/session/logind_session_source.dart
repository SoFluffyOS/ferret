import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:ferret_system/src/session/screen_session_source.dart';

/// Linux: systemd-logind says whether this session is the one in front
/// (`Active`) and whether its screen is locked (`LockedHint`, set by the
/// GNOME and KDE lock screens). Without logind, always active.
class LogindSessionSource implements ScreenSessionSource {
  LogindSessionSource({DBusClient Function()? connect})
    : _connect = connect ?? DBusClient.system;

  static const _service = 'org.freedesktop.login1';
  static const _sessionInterface = 'org.freedesktop.login1.Session';

  final DBusClient Function() _connect;
  final StreamController<bool> _changes = .broadcast();
  DBusClient? _client;
  DBusRemoteObject? _session;
  StreamSubscription<DBusPropertiesChangedSignal>? _subscription;
  bool _active = true;
  bool _locked = false;

  /// In front and unlocked.
  static bool activeFrom({required bool active, required bool locked}) =>
      active && !locked;

  @override
  Future<bool> isActive() async {
    final session = await _open();
    if (session == null) {
      return true;
    }

    await _read(session);
    return activeFrom(active: _active, locked: _locked);
  }

  @override
  Stream<bool> get changes => _changes.stream;

  @override
  Future<void> start() async {
    final session = await _open();
    if (session == null || _subscription != null) {
      return;
    }

    _subscription = session.propertiesChanged
        .where((signal) => signal.propertiesInterface == _sessionInterface)
        .listen((_) => unawaited(_onChanged(session)));
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _client?.close();
    _client = null;
    _session = null;
  }

  Future<void> _onChanged(DBusRemoteObject session) async {
    await _read(session);
    _changes.add(activeFrom(active: _active, locked: _locked));
  }

  Future<void> _read(DBusRemoteObject session) async {
    try {
      final active = await session.getProperty(_sessionInterface, 'Active');
      final locked = await session.getProperty(_sessionInterface, 'LockedHint');
      _active = active.asBoolean();
      _locked = locked.asBoolean();
    } on Object {
      return;
    }
  }

  /// Signals come from the session's own path, so `session/auto` is only
  /// used to find it.
  Future<DBusRemoteObject?> _open() async {
    if (_session case final session?) {
      return session;
    }

    try {
      final client = _client ??= _connect();
      final auto = DBusRemoteObject(
        client,
        name: _service,
        path: DBusObjectPath('/org/freedesktop/login1/session/auto'),
      );
      final id = (await auto.getProperty(_sessionInterface, 'Id')).asString();
      final manager = DBusRemoteObject(
        client,
        name: _service,
        path: DBusObjectPath('/org/freedesktop/login1'),
      );
      final found = await manager.callMethod(
        'org.freedesktop.login1.Manager',
        'GetSession',
        [DBusString(id)],
        replySignature: DBusSignature('o'),
      );
      final session = DBusRemoteObject(
        client,
        name: _service,
        path: found.values.first.asObjectPath(),
      );
      _session = session;
      return session;
    } on Object {
      return null;
    }
  }
}
