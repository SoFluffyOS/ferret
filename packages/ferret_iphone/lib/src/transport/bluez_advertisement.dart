import 'package:dbus/dbus.dart';
import 'package:ferret_iphone/src/transport/apple_characteristic.dart';

/// The Bluetooth LE advertisement BlueZ sends while this computer invites an
/// iPhone: it asks for ANCS (a "service solicitation"), which is what makes
/// iOS list the computer under Bluetooth and reconnect to it later.
class BluezAdvertisement extends DBusObject {
  BluezAdvertisement()
    : super(DBusObjectPath('/io/sofluffy/ferret/iphone/advertisement'));

  static const interface = 'org.bluez.LEAdvertisement1';

  Map<String, DBusValue> get _properties => {
    'Type': const DBusString('peripheral'),
    'SolicitUUIDs': DBusArray.string([AppleService.ancs.uuid.toLowerCase()]),
    'Includes': DBusArray.string(const ['local-name']),
    'Discoverable': const DBusBoolean(true),
  };

  @override
  List<DBusIntrospectInterface> introspect() => [
    DBusIntrospectInterface(
      interface,
      methods: [DBusIntrospectMethod('Release')],
      properties: [
        DBusIntrospectProperty('Type', DBusSignature('s'), access: .read),
        DBusIntrospectProperty(
          'SolicitUUIDs',
          DBusSignature('as'),
          access: .read,
        ),
        DBusIntrospectProperty('Includes', DBusSignature('as'), access: .read),
        DBusIntrospectProperty(
          'Discoverable',
          DBusSignature('b'),
          access: .read,
        ),
      ],
    ),
  ];

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != interface || methodCall.name != 'Release') {
      return DBusMethodErrorResponse.unknownMethod();
    }

    return DBusMethodSuccessResponse();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    final value = switch (interface == BluezAdvertisement.interface) {
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
    if (interface != BluezAdvertisement.interface) {
      return DBusGetAllPropertiesResponse(const {});
    }

    return DBusGetAllPropertiesResponse(_properties);
  }
}
