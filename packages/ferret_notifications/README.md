# ferret_notifications

Other apps' notifications on Android, for Ferret's notification mirroring:

- 🔔 Get each notification as it is posted or removed (never the ones already showing).
- 💬 Run a notification's actions, including replies through `RemoteInput`.
- 🧹 Dismiss notifications.
- 🔑 Check and open notification access, and detect Android 13+ "restricted settings" for apps installed from a file.
- 📱 List launcher apps with their icons, for an app picker.

```dart
final notifications = FerretNotifications();
if (FerretNotifications.isSupported && await notifications.isAccessGranted()) {
  notifications.events.listen((event) { /* ... */ });
}
```

The listener service is `io.sofluffy.ferret_notifications.FerretNotificationListener`, declared in the plugin manifest. Other plugins that need notification access (such as `MediaSessionManager.getActiveSessions`) use `FerretNotificationListener.componentName(context)` in Kotlin or `FerretNotifications.listenerClassName` in Dart.

Android only. Regenerate the platform channel code with `fvm dart run pigeon --input pigeon/messages.dart`.
