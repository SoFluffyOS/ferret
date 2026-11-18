# ferret_calls

Phone calls on Android for Flutter: see when a call rings and who it is,
answer it, decline it, hang up, silence the ringer, place a call, and read the
recent calls. Built for [Ferret](../../README.md), usable on its own.

Android only. Check `FerretCalls.isSupported` first.

```dart
final calls = FerretCalls();

final permissions = await calls.requestPermissions();
if (permissions.phoneState) {
  calls.events.listen((event) => print(event.state));
  await calls.startMonitoring();
}

await calls.dial('+15550100');
final recent = await calls.recentCalls(50);
```

## What it uses

| What | Android API | Permission |
|---|---|---|
| Call state | `TelephonyCallback` (12+), `PhoneStateListener` (older) | `READ_PHONE_STATE` |
| The number | `PHONE_STATE` broadcast | `READ_CALL_LOG` |
| Name and photo | `ContactsContract.PhoneLookup` | `READ_CONTACTS` |
| Answer (8+), end (9+) | `TelecomManager.acceptRingingCall`, `endCall` | `ANSWER_PHONE_CALLS` |
| Silence | `TelecomManager.silenceRinger`, else mutes the ring stream until the ringing stops | none |
| Dial | `TelecomManager.placeCall` | `CALL_PHONE` |
| Recent calls | `CallLog.Calls` | `READ_CALL_LOG` |

The permissions are declared in the plugin's manifest and merged into the app.

## Limits

- Android does not tell apps when an outgoing call is picked up, or which
  call is on hold.
- Events arrive while the app's process is alive. Keep it alive with a
  foreground service if you need calls in the background.
- Call audio is not touched. It stays on the phone.

The pigeon API is in `pigeon/messages.dart`. Regenerate with
`fvm dart run pigeon --input pigeon/messages.dart`.
