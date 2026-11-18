# ferret_power

Android apps can't read the clipboard in the background, and a few system settings are painful to reach. With [Shizuku](https://shizuku.rikka.app) or root, they can.

`ferret_power` finds both, tells you where each one stands, and runs a short, fixed list of things through them. Android only. On every other platform it reports "nothing here" and does nothing.

## 🚀 Use it

```dart
final power = PowerCapabilities();

// Apply what the user chose earlier. Nothing runs before this says yes.
await power.configure(shizuku: true, root: false);

print(power.status.shizuku); // notInstalled, notRunning, notAuthorized, ready
print(power.activeTier);     // standard, shizuku, root

// Starts a watcher as the shell user while someone listens.
power.clipboardChanges.listen((clip) => print(clip.sensitive));

final clip = await power.readClipboard();
await power.grant(PowerGrant.notificationAccess);
```

Walk the user through Shizuku with `openShizuku()` and `authorizeShizuku()`, and through root with `enableRoot()`. Call `refresh()` when they come back to your app.

## 🔑 Nothing runs unless it was turned on

A tier counts only when the user turned it on **and** the phone agrees right now. Otherwise `activeTier` is `standard`, and `readClipboard()`, `clipboardChanges` and `grant()` do nothing: no shell is started and `su` is never run.

Looking never asks. Reading `status` checks whether Shizuku and a root manager are installed and stops there.

## 📦 What runs, and as whom

A small helper from your own APK runs as Android's shell user: as a Shizuku user service, or through `su` with `app_process`. It can do three things:

| Capability | How | Why |
|---|---|---|
| `readClipboard()`, `clipboardChanges` | The clipboard service's `getPrimaryClip` and change listener, as `com.android.shell` | The shell user may read the clipboard in the background. Text only, up to 200,000 characters |
| `grant(notificationAccess)` | `cmd notification allow_listener <your listener>` | Skips the settings screen and Android 13's "restricted setting" block for sideloaded apps |
| `grant(batteryUnrestricted)` | `cmd deviceidle whitelist +<your package>` | Keeps a background connection alive |

The helper builds these commands itself from validated names and runs them without a shell. It can't be handed a command line. The one line given to `su` is assembled with single-quoted values.

Clipboard text passes through and is never logged.

## 🧪 Tests

- `fvm flutter test`: the tier state machine and the gating, against `FakePowerPlatform` (`package:ferret_power/testing.dart`). Use the same fake in your own tests.
- Kotlin unit tests in `android/src/test`: the helper's line protocol, the quoting, the fixed commands, and the argument filling for the clipboard service's hidden methods.

What was run on a device, and what wasn't:

| Check | Result |
|---|---|
| The helper, started with `app_process` as the shell user on an Android 15 emulator: read, watch, both grants | ✅ |
| The plugin in the app on that emulator: state, the ladder | ✅ |
| The helper as a Shizuku user service (binding, permission dialog) | ❌ not run yet |
| The helper started through `su` (Magisk, KernelSU, APatch) | ❌ not run yet |
| Android versions other than 15 | ❌ not run yet |

## 🧭 Notes

- The notification listener that `grant(notificationAccess)` turns on is `<package>/io.sofluffy.ferret_notifications.FerretNotificationListener`.
- The clipboard service's hidden methods changed their arguments in Android 10, 13 and 14. The helper fills them by type, so one code path covers them all.
- Release builds keep the helper classes through `consumer-rules.pro`.
