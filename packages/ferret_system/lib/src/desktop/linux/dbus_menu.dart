import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:ferret_system/src/desktop/tray_menu_item.dart';

/// The tray icon's menu, as `com.canonical.dbusmenu`: the panel asks for
/// the layout and reports clicks. Item ids are the items' places plus one;
/// 0 is the root.
class DBusMenu extends DBusObject {
  DBusMenu() : super(DBusObjectPath(objectPath));

  static const objectPath = '/MenuBar';
  static const interface = 'com.canonical.dbusmenu';

  final StreamController<String> _selections = .broadcast();
  List<TrayMenuItem> _items = const [];
  int _revision = 1;

  /// The id of the line that was clicked.
  Stream<String> get selections => _selections.stream;

  List<TrayMenuItem> get items => _items;

  /// Replaces the menu and tells the panel to fetch it again.
  Future<void> setItems(List<TrayMenuItem> items) async {
    _items = List.unmodifiable(items);
    _revision++;
    if (client == null) {
      return;
    }

    await emitSignal(interface, 'LayoutUpdated', [
      DBusUint32(_revision),
      const DBusInt32(0),
    ]);
  }

  Future<void> dispose() => _selections.close();

  Map<String, DBusValue> get _properties => {
    'Version': const DBusUint32(3),
    'TextDirection': const DBusString('ltr'),
    'Status': const DBusString('normal'),
    'IconThemePath': DBusArray.string(const []),
  };

  @override
  List<DBusIntrospectInterface> introspect() => [
    DBusIntrospectInterface(
      interface,
      methods: [
        DBusIntrospectMethod(
          'GetLayout',
          args: [
            DBusIntrospectArgument(DBusSignature('i'), .in_),
            DBusIntrospectArgument(DBusSignature('i'), .in_),
            DBusIntrospectArgument(DBusSignature('as'), .in_),
            DBusIntrospectArgument(DBusSignature('u'), .out),
            DBusIntrospectArgument(DBusSignature('(ia{sv}av)'), .out),
          ],
        ),
        DBusIntrospectMethod(
          'GetGroupProperties',
          args: [
            DBusIntrospectArgument(DBusSignature('ai'), .in_),
            DBusIntrospectArgument(DBusSignature('as'), .in_),
            DBusIntrospectArgument(DBusSignature('a(ia{sv})'), .out),
          ],
        ),
        DBusIntrospectMethod(
          'GetProperty',
          args: [
            DBusIntrospectArgument(DBusSignature('i'), .in_),
            DBusIntrospectArgument(DBusSignature('s'), .in_),
            DBusIntrospectArgument(DBusSignature('v'), .out),
          ],
        ),
        DBusIntrospectMethod(
          'Event',
          args: [
            DBusIntrospectArgument(DBusSignature('i'), .in_),
            DBusIntrospectArgument(DBusSignature('s'), .in_),
            DBusIntrospectArgument(DBusSignature('v'), .in_),
            DBusIntrospectArgument(DBusSignature('u'), .in_),
          ],
        ),
        DBusIntrospectMethod(
          'EventGroup',
          args: [
            DBusIntrospectArgument(DBusSignature('a(isvu)'), .in_),
            DBusIntrospectArgument(DBusSignature('ai'), .out),
          ],
        ),
        DBusIntrospectMethod(
          'AboutToShow',
          args: [
            DBusIntrospectArgument(DBusSignature('i'), .in_),
            DBusIntrospectArgument(DBusSignature('b'), .out),
          ],
        ),
        DBusIntrospectMethod(
          'AboutToShowGroup',
          args: [
            DBusIntrospectArgument(DBusSignature('ai'), .in_),
            DBusIntrospectArgument(DBusSignature('ai'), .out),
            DBusIntrospectArgument(DBusSignature('ai'), .out),
          ],
        ),
      ],
      signals: [
        DBusIntrospectSignal(
          'LayoutUpdated',
          args: [
            DBusIntrospectArgument(DBusSignature('u'), .out),
            DBusIntrospectArgument(DBusSignature('i'), .out),
          ],
        ),
        DBusIntrospectSignal(
          'ItemsPropertiesUpdated',
          args: [
            DBusIntrospectArgument(DBusSignature('a(ia{sv})'), .out),
            DBusIntrospectArgument(DBusSignature('a(ias)'), .out),
          ],
        ),
      ],
      properties: [
        DBusIntrospectProperty('Version', DBusSignature('u'), access: .read),
        DBusIntrospectProperty(
          'TextDirection',
          DBusSignature('s'),
          access: .read,
        ),
        DBusIntrospectProperty('Status', DBusSignature('s'), access: .read),
        DBusIntrospectProperty(
          'IconThemePath',
          DBusSignature('as'),
          access: .read,
        ),
      ],
    ),
  ];

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != interface) {
      return DBusMethodErrorResponse.unknownInterface();
    }

    final values = methodCall.values;
    switch (methodCall.name) {
      case 'GetLayout':
        return DBusMethodSuccessResponse([DBusUint32(_revision), _layout()]);
      case 'GetGroupProperties':
        final ids = switch (values.firstOrNull) {
          final DBusArray array => array.children.map(
            (value) => value.asInt32(),
          ),
          _ => const <int>[],
        };
        return DBusMethodSuccessResponse([
          DBusArray(DBusSignature('(ia{sv})'), [
            for (final id in ids)
              if (_propertiesOf(id) case final properties?)
                DBusStruct([DBusInt32(id), DBusDict.stringVariant(properties)]),
          ]),
        ]);
      case 'GetProperty':
        final id = values[0].asInt32();
        final name = values[1].asString();
        final value = _propertiesOf(id)?[name];
        if (value == null) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse([DBusVariant(value)]);
      case 'Event':
        _onEvent(values[0].asInt32(), values[1].asString());
        return DBusMethodSuccessResponse();
      case 'EventGroup':
        for (final event in values[0].asArray()) {
          final fields = event.asStruct();
          _onEvent(fields[0].asInt32(), fields[1].asString());
        }
        return DBusMethodSuccessResponse([DBusArray.int32(const [])]);
      case 'AboutToShow':
        return DBusMethodSuccessResponse([const DBusBoolean(false)]);
      case 'AboutToShowGroup':
        return DBusMethodSuccessResponse([
          DBusArray.int32(const []),
          DBusArray.int32(const []),
        ]);
    }

    return DBusMethodErrorResponse.unknownMethod();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    final value = switch (interface == DBusMenu.interface) {
      true => _properties[name],
      false => null,
    };
    if (value == null) {
      return DBusMethodErrorResponse.unknownProperty();
    }

    return DBusGetPropertyResponse(value);
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    if (interface != DBusMenu.interface) {
      return DBusGetAllPropertiesResponse(const {});
    }

    return DBusGetAllPropertiesResponse(_properties);
  }

  void _onEvent(int id, String eventId) {
    if (eventId != 'clicked' || id < 1 || id > _items.length) {
      return;
    }

    final item = _items[id - 1];
    if (item.separator || !item.enabled) {
      return;
    }

    _selections.add(item.id);
  }

  DBusStruct _layout() => DBusStruct([
    const DBusInt32(0),
    DBusDict.stringVariant(const {'children-display': DBusString('submenu')}),
    DBusArray.variant([
      for (final (index, _) in _items.indexed)
        if (_propertiesOf(index + 1) case final properties?)
          DBusStruct([
            DBusInt32(index + 1),
            DBusDict.stringVariant(properties),
            DBusArray.variant(const []),
          ]),
    ]),
  ]);

  Map<String, DBusValue>? _propertiesOf(int id) {
    if (id == 0) {
      return const {'children-display': DBusString('submenu')};
    }

    if (id < 1 || id > _items.length) {
      return null;
    }

    final item = _items[id - 1];
    if (item.separator) {
      return const {'type': DBusString('separator')};
    }

    return {
      'label': DBusString(item.title.replaceAll('_', '__')),
      'enabled': DBusBoolean(item.enabled),
      'visible': const DBusBoolean(true),
    };
  }
}
