# ferret_drop

Platform code for Ferret's Drop feature, usable on its own.

- **Android:** a "Send with Ferret" share target for any file or text (`ACTION_SEND` and `ACTION_SEND_MULTIPLE`). Shared content URIs are copied into the app cache with streams and handed to Dart as plain paths. Received files are saved into `Download/<folder>` through MediaStore on Android 10 and newer, never overwriting.
- **macOS:** the app's side of a Share extension. The extension leaves files and a request in an App Group container (named by `FerretShareGroup` in the app's Info.plist) and opens `ferret://send`; the plugin hands them to Dart as a share, with the device picked in the Share menu. `setShareTargets` publishes the devices the extension lists.
- **Every platform:** open a received file in its default app, and show it in Finder, Explorer, the file manager or the Downloads app.

```dart
final drop = FerretDrop();

drop.shares.listen((items) {
  // items.paths: files copied into the cache. items.text: shared text.
  // items.deviceId / items.everyDevice: picked in the macOS Share menu.
  // items.keepFiles: the paths are the files themselves, not copies.
});

await drop.open('/Users/me/Downloads/Ferret/photo.jpg');
await drop.reveal('/Users/me/Downloads/Ferret/photo.jpg');
```

The pigeon API lives in `pigeon/messages.dart`. Regenerate with `fvm dart run pigeon --input pigeon/messages.dart`.
