# ferret_iphone

Talks to an iPhone from a desktop over the Bluetooth LE services every iPhone offers a paired device. No app on the iPhone. Part of [Ferret](../../README.md), usable on its own.

- **ANCS** (Apple Notification Center Service): notifications as they come and go, their text, the app's name, and their positive and negative actions.
- **AMS** (Apple Media Service): what plays, where it is, and play, pause, next, previous and volume.

```dart
final transport = AppleTransport.current();
if (await transport.status() != BluetoothStatus.ready) {
  return;
}

final iphone = (await transport.devices()).first;
final services = await transport.connect(iphone.id);

if (services.hasAncs) {
  final ancs = AncsClient(transport);
  ancs.events.where((event) => !event.isPreExisting).listen((event) async {
    if (event.kind == AncsEventKind.removed) {
      return;
    }

    final notification = await ancs.fetch(event);
    final app = await ancs.appName(notification.appId);
    // Show it. Later: ancs.perform(notification.uid, AncsAction.negative).
  });
  await ancs.start();
}

if (services.hasAms) {
  final ams = AmsClient(transport);
  ams.states.listen((state) {
    // state.title, state.artist, state.positionAt(DateTime.now())
  });
  await ams.start();
  await ams.send(AmsCommand.togglePlayPause);
}
```

The byte formats (`AncsEvent`, `AncsCommands`, `AncsResponseAssembler`, `AmsUpdate`, `AmsCommands`, `AmsState`) are plain Dart and follow Apple's ANCS and AMS specifications. `AppleTransport` is the only platform part.

| Platform | Transport | State |
|---|---|---|
| Linux | `BluezTransport`: BlueZ over the system D-Bus, in Dart. Can advertise an ANCS solicitation (`setInviting`) so the iPhone lists the computer and reconnects by itself | Tested against a simulated BlueZ, not yet against a real iPhone |
| Windows | `PigeonTransport` over a C++/WinRT GATT client (`windows/apple_gatt_client.cpp`) | Written against the WinRT documentation; not yet compiled or run |
| macOS | `PigeonTransport` over CoreBluetooth (`macos/.../AppleGattCentral.swift`) | Builds. Only sees an iPhone that macOS itself is connected to, and macOS may keep ANCS to itself; not yet confirmed against a real iPhone |
| Android, iOS | `UnsupportedTransport` | Not applicable |

The iPhone only shows these services to a device it is **bonded** with, and ANCS also needs **Share System Notifications** turned on for that device in the iPhone's Bluetooth settings. Without it, `connect` returns no services or subscribing throws `GattException(GattFailure.notBonded)`.

## macOS app setup

The app needs `NSBluetoothAlwaysUsageDescription` in its `Info.plist`, and `com.apple.security.device.bluetooth` in its entitlements when it is sandboxed. Without them `status()` returns `BluetoothStatus.notConfigured` and Bluetooth is never touched.

## Tests

`package:ferret_iphone/testing.dart` has `FakeAppleTransport` and `FakeIphone`, which answers ANCS commands and builds the packets a real iPhone sends:

```dart
final transport = FakeAppleTransport();
final iphone = FakeIphone(transport);
await transport.connect('iphone');

final ancs = AncsClient(transport);
await ancs.start();
iphone.notify(1, title: 'Zoé', message: 'On my way');
```

Regenerate the platform channel code with `dart run pigeon --input pigeon/messages.dart`.
