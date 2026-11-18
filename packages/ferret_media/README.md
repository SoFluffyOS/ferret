# ferret_media

See and control the media players of other apps on this device, from Dart.

```dart
final media = FerretMedia.platform();
if (await media.access() == MediaAccess.notGranted) {
  await media.requestAccess();
}

media.players.listen((players) {
  for (final player in players) {
    print('${player.appName}: ${player.title} (${player.status.name})');
  }
});
await media.startWatching();

await media.command(playerId, PlayerAction.toggle);
```

| Platform | How | Access |
|---|---|---|
| Android | `MediaSessionManager.getActiveSessions` and `MediaController` | Notification access for `io.sofluffy.ferret_notifications.FerretNotificationListener` |
| macOS | AppleScript to Music and Spotify, only while they run | Automation, asked once. Needs `NSAppleEventsUsageDescription` and the Apple Events entitlement |
| Windows | `GlobalSystemMediaTransportControlsSessionManager` (C++/WinRT) | None. No per-player volume |
| Linux | MPRIS on the session D-Bus, in Dart | None |
| iOS | Not possible: iOS hides other apps' media | `MediaAccess.unsupported` |

Positions come with the time they were true (`positionAtMs`), so callers extrapolate instead of polling. Artwork is a small JPEG or PNG, at most 64 KiB, and never downloaded from the internet.

The pigeon API lives in `pigeon/messages.dart`; regenerate with `fvm dart run pigeon --input pigeon/messages.dart`.
