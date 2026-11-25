# ferret_remote_input

Moves the pointer, clicks, scrolls and types on this computer for another device. Key names are the same everywhere (`InputKey`, `KeyModifier`); each platform maps them to its own codes.

| Platform | How | Needs |
|---|---|---|
| macOS | CGEvent (Swift) | Accessibility access (`CGRequestPostEventAccess`) |
| Windows | SendInput (C++) | Nothing; apps running as administrator can't be reached |
| Linux | uinput virtual device (Dart FFI), else `ydotool` (Wayland) or `xdotool` (X11) | Write access to `/dev/uinput`, or one of the tools |
| Android, iOS | Not supported | They are controllers |

```dart
final injector = InputInjector.current();
if ((await injector.status()).isReady) {
  await injector.inject(const [MoveAction(10, 0), ButtonAction(.left, pressed: true), ButtonAction(.left, pressed: false)]);
}
await injector.releaseAll();
```

Regenerate the platform channel with `dart run pigeon --input pigeon/messages.dart`.
