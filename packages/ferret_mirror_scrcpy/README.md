# ferret_mirror_scrcpy

A `MirrorRoute` (see `ferret_mirroring`) that shows an Android device's screen on a computer through adb. The device needs USB or wireless debugging turned on, and nothing else: no root, no Shizuku, no Ferret on the phone.

It works by running [scrcpy](https://github.com/Genymobile/scrcpy)'s official, unmodified server on the device and reading its H.264 stream. The server ships inside this package. Nothing is downloaded to show a screen.

macOS, Windows and Linux only. On a phone, `status()` is `RouteUnsupported`.

```dart
final route = ScrcpyRoute();

switch (await route.status()) {
  case RouteNeedsSetup(step: .installTool, detail: ScrcpyRoute.needsAdbStarted):
    // adb is there but this app can't start it: "Open Android Studio, or
    // run adb start-server"
  case RouteNeedsSetup(step: .installTool) when route.canInstallAdb:
    // Only from a button that says it downloads Android's platform tools
    // from Google: await route.installAdb();
  case RouteNeedsSetup(step: .authorizeComputer, :final detail):
    // "Tap Allow on $detail"
  case RouteNeedsSetup(step: .enableDebugging):
    // explain USB debugging, or offer route.pair / route.connect
  default:
}

route.targets.listen((targets) async {
  final feed = await route.open(
    targets.first,
    const FeedOptions(codecs: [.h264], maxSize: 1920, control: true),
  );
  feed.events.listen((event) { /* FeedConfigured, FeedFrame, FeedEnded */ });
  feed.control?.press(.home);
});
```

## What's inside

- `adb/`: `AdbBridge`, what the route needs from adb, and its two ways there: `AdbHostClient` (adb's server on port 5037) and `AdbClient` (the `adb` program). Also `AdbLocator` (PATH, `ANDROID_HOME` / `ANDROID_SDK_ROOT`, the usual install folders), `AdbInstaller` (downloads platform-tools) and `AdbDevice`.
- `download/`: `VerifiedDownload`, which keeps a file only when its SHA-256 is the pinned one.
- `server/`: `ScrcpyRelease` (the pinned version and hash), `ScrcpyServerBundle` (the bundled server, checked and written out), `ScrcpyServerOptions` (the server's command line).
- `assets/`: `scrcpy-server-v5.0.1` as released, with scrcpy's licence and a notice.
- `protocol/`: `ScrcpyDemuxer` (the video and audio sockets), `H264Sps`, `AnnexB`, `H264FeedAssembler` (packets to `FeedConfigured` and `FeedFrame`), `AudioFeedAssembler` (packets to `FeedAudioConfigured` and `FeedAudio`), `ControlMessage`, `HidKeycodes`.
- `route/`: `ScrcpyRoute`, `ScrcpyFeed`, `ScrcpyControl`.

## How a feed starts

1. The bundled server (one file, about 730 KB) is checked against its SHA-256 and pushed to `/data/local/tmp/ferret-scrcpy-server-<scid>.jar`.
2. `shell CLASSPATH=… app_process / com.genymobile.scrcpy.Server 5.0.1 scid=<scid> tunnel_forward=true video_codec=h264 audio=false control=true clipboard_autosync=false max_size=… max_fps=… video_bit_rate=…`
3. Two connections to `localabstract:scrcpy_<scid>` on the device: video first, control second. With sound, three: video, audio, control.
4. On the video socket: one dummy byte, 64 bytes of device name, the codec id, then 12-byte headers. A header is a session packet (the video size, sent again on every rotation) or a media packet (config flag, keyframe flag, PTS, size) followed by Annex-B H.264.
5. The config packet's SPS and PPS become a `MirrorStreamConfig` (size read from the SPS). They are also put back in front of the next keyframe, as scrcpy's own client does, so every keyframe decodes on its own.

## Sound

Pass `FeedOptions.audioCodecs` (what this computer plays, best first) and the server starts with `audio=true audio_codec=opus audio_source=output` (`audio_codec=raw` for `.pcm`). It needs Android 11.

- The audio socket starts at the codec id (no dummy byte, no device name: those come on the first socket only). `opus` is followed by a config packet holding an Opus identification header, then one 20 ms Opus packet per media packet. `raw` has no config packet: 4096-byte packets of signed 16-bit little-endian samples, 48 kHz, stereo.
- A codec id of 0 means the device can't capture its sound (Android 10 and older, or an Android 11 phone that is locked when the feed starts). The feed sends one `FeedAudioUnavailable` and the pictures go on.
- Audio and video packets carry times on the same clock.
- **The phone goes quiet while its sound is sent.** Android plays it in one place. Open the feed without `audioCodecs` to hear the phone itself again.
- Only what plays on the device is captured (`audio_source=output`), never its microphone.
- The phone's media volume sets how loud the sound arrives.

`stop()` closes the sockets, which ends the server. The server deletes its own file. It is cut off if it is still there a second later, and a forwarded port is removed.

## Things to know

- **The owner isn't asked per feed.** Allowing this computer to debug the phone was the question. Whoever can use adb on this computer can see and control the phone. Say so in the UI.
- **Control** goes through scrcpy's control socket: touches (fractions become video pixels, the server maps them to the screen), scroll, keys (HID usage to Android keycode), text, Back, Home, Recent apps, Power, Volume, the notification panel, rotate, and set clipboard with paste. `feed.control` is null unless `FeedOptions.control` is set.
- **`text()`** types what the device's key map has, so mostly ASCII. For anything else use `setClipboard(text, paste: true)`.
- **`requestKeyframe()`** sends scrcpy's "reset video" message, which restarts the encoder. That is why the control socket is always open, even when control wasn't asked for.
- **`setBitrate()` does nothing.** scrcpy's server takes its bitrate when it starts. Open a new feed for another one.
- **H.264 only.** `FeedOptions.codecs` without `.h264` ends the feed with `noCodec`.
- **The phone's clipboard never comes here on its own** (`clipboard_autosync=false`).
- **Protected screens stay black**, as in any capture.

## Two ways to reach adb

`ScrcpyRoute` asks adb's server first, and runs the `adb` program only when no server answers.

| | `AdbHostClient` | `AdbClient` |
|---|---|---|
| How | adb's host protocol on `127.0.0.1:5037`: `host:devices-l`, `host:transport`, `sync:` for the push, `shell:`, `localabstract:`, `host:pair`, `host:connect` | Runs `adb devices`, `push`, `shell`, `forward`, `pair`, `connect` |
| Needs | An adb server that is already running | The `adb` program on this computer |
| Sockets to the device | Straight through the server. No port is opened here | Through `adb forward tcp:0 …`, removed after |

Why both? The socket is the lighter way, and the only one that also works inside a sandbox. But something has to start that server, own the USB connection and keep the key the phone trusts. Only the `adb` program does that. Its first command starts the server, and from the next call on the route talks to the server directly.

### The macOS App Sandbox

Ferret for macOS ships outside the Mac App Store (Developer ID, notarized, hardened runtime) and is **not** sandboxed, so the route starts adb itself there, as on Windows and Linux. The hardened runtime needs no entitlement for running a program.

Another app that embeds this route inside the App Sandbox gets less. Tried with a sandboxed build mirroring an Android 15 emulator:

- **An adb server that is already running works.** Devices, push, shell and the video all go over the local socket. `com.apple.security.network.client` is all it takes.
- **The app can't start adb.** Running the program fails with "Operation not permitted", wherever the file is. A downloaded file also gets `com.apple.quarantine`, which a sandboxed app can't take off again.

So in a sandbox `canInstallAdb` is false and `installAdb()` throws. Without a server, `status()` is `RouteNeedsSetup(installTool, detail: ScrcpyRoute.needsAdbStarted)`: the user has to open Android Studio or run `adb start-server` once.

## What reaches the internet

Ferret makes no network calls beyond your own devices, and neither does showing a screen with this package. There is one exception, and it never happens on its own:

| What | From | When |
|---|---|---|
| Android platform-tools 37.0.1 | `dl.google.com/android/repository` | Only when `installAdb()` is called |

Call `installAdb()` only from a button the user pressed, whose text says it downloads Android's platform tools from Google, and only where `canInstallAdb` is true. Ferret's mirroring settings do exactly that: **Get Android's helper tool**, "Ferret downloads Android's platform tools from Google, about 16 MB, once.", **Download**. The route also implements `ToolInstaller` from `ferret_mirroring` (`canInstallTool`, `installTool()`, `toolNotStartedDetail`), so a UI can offer this without importing the package. The download is checked against a pinned SHA-256. Google publishes SHA-1 only; the SHA-256 values in `PlatformToolsRelease` were computed from downloads whose SHA-1 matched Google's list.

The scrcpy server is an asset. Its SHA-256 (from scrcpy's own `SHA256SUMS.txt`) is checked every time before it is used.

## Moving to a newer scrcpy

scrcpy's protocol is internal and changes between versions (4.0 added session packets, for one). The server only starts for a client of its exact version. So the file in `assets/`, `ScrcpyRelease` (version and hash), the notice and everything in `protocol/` move together. Check `doc/develop.md`, `server/.../Options.java`, `app/src/control_msg.c` and `app/src/demuxer.c` of the new version first.

## Tests

`scripts/check.sh packages/ferret_mirror_scrcpy` runs the unit tests: the demuxer (video and audio) and SPS parser on bytes captured from a real server, and control messages against the bytes in scrcpy's own `test_control_msg_serialize.c`.

One suite needs a running Android emulator, so it is skipped by default:

```bash
fvm flutter test --run-skipped --tags emulator
```

It shows the emulator's screen, rotates it, taps and types, reads its sound as Opus and as plain samples, and checks nothing is left behind: once through adb's server, once through the `adb` program. Its last test downloads Google's platform-tools and runs them.

## Credits

[scrcpy](https://github.com/Genymobile/scrcpy) is made by Genymobile and Romain Vimont, under the Apache License 2.0. This package ships scrcpy's released server as it is, with its licence (`assets/scrcpy-LICENSE.txt`) and a notice (`assets/scrcpy-NOTICE.txt`). It contains no scrcpy source code.
