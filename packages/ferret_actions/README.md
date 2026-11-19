# ferret_actions

Puts this computer to sleep, restarts it, shuts it down, changes its volume, and runs a command line with a timeout. Part of [Ferret](../../README.md), usable on its own. Pure Dart: no plugin to register, so it works in a command-line tool too.

```dart
final computer = ComputerActions.current();
if (computer.supported.contains(ComputerAction.sleep)) {
  await computer.run(ComputerAction.sleep);
}

final outcome = await CommandRunner().run(
  CommandLine.resolve(CommandLine.split('~/bin/backup.sh --quick')),
  timeout: const Duration(seconds: 30),
);
print(outcome.exitCode); // null when it timed out or couldn't start
```

| Action | macOS | Windows | Linux |
|---|---|---|---|
| Sleep | `pmset sleepnow` | `SetSuspendState` | logind `Suspend`, then `systemctl suspend` |
| Restart | System Events `restart` | `ExitWindowsEx` with `SeShutdownPrivilege` | logind `Reboot`, then `systemctl reboot` |
| Shut down | System Events `shut down` | `ExitWindowsEx` with `SeShutdownPrivilege` | logind `PowerOff`, then `systemctl poweroff` |
| Mute, volume | `set volume` (AppleScript) | the volume keys (`keybd_event`) | `wpctl`, then `pactl`, then `amixer` |

On macOS, restart and shut down go through System Events: the app needs `NSAppleEventsUsageDescription` in its `Info.plist` (and the `com.apple.security.automation.apple-events` entitlement under the hardened runtime), and macOS asks once.

`CommandLine.split` never starts a shell: quotes group words, nothing else is special. `CommandLine.resolve` picks the program for a script or shortcut path (`.sh`, `.scpt`, `.app`, `.ps1`, `.bat`, `.lnk`).
