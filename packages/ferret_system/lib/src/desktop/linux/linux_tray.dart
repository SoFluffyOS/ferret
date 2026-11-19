import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:ferret_system/src/desktop/desktop_tray.dart';
import 'package:ferret_system/src/desktop/linux/dbus_menu.dart';
import 'package:ferret_system/src/desktop/linux/status_notifier_item.dart';
import 'package:ferret_system/src/desktop/tray_menu_item.dart';

/// The Linux tray icon, spoken over the session bus in Dart, so it needs no
/// library at build time and works inside a Flatpak that may talk to
/// `org.kde.StatusNotifierWatcher`.
///
/// Without a watcher on the bus (stock GNOME) [show] returns false. When the
/// panel restarts, the icon registers again.
class LinuxTray implements DesktopTray {
  LinuxTray({
    DBusClient Function()? connect,
    Map<String, String>? environment,
    Future<bool> Function(String path)? fileExists,
    String? executable,
  }) : _connect = connect ?? DBusClient.session,
       _environment = environment ?? Platform.environment,
       _fileExists = fileExists ?? ((path) => File(path).exists()),
       _executable = executable ?? Platform.resolvedExecutable;

  static const watcherName = 'org.kde.StatusNotifierWatcher';
  static const _watcherPath = '/StatusNotifierWatcher';
  static const appIcon = 'io.sofluffy.ferret';

  /// Shown when the app's icon is neither installed nor next to the
  /// binary.
  static const fallbackIcon = 'phone-symbolic';

  static final _iconFiles = [
    'scalable/apps/$appIcon.svg',
    for (final size in [512, 256, 128, 64, 48, 32, 24, 16])
      '${size}x$size/apps/$appIcon.png',
  ];

  final DBusClient Function() _connect;
  final Map<String, String> _environment;
  final Future<bool> Function(String path) _fileExists;
  final String _executable;
  final DBusMenu _menu = DBusMenu();
  final StreamController<void> _activations = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  DBusClient? _client;
  StatusNotifierItem? _item;
  String? _busName;

  @override
  Stream<void> get activations => _activations.stream;

  @override
  Stream<String> get selections => _menu.selections;

  @override
  Future<bool> show({
    required String tooltip,
    required List<TrayMenuItem> items,
  }) async {
    await _menu.setItems(items);
    if (_item case final item?) {
      await item.setTooltip(tooltip);
      return true;
    }

    final client = await _open();
    if (client == null || !await _hasWatcher(client)) {
      return false;
    }

    final (:name, :themePath) = await _icon();
    final item = StatusNotifierItem(iconName: name, iconThemePath: themePath);
    await item.setTooltip(tooltip);
    try {
      _busName = await _claimName(client);
      await client.registerObject(item);
      await client.registerObject(_menu);
      _item = item;
      _subscriptions
        ..add(item.activations.listen(_activations.add))
        ..add(
          client.nameOwnerChanged
              .where((event) => event.name == watcherName)
              .where((event) => event.newOwner != null)
              .listen((_) => unawaited(_register(client))),
        );
      return await _register(client);
    } on Object {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _item?.dispose();
    await _menu.dispose();
    await _activations.close();
    await _client?.close();
    _client = null;
  }

  Future<DBusClient?> _open() async {
    if (_client case final client?) {
      return client;
    }

    try {
      final client = _connect();
      _client = client;
      return client;
    } on Object {
      return null;
    }
  }

  /// The well-known name the spec suggests. A Flatpak may not own it, and
  /// the watcher takes the connection's unique name just as well.
  Future<String> _claimName(DBusClient client) async {
    final wellKnown = 'org.kde.StatusNotifierItem-$pid-1';
    try {
      final reply = await client.requestName(
        wellKnown,
        flags: {.doNotQueue},
      );
      if (reply == .primaryOwner || reply == .alreadyOwner) {
        return wellKnown;
      }
    } on Object {
      return client.uniqueName;
    }

    return client.uniqueName;
  }

  Future<bool> _hasWatcher(DBusClient client) async {
    try {
      return await client.nameHasOwner(watcherName);
    } on Object {
      return false;
    }
  }

  Future<bool> _register(DBusClient client) async {
    try {
      await client.callMethod(
        destination: watcherName,
        path: DBusObjectPath(_watcherPath),
        interface: watcherName,
        name: 'RegisterStatusNotifierItem',
        values: [DBusString(_busName ?? '')],
        replySignature: DBusSignature(''),
      );
      return true;
    } on Object {
      return false;
    }
  }

  /// The installed `io.sofluffy.ferret` icon, so the tray matches the
  /// launcher. A bundle that isn't installed (a build folder, an AppImage)
  /// carries the same icons in `data/icons`, and the panel is told to look
  /// there. Otherwise a phone from the user's own icon theme.
  Future<({String name, String themePath})> _icon() async {
    final home = _environment['HOME'] ?? '';
    final dataDirs =
        (_environment['XDG_DATA_DIRS'] ?? '/usr/local/share:/usr/share')
            .split(':')
            .where((directory) => directory.isNotEmpty);
    final installed = [
      '${_environment['XDG_DATA_HOME'] ?? '$home/.local/share'}/icons',
      for (final directory in dataDirs) '$directory/icons',
    ];
    for (final icons in installed) {
      if (await _hasAppIcon(icons)) {
        return (name: appIcon, themePath: '');
      }
    }

    final bundled = '${File(_executable).parent.path}/data/icons';
    if (await _hasAppIcon(bundled)) {
      return (name: appIcon, themePath: bundled);
    }

    return (name: fallbackIcon, themePath: '');
  }

  Future<bool> _hasAppIcon(String icons) async {
    for (final file in _iconFiles) {
      if (await _fileExists('$icons/hicolor/$file')) {
        return true;
      }
    }

    return false;
  }
}
