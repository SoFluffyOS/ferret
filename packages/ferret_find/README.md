# ferret_find

Rings a device so someone can find it. Part of [Ferret](../../README.md), usable on its own.

```dart
final find = FindPlatform.current();
final before = await find.readAudio();
if (before != null) {
  await find.applyAudio(before.loudest(liftDoNotDisturb: true));
}

await find.startAlert(
  const RingAlert(
    title: 'Ferret is ringing',
    body: 'Your laptop is looking for this phone',
    foundItLabel: 'Found it',
    maxDuration: Duration(minutes: 2),
    flashTorch: true,
  ),
);

// Later, or when find.stops fires:
await find.stopAlert();
if (before != null) {
  await find.applyAudio(before);
}
```

| Platform | Sound | Volume | Notice |
|---|---|---|---|
| Android | Default alarm tone on the alarm stream, vibration, optional torch blink | Raises the alarm volume and lifts Do Not Disturb (with access) | Full-screen notification with "Found it"; a volume key also stops it |
| iOS | Bundled tone through the silent switch, vibration | Not available on iOS | None: show your own. Only while the app is open |
| macOS | A system sound on repeat, Dock icon bounce | Raises and unmutes the output | None: show your own |
| Windows | Bundled tone with `System.Media.SoundPlayer` | Untouched | None: show your own |
| Linux | Bundled tone with `pw-play`, `paplay` or `aplay` | Untouched | None: show your own |

Android permissions (merged from this plugin's manifest): `ACCESS_NOTIFICATION_POLICY`, `USE_FULL_SCREEN_INTENT`, `VIBRATE`, `WAKE_LOCK`. Do Not Disturb access is granted by the person in Settings: `openDndAccessSettings()` opens the page.

Regenerate the platform channel code with `fvm dart run pigeon --input pigeon/messages.dart`.
