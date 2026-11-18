# ferret_clipboard

Reads, writes and watches the system clipboard, and tells you when an item was marked as private.

| Platform | Reads | Change events | Private items |
|---|---|---|---|
| macOS | any time | `NSPasteboard.changeCount`, checked twice a second | `org.nspasteboard.ConcealedType`, `TransientType` |
| Windows | any time | `AddClipboardFormatListener` | `ExcludeClipboardContentFromMonitorProcessing`, `CanIncludeInClipboardHistory = 0` |
| Linux | any time | `wl-paste --watch`, or a 1 s check | `x-kde-passwordManagerHint` |
| Android | in front only | copies made inside the app | `ClipDescription.EXTRA_IS_SENSITIVE` |
| iOS | when asked | in front only | `org.nspasteboard.ConcealedType` |

Images on Linux need `wl-clipboard` (Wayland) or `xclip` (X11).

```dart
final clipboard = ClipboardPlatform.current();
await clipboard.startWatching();
clipboard.changes.listen((_) async {
  final content = await clipboard.read();
});
await clipboard.write(const ClipboardContent.text('Hello', sensitive: true));
```

Regenerate the platform channels after editing `pigeon/messages.dart`:

```bash
fvm dart run pigeon --input pigeon/messages.dart
```
