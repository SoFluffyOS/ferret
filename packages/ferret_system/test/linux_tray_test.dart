import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWatcher extends DBusObject {
  _FakeWatcher() : super(DBusObjectPath('/StatusNotifierWatcher'));

  final List<String> registered = [];

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.name == 'RegisterStatusNotifierItem') {
      registered.add(methodCall.values.first.asString());
    }

    return DBusMethodSuccessResponse();
  }
}

void main() {
  late Directory directory;
  late DBusServer server;
  late DBusAddress address;
  final clients = <DBusClient>[];

  DBusClient client() {
    final client = DBusClient(
      address,
      authClient: DBusAuthClient(uid: '1000', requestUnixFd: false),
    );
    clients.add(client);
    return client;
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('fake-session-bus');
    server = DBusServer();
    address = await server.listenAddress(DBusAddress.unix(dir: directory));
  });

  tearDown(() async {
    for (final client in clients) {
      await client.close();
    }
    clients.clear();
    await server.close();
    await directory.delete(recursive: true);
  });

  const items = [
    TrayMenuItem(id: 'open', title: 'Open Ferret'),
    TrayMenuItem.separator(),
    TrayMenuItem(id: 'clipboard', title: 'Send clipboard', enabled: false),
    TrayMenuItem(id: 'quit', title: 'Quit'),
  ];

  LinuxTray tray({Set<String> files = const {}}) => LinuxTray(
    connect: client,
    environment: const {'HOME': '/home/someone'},
    fileExists: (path) async => files.contains(path),
    executable: '/opt/ferret/ferret',
  );

  test('without a watcher, as on stock GNOME, there is no tray', () async {
    final linux = tray();
    addTearDown(linux.dispose);

    expect(await linux.show(tooltip: 'Ferret', items: items), isFalse);
  });

  test('a watcher that starts later, as the AppIndicator extension can at '
      'login, gets the icon, and one that leaves is reported', () async {
    final linux = tray();
    addTearDown(linux.dispose);
    final changes = <bool>[];
    linux.presence.listen(changes.add);

    expect(await linux.show(tooltip: 'Ferret', items: items), isFalse);

    final panel = client();
    final watcher = _FakeWatcher();
    await panel.registerObject(watcher);
    await panel.requestName(LinuxTray.watcherName);
    await _until(() => changes.isNotEmpty);

    expect(changes, [true]);
    expect(watcher.registered, hasLength(1));
    expect(await linux.show(tooltip: 'Ferret', items: items), isTrue);

    await panel.releaseName(LinuxTray.watcherName);
    await _until(() => changes.length > 1);

    expect(changes, [true, false]);
    expect(await linux.show(tooltip: 'Ferret', items: items), isFalse);
  });

  group('with a watcher', () {
    late _FakeWatcher watcher;
    late DBusClient panel;

    setUp(() async {
      panel = client();
      await panel.requestName(LinuxTray.watcherName);
      watcher = _FakeWatcher();
      await panel.registerObject(watcher);
    });

    Future<DBusMethodSuccessResponse> callItem(
      String path,
      String interface,
      String name,
      List<DBusValue> values,
    ) => panel.callMethod(
      destination: watcher.registered.single,
      path: DBusObjectPath(path),
      interface: interface,
      name: name,
      values: values,
    );

    test('the icon registers, and a click on it is reported', () async {
      final linux = tray();
      addTearDown(linux.dispose);
      final clicks = linux.activations.first;

      expect(await linux.show(tooltip: 'Ferret', items: items), isTrue);
      expect(
        watcher.registered.single,
        startsWith('org.kde.StatusNotifierItem-'),
      );

      await callItem(
        StatusNotifierItem.objectPath,
        StatusNotifierItem.interface,
        'Activate',
        const [DBusInt32(0), DBusInt32(0)],
      );
      await clicks;
    });

    Future<(String, String)> iconOf(LinuxTray linux) async {
      await linux.show(tooltip: 'Ferret', items: items);
      final properties = await panel.callMethod(
        destination: watcher.registered.single,
        path: DBusObjectPath(StatusNotifierItem.objectPath),
        interface: 'org.freedesktop.DBus.Properties',
        name: 'GetAll',
        values: const [DBusString(StatusNotifierItem.interface)],
      );
      final values = properties.returnValues.single.asStringVariantDict();
      return (
        values['IconName']?.asString() ?? '',
        values['IconThemePath']?.asString() ?? '',
      );
    }

    test('when the well-known name is taken, the item registers under its '
        'unique name', () async {
      final other = client();
      await other.requestName('org.kde.StatusNotifierItem-$pid-1');
      final linux = tray();
      addTearDown(linux.dispose);

      expect(await linux.show(tooltip: 'Ferret', items: items), isTrue);
      expect(watcher.registered.single, startsWith(':'));
    });

    test('an installed icon is shown by its name', () async {
      final linux = tray(
        files: {'/usr/share/icons/hicolor/48x48/apps/io.sofluffy.ferret.png'},
      );
      addTearDown(linux.dispose);

      expect(await iconOf(linux), ('io.sofluffy.ferret', ''));
    });

    test('a bundle that is not installed points the panel at its own '
        'icons', () async {
      final linux = tray(
        files: {
          '/opt/ferret/data/icons/hicolor/scalable/apps/io.sofluffy.ferret.svg',
        },
      );
      addTearDown(linux.dispose);

      expect(await iconOf(linux), (
        'io.sofluffy.ferret',
        '/opt/ferret/data/icons',
      ));
    });

    test('with no icon anywhere, a phone from the theme stands in', () async {
      final linux = tray();
      addTearDown(linux.dispose);

      expect(await iconOf(linux), ('phone-symbolic', ''));
    });

    test('the panel reads the menu, and a click names the line', () async {
      final linux = tray();
      addTearDown(linux.dispose);
      await linux.show(tooltip: 'Ferret', items: items);
      final picked = linux.selections.first;

      final layout = await callItem(
        DBusMenu.objectPath,
        DBusMenu.interface,
        'GetLayout',
        [const DBusInt32(0), const DBusInt32(-1), DBusArray.string(const [])],
      );
      final children = layout.returnValues[1].asStruct()[2].asArray();
      final labels = [
        for (final child in children)
          child
              .asVariant()
              .asStruct()[1]
              .asStringVariantDict()['label']
              ?.asString(),
      ];
      expect(labels, ['Open Ferret', null, 'Send clipboard', 'Quit']);

      await callItem(DBusMenu.objectPath, DBusMenu.interface, 'Event', [
        const DBusInt32(3),
        const DBusString('clicked'),
        const DBusVariant(DBusString('')),
        const DBusUint32(0),
      ]);
      await callItem(DBusMenu.objectPath, DBusMenu.interface, 'Event', [
        const DBusInt32(4),
        const DBusString('clicked'),
        const DBusVariant(DBusString('')),
        const DBusUint32(0),
      ]);

      expect(await picked, 'quit');
    });

    test('the tooltip and menu follow later calls without registering '
        'again', () async {
      final linux = tray();
      addTearDown(linux.dispose);
      await linux.show(tooltip: 'Ferret', items: items);

      expect(
        await linux.show(
          tooltip: 'Connected to Pixel 9',
          items: const [TrayMenuItem(id: 'open', title: 'Open Ferret')],
        ),
        isTrue,
      );
      expect(watcher.registered, hasLength(1));

      final tooltip = await panel.callMethod(
        destination: watcher.registered.single,
        path: DBusObjectPath(StatusNotifierItem.objectPath),
        interface: 'org.freedesktop.DBus.Properties',
        name: 'Get',
        values: const [
          DBusString(StatusNotifierItem.interface),
          DBusString('ToolTip'),
        ],
      );
      expect(
        tooltip.returnValues.single.asVariant().asStruct()[3].asString(),
        'Connected to Pixel 9',
      );
    });
  });
}

Future<void> _until(bool Function() done) async {
  for (var tries = 0; tries < 100 && !done(); tries++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
