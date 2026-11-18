# ferret_messages

Reads and sends SMS and MMS on Android, for Ferret's messages feature. Reusable on its own.

- Conversations from the Telephony providers, most recent first, with contact names and small photos.
- Messages of one conversation, paged by date, with MMS text and image previews.
- A change stream (provider observer, incoming SMS, delivery reports), merged into one event per burst.
- Sending through `SmsManager`, split into parts, waiting for the radio to confirm.
- The permission flow: `access()`, `requestAccess()` and `openAppSettings()`.

```dart
final messages = FerretMessages();
if (FerretMessages.isSupported && (await messages.requestAccess()).canRead) {
  final page = await messages.listConversations(limit: 30);
}
```

The plugin declares `READ_SMS`, `RECEIVE_SMS`, `SEND_SMS` and `READ_CONTACTS`. RCS chats live inside Google Messages and no other app can read them.

Regenerate the platform API with `fvm dart run pigeon --input pigeon/messages.dart`.
