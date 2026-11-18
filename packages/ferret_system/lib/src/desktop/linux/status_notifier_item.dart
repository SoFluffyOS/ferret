import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:ferret_system/src/desktop/linux/dbus_menu.dart';

/// The tray icon as `org.kde.StatusNotifierItem`, the protocol KDE Plasma,
/// Xfce, Cinnamon, MATE, waybar and GNOME's AppIndicator extension show.
class StatusNotifierItem extends DBusObject {
  StatusNotifierItem({required this.iconName})
    : super(DBusObjectPath(objectPath));

  static const objectPath = '/StatusNotifierItem';
  static const interface = 'org.kde.StatusNotifierItem';

  /// A name from the icon theme.
  final String iconName;

  final StreamController<void> _activations = .broadcast();
  String _tooltip = '';

  /// A click on the icon (not its menu).
  Stream<void> get activations => _activations.stream;

  Future<void> setTooltip(String tooltip) async {
    if (tooltip == _tooltip) {
      return;
    }

    _tooltip = tooltip;
    if (client == null) {
      return;
    }

    await emitSignal(interface, 'NewToolTip', const []);
  }

  Future<void> dispose() => _activations.close();

  Map<String, DBusValue> get _properties => {
    'Category': const DBusString('Communications'),
    'Id': const DBusString('io.sofluffy.ferret'),
    'Title': const DBusString('Ferret'),
    'Status': const DBusString('Active'),
    'WindowId': const DBusInt32(0),
    'IconName': DBusString(iconName),
    'IconPixmap': DBusArray(DBusSignature('(iiay)'), const []),
    'OverlayIconName': const DBusString(''),
    'AttentionIconName': const DBusString(''),
    'ToolTip': DBusStruct([
      DBusString(iconName),
      DBusArray(DBusSignature('(iiay)'), const []),
      const DBusString('Ferret'),
      DBusString(_tooltip),
    ]),
    'ItemIsMenu': const DBusBoolean(false),
    'Menu': DBusObjectPath(DBusMenu.objectPath),
  };

  static const _signatures = {
    'Category': 's',
    'Id': 's',
    'Title': 's',
    'Status': 's',
    'WindowId': 'i',
    'IconName': 's',
    'IconPixmap': 'a(iiay)',
    'OverlayIconName': 's',
    'AttentionIconName': 's',
    'ToolTip': '(sa(iiay)ss)',
    'ItemIsMenu': 'b',
    'Menu': 'o',
  };

  @override
  List<DBusIntrospectInterface> introspect() => [
    DBusIntrospectInterface(
      interface,
      methods: [
        for (final name in ['ContextMenu', 'Activate', 'SecondaryActivate'])
          DBusIntrospectMethod(
            name,
            args: [
              DBusIntrospectArgument(DBusSignature('i'), .in_),
              DBusIntrospectArgument(DBusSignature('i'), .in_),
            ],
          ),
        DBusIntrospectMethod(
          'Scroll',
          args: [
            DBusIntrospectArgument(DBusSignature('i'), .in_),
            DBusIntrospectArgument(DBusSignature('s'), .in_),
          ],
        ),
      ],
      signals: [
        DBusIntrospectSignal('NewIcon'),
        DBusIntrospectSignal('NewToolTip'),
        DBusIntrospectSignal(
          'NewStatus',
          args: [DBusIntrospectArgument(DBusSignature('s'), .out)],
        ),
      ],
      properties: [
        for (final MapEntry(key: name, value: signature) in _signatures.entries)
          DBusIntrospectProperty(name, DBusSignature(signature), access: .read),
      ],
    ),
  ];

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != interface) {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      case 'Activate':
        _activations.add(null);
        return DBusMethodSuccessResponse();
      case 'ContextMenu' || 'SecondaryActivate' || 'Scroll':
        return DBusMethodSuccessResponse();
    }

    return DBusMethodErrorResponse.unknownMethod();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    final value = switch (interface == StatusNotifierItem.interface) {
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
    if (interface != StatusNotifierItem.interface) {
      return DBusGetAllPropertiesResponse(const {});
    }

    return DBusGetAllPropertiesResponse(_properties);
  }
}
