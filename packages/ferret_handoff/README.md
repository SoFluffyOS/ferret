# ferret_handoff

Platform code for Ferret's handoff feature, usable on its own.

- **Android**: a "Continue on…" share target for text and links, with a small native device chooser that works before Flutter starts. An assistant (`VoiceInteractionService`) that reads `AssistContent` (web URI, structured data, app intent) of the current screen when Ferret is the default digital assistant. Opening a URI in a given package.
- **macOS**: opening a URI in a given app by bundle id, and reading the current page of Safari or a Chromium browser through AppleScript (opt-in, needs Automation permission).

The Dart API is `FerretHandoff`; the platform interface lives in `pigeon/messages.dart`. Regenerate with:

```bash
fvm dart run pigeon --input pigeon/messages.dart
```

## App setup on macOS

Reading the browser page sends Apple events, so the app needs:

- `NSAppleEventsUsageDescription` in `Info.plist`.
- `com.apple.security.automation.apple-events` in its entitlements, and, when sandboxed, `com.apple.security.temporary-exception.apple-events` listing the browser bundle ids.
