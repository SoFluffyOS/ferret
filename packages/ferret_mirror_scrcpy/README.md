# ferret_mirror_scrcpy

A `MirrorRoute` (see `ferret_mirroring`) that shows an Android device's screen on a computer through adb. The device needs USB or wireless debugging turned on, and nothing else: no root, no Shizuku, no Ferret on the phone.

It works by running [scrcpy](https://github.com/Genymobile/scrcpy)'s official, unmodified server on the device and reading its H.264 stream.

macOS, Windows and Linux only. On a phone, `status()` is `RouteUnsupported`.

```dart
final route = ScrcpyRoute();

switch (await route.status()) {
  case RouteNeedsSetup(step: .installTool):
    await route.installAdb(); // Google's platform-tools, SHA-256 checked
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

- `adb/`: `AdbLocator` (PATH, `ANDROID_HOME` / `ANDROID_SDK_ROOT`, the usual install folders), `AdbInstaller` (downloads platform-tools), `AdbClient` (devices, push, forward, shell, pair, connect), `AdbDevice`.
- `download/`: `VerifiedDownload`, which keeps a file only when its SHA-256 is the pinned one.
- `server/`: `ScrcpyRelease` (the pinned version and hash), `ScrcpyServerCache`, `ScrcpyServerOptions` (the server's command line).
- `protocol/`: `ScrcpyDemuxer` (the video socket), `H264Sps`, `AnnexB`, `H264FeedAssembler` (packets to `FeedConfigured` and `FeedFrame`), `ControlMessage`, `HidKeycodes`.
- `route/`: `ScrcpyRoute`, `ScrcpyFeed`, `ScrcpyControl`.

## How a feed starts

1. The server (one file, about 730 KB) is pushed to `/data/local/tmp/ferret-scrcpy-server-<scid>.jar`.
2. `adb shell CLASSPATH=… app_process / com.genymobile.scrcpy.Server 5.0.1 scid=<scid> tunnel_forward=true video_codec=h264 audio=false control=true clipboard_autosync=false max_size=… max_fps=… video_bit_rate=…`
3. `adb forward tcp:0 localabstract:scrcpy_<scid>`, then two connections to that port: video first, control second.
4. On the video socket: one dummy byte, 64 bytes of device name, the codec id, then 12-byte headers. A header is a session packet (the video size, sent again on every rotation) or a media packet (config flag, keyframe flag, PTS, size) followed by Annex-B H.264.
5. The config packet's SPS and PPS become a `MirrorStreamConfig` (size read from the SPS). They are also put back in front of the next keyframe, as scrcpy's own client does, so every keyframe decodes on its own.

`stop()` closes the sockets, which ends the server. The server deletes its own file. The adb process is killed if it is still there a second later, and the forward is removed.

## Things to know

- **The owner isn't asked per feed.** Allowing this computer to debug the phone was the question. Whoever can use adb on this computer can see and control the phone. Say so in the UI.
- **Control** goes through scrcpy's control socket: touches (fractions become video pixels, the server maps them to the screen), scroll, keys (HID usage to Android keycode), text, Back, Home, Recent apps, Power, Volume, the notification panel, rotate, and set clipboard with paste. `feed.control` is null unless `FeedOptions.control` is set.
- **`text()`** types what the device's key map has, so mostly ASCII. For anything else use `setClipboard(text, paste: true)`.
- **`requestKeyframe()`** sends scrcpy's "reset video" message, which restarts the encoder. That is why the control socket is always open, even when control wasn't asked for.
- **`setBitrate()` does nothing.** scrcpy's server takes its bitrate when it starts. Open a new feed for another one.
- **No sound**, and H.264 only. `FeedOptions.codecs` without `.h264` ends the feed with `noCodec`.
- **The phone's clipboard never comes here on its own** (`clipboard_autosync=false`).
- **Protected screens stay black**, as in any capture.

## Why the adb program, not its socket protocol

adb's server speaks a small protocol on port 5037, and talking to it directly would save a process per command. But something still has to start that server, own the USB connection, keep the RSA key the phone trusts, and pair over TLS for wireless debugging. Only the `adb` program does all that, so it has to be on the computer anyway. Running it for `devices`, `push`, `forward`, `shell`, `pair` and `connect` keeps this package to one small class, and behaves exactly like the adb the user already knows. The video and control streams don't go through a process: they are plain sockets to the forwarded port.

## What gets downloaded, and when

Ferret makes no network calls beyond your own devices. This route needs two exceptions, both pinned by SHA-256 and both only when the route is used:

| What | From | When |
|---|---|---|
| scrcpy server 5.0.1 | `github.com/Genymobile/scrcpy` releases | The first `open()` |
| Android platform-tools 37.0.1 | `dl.google.com/android/repository` | Only when `installAdb()` is called |

Google publishes SHA-1 for platform-tools. The SHA-256 values in `PlatformToolsRelease` were computed from downloads whose SHA-1 matched Google's list. scrcpy's SHA-256 is the one in its release's `SHA256SUMS.txt`.

## Moving to a newer scrcpy

scrcpy's protocol is internal and changes between versions (4.0 added session packets, for one). The server only starts for a client of its exact version. So `ScrcpyRelease.version`, its hash and everything in `protocol/` move together. Check `doc/develop.md`, `server/.../Options.java`, `app/src/control_msg.c` and `app/src/demuxer.c` of the new version first.

## Tests

`scripts/check.sh packages/ferret_mirror_scrcpy` runs the unit tests: the demuxer and SPS parser on bytes captured from a real server, and control messages against the bytes in scrcpy's own `test_control_msg_serialize.c`.

One suite needs a running Android emulator and the internet, so it is skipped by default:

```bash
fvm flutter test --run-skipped --tags emulator
```

It downloads adb and the server, shows the emulator's screen, rotates it, taps and types, and checks nothing is left behind.

## Credits

[scrcpy](https://github.com/Genymobile/scrcpy) is made by Genymobile and Romain Vimont, under the Apache License 2.0. This package downloads scrcpy's released server and runs it as it is. It contains no scrcpy code.
