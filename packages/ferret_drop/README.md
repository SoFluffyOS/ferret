# ferret_drop

Platform code for Ferret's Drop feature, usable on its own.

- **Android:** a "Send with Ferret" share target for any file or text (`ACTION_SEND` and `ACTION_SEND_MULTIPLE`). Shared content URIs are copied into the app cache with streams and handed to Dart as plain paths. Received files are saved into `Download/<folder>` through MediaStore on Android 10 and newer, never overwriting.
- **Every platform:** open a received file in its default app, and show it in Finder, Explorer, the file manager or the Downloads app.

```dart
final drop = FerretDrop();

drop.shares.listen((items) {
  // items.paths: files copied into the cache. items.text: shared text.
});

await drop.open('/Users/me/Downloads/Ferret/photo.jpg');
await drop.reveal('/Users/me/Downloads/Ferret/photo.jpg');
```

The pigeon API lives in `pigeon/messages.dart`. Regenerate with `fvm dart run pigeon --input pigeon/messages.dart`.
