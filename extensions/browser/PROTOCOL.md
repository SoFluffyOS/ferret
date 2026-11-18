# Browser bridge protocol

How the Ferret browser extension talks to the Ferret app on the same computer. Version 1.

The app side lives in `modules/handoff/lib/services/browser/`, the extension side in `src/protocol.ts` and `src/bridge_client.ts`. Change all three together.

## Transport

- The app runs a WebSocket server on **127.0.0.1 only**, on the first free port of **47650 to 47654**. The extension tries the same ports in order, the last one that worked first.
- No native messaging, no helper binary, nothing on the network.
- Text frames only. Each frame is one JSON object. Frames over 64 KiB close the connection (code 1009). Binary frames close it (4000).
- The app pings every 30 seconds at the WebSocket level. The extension sends `ping` every 20 seconds while connected, which also keeps a Chromium service worker alive.

## Who may connect

Any web page can open `ws://127.0.0.1:47650`, so the app checks every request **before** the upgrade and answers `403` unless all of these hold:

| Check | Rule |
| --- | --- |
| Peer address | Loopback |
| `Origin` | Exactly one header, matching `chrome-extension://[a-p]{32}` or `moz-extension://<uuid>` |
| `Host` | Exactly one header naming `127.0.0.1`, `localhost` or `[::1]` (any port), so DNS rebinding can't reach it |

Plain HTTP gets `426` and an empty body. More than 16 open connections get `503`.

The origin check stops web pages. It doesn't stop other programs on the computer, which can send any header, so nothing works without **pairing** and a **token**.

## Messages

Every message has a `type`. Requests from the extension may carry an `id` (a string up to 64 characters); the reply carries it back as `re`. Pushes from the app have no `re`.

After pairing, **every** extension message except `hello`, `pair` and `ping` must carry `token`. A missing or wrong token gets `error` with `unauthorized`.

### Hello

The first message on every connection. Anything else first gets `error` `hello_first` and the connection closes.

```json
{ "type": "hello", "id": "1", "v": 1, "browser": "Firefox", "token": "…" }
```

`token` is left out before pairing. `browser` is a display name (up to 32 characters).

```json
{ "type": "welcome", "re": "1", "v": 1, "app": "ferret", "device": "MacBook", "paired": true, "passive": true }
```

- `paired` is true when the token belongs to this extension's origin. A token from another origin, or one the user removed, gives `false`; the extension then forgets it.
- `passive` is Ferret's **Suggest what I'm doing** setting.
- An extension that gets no `welcome` with `"app": "ferret"` within a few seconds moves to the next port.
- Another `v` gets `error` `unsupported_version` with the supported `v`, then the connection closes.

Once paired, the app follows the welcome with `devices` and `suggestions`.

### Pairing

```json
{ "type": "pair", "id": "2", "code": "482913", "browser": "Firefox" }
```

The extension picks six random digits and shows them. Ferret comes to the front with **Allow Firefox to use Ferret?** and the same code. The user checks they match and clicks **Allow** or **Deny**.

```json
{ "type": "paired", "re": "2", "token": "<43 characters, base64url>", "client": "9f2c…", "device": "MacBook" }
{ "type": "pair_denied", "re": "2", "reason": "denied" }
```

`reason` is `denied`, `timeout` (no answer in 2 minutes) or `busy` (this connection already asked, or three requests are waiting).

- The token is 32 random bytes. The extension keeps it in `storage.local`. The app keeps only its SHA-256 hash, with the extension's origin, in `handoff.browser_clients`.
- A token only works from the origin it was paired from.
- Pairing again from the same origin replaces the old pairing.
- An unpaired connection is closed with code `4001` after the pairing window.

### Devices

```json
{ "type": "devices", "id": "3", "token": "…" }
{ "type": "devices", "re": "3", "devices": [
  { "id": "…", "name": "Pixel", "platform": "android", "formFactor": "phone", "connected": true }
] }
```

Every device paired with Ferret. `connected` means it's reachable now and does Handoff. Pushed again (without `re`) when devices connect, disconnect or get paired.

### Send a tab

```json
{ "type": "send", "id": "4", "token": "…", "deviceId": "…",
  "tab": { "url": "https://www.youtube.com/watch?v=abc&t=95s", "title": "A talk", "videoTime": 95.4, "scrollY": 300 } }
{ "type": "sent", "re": "4", "outcome": "opened" }
```

- `url` must be http(s), up to 8 KiB. Anything else gets `error` `bad_request`.
- `videoTime` (seconds) and `scrollY` (pixels) are optional. The extension also writes the time into links that understand it (YouTube `t=`, Vimeo `#t=`, plain video files `#t=`), so the other device resumes even without the extension.
- The app turns it into a Handoff "continue now" send. `outcome` is `opened`, `suggested` (waiting in a notification there), `failed` or `unreachable`.

### Share the current tab

```json
{ "type": "share", "id": "5", "token": "…", "tab": { "url": "https://example.org", "title": "Example" } }
{ "type": "shared", "re": "5", "delivered": 2 }
```

Only sent when the user turned on **Share the current tab**, when the browser loses focus, never for private windows. The app publishes it as a quiet Handoff suggestion (only when **Suggest what I'm doing** is on) and skips a page it already offered in the last 5 minutes. `delivered` is how many devices got it.

### Suggestions

```json
{ "type": "suggestions", "id": "6", "token": "…" }
{ "type": "suggestions", "re": "6", "items": [
  { "id": "…", "title": "Cats", "url": "https://example.org/cats", "from": "Pixel", "fromId": "…",
    "explicit": false, "receivedAtMs": 1794960000000, "expiresAtMs": 1794960300000, "videoTime": 61.5 }
] }
```

Web pages your other devices offer here. Pushed (without `re`) whenever the list changes. The extension shows a badge, and a notification for ones it hasn't seen.

When the user opens one from the extension, it opens the tab itself and tells the app:

```json
{ "type": "dismiss", "token": "…", "activityId": "…" }
```

### Focus and opening here

```json
{ "type": "focus", "token": "…", "focused": true }
```

Sent when a browser window gains focus, or all lose it. When a web page arrives to open on this computer and a paired browser says it has focus (the latest one wins), the app asks it instead of the system's default browser:

```json
{ "type": "open", "id": "o1", "url": "https://example.org", "title": "Example", "videoTime": 61.5, "scrollY": 300 }
{ "type": "opened", "token": "…", "re": "o1", "ok": true }
```

No answer within 3 seconds, or `"ok": false`, and the app opens it with the system (`url_launcher`). Only web pages go this way; app links, places and text don't.

### Unpair and revoke

```json
{ "type": "unpair", "id": "7", "token": "…" }
{ "type": "unpaired", "re": "7" }
```

The extension forgets itself. When the user removes the browser in Ferret instead, the app sends `{ "type": "revoked" }` and closes with code `4003`.

### Ping

```json
{ "type": "ping", "id": "8" }
{ "type": "pong", "re": "8" }
```

Allowed before pairing.

### Errors

```json
{ "type": "error", "re": "4", "code": "bad_request" }
```

| Code | Meaning |
| --- | --- |
| `hello_first` | Something came before `hello`. Closes. |
| `unsupported_version` | Another protocol version. Closes. |
| `unauthorized` | Missing or wrong token. |
| `bad_request` | A field is missing or invalid. |
| `unknown_type` | The app doesn't know this message. |
| `rate_limited` | Too many tries; `retryAfterMs` says when to try again. Closes with `4008`. |

Five `bad_request` or `unknown_type` errors on one connection close it with `4000`.

## Rate limit

Wrong tokens (in `hello` or any message) and `pair` requests count as unauthenticated attempts. All connections share one budget, since they all come from 127.0.0.1: **10 per minute**. The next one gets `rate_limited` and the connection closes. Requests rejected before the upgrade (web pages) don't count, so a web page can't lock the extension out.

## Close codes

| Code | Meaning |
| --- | --- |
| 1001 | Ferret is quitting, or the bridge was turned off |
| 1009 | Message too big |
| 4000 | Protocol error |
| 4001 | Didn't pair in time |
| 4003 | The user removed this browser in Ferret |
| 4008 | Rate limited |
