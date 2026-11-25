# ferret_mirror_airplay

A `MirrorReceiver` (see `ferret_mirroring`) that makes a computer show up under **Control Center → Screen Mirroring** on an iPhone, iPad or Mac. Pick it there and the screen arrives as a `MirrorFeed`. Nothing is installed on the phone.

It speaks **legacy AirPlay screen mirroring**, the way the open source receivers do ([RPiPlay](https://github.com/FD-/RPiPlay), [UxPlay](https://github.com/FDH2/UxPlay)). Video only: H.264, no sound yet.

macOS, Windows and Linux. On a phone, `status()` is `RouteUnsupported`.

```dart
final receiver = AirPlayReceiver(
  // Stable between runs, and made from something only this device knows.
  identity: () async => AirPlayIdentity.derive(privateKeyBytes),
  // Nothing is shown without a yes from here.
  // Or pass `allow` to `start`, as Ferret does.
  allow: (deviceName) => askTheUser('Show $deviceName\'s screen here?'),
);

receiver.incoming.listen((feed) {
  feed.events.listen((event) { /* FeedConfigured, FeedFrame, FeedEnded */ });
});

await receiver.start('Living room PC'); // listens and announces
await receiver.stop();                  // gone from every phone's list
```

Nothing listens and nothing is announced until `start`. `AirPlayReceiver.onByDefault` is `false` on macOS, which has its own AirPlay receiver.

## ⚠️ FairPlay is reverse-engineered

Read this before you rely on the package.

- AirPlay is Apple's, and Apple doesn't document it. Before an iPhone sends its screen, it runs a **FairPlay** handshake. The only open implementation is **playfair**, reverse-engineered years ago. We vendor it as it is (`native/playfair`, GPL-3.0) and call it through FFI.
- **An iOS update can break it, any day.** If Apple changes the handshake or drops legacy mirroring, phones will stop connecting and there is nothing to patch on our side until someone works it out again.
- The receiver presents itself as an **Apple TV 3** (`AppleTV3,2`), because that generation still speaks the legacy protocol. That is a trick, and tricks get closed.
- It has **never been run against a real iPhone here**. See "What was tested" below.

This is why the receiver sits behind `MirrorReceiver`: the day it stops working, it can be swapped for another one without touching the viewer.

## What's inside

- `plist/`: `BinaryPlistDecoder`, `BinaryPlistEncoder`. Apple's `bplist00` format, used for most request and response bodies.
- `crypto/`: `PairVerify` (legacy pair-verify: X25519, Ed25519, AES-CTR), `MirrorStreamKeys` (the video key and IV), `AesCtrStream`, `AirPlayIdentity`.
- `fairplay/`: `FairPlaySession` (`/fp-setup`), `FairPlayReplies` (the four fixed answers), `playfairDecrypt` (the FFI call).
- `rtsp/`: `RtspRequestReader`, `RtspRequest`, `RtspResponse`. iPhones mix RTSP and HTTP-style requests on one connection.
- `stream/`: `MirrorPacketReader` and `MirrorPacketHeader` (128-byte headers), `Avcc` (avcC → SPS/PPS, length-prefixed NALs → Annex-B), `MirrorStreamDecoder` (packets → feed events).
- `discovery/`: `AirPlayServiceInfo` (TXT records and `/info`), `AirPlayAdvertiser` (`_airplay._tcp` and `_raop._tcp` over the mDNS responder of `lan_discovery`).
- `receiver/`: `AirPlayReceiver`, `AirPlayConnection` (one phone's control connection), `AirPlayFeed`, `TimingClient`.

## How a session goes

1. The phone finds `_airplay._tcp` and `_raop._tcp` and connects to the port in them.
2. `GET /info`: who we are, as a binary plist.
3. `POST /pair-setup`, then `POST /pair-verify` twice: both sides prove their Ed25519 keys and share an X25519 secret.
4. `POST /fp-setup` twice: the FairPlay handshake.
5. `SETUP` with `ekey` and `eiv`: the phone names itself. **This is where `allow` is asked.** A no, or no answer in 30 seconds, is a `401` and the phone is hung up on.
6. `SETUP` with a stream of type `110`: we open a TCP port, the feed goes out on `incoming`, the phone connects and sends 128-byte headers with payloads: `1` the avcC record (→ `FeedConfigured`), `0` encrypted pictures (→ `FeedFrame`), `2` heartbeats.
7. `TEARDOWN` → `FeedEnded(stoppedThere)`. A dropped connection → `FeedEnded(lostConnection)`. `feed.stop()` → `FeedEnded(stoppedHere)` and the phone is hung up on.

The video key: playfair decrypts `ekey` to 16 bytes, hashed with the pair-verify secret (SHA-512, first 16 bytes), hashed again with `AirPlayStreamKey<id>` and `AirPlayStreamIV<id>` for the AES-128-CTR key and IV. One key stream runs over all pictures.

A phone's rotation or a locked screen shows up as a new `FeedConfigured` or a `FeedSourceState`. `requestKeyframe` and `setBitrate` do nothing: AirPlay gives the receiver no say in either. `control` is null.

## Security

- **Nothing without a yes.** Every session goes through `allow`. The name it gets is only what the phone claims.
- **Local network only.** Connections from other addresses are dropped.
- **Legacy pairing proves nothing about who the phone is.** Any device on your network can ask. That is why `allow` exists, and why a PIN is the next step.
- Everything from the network is size-checked: plists, RTSP heads and bodies, stream payloads, and the FairPlay message before it reaches C.
- The signing key is derived from the secret you give `AirPlayIdentity.derive`. Give it something private.

## What was tested

Automated (`flutter test`):

- **plist**: decoded a plist written by macOS's own `plutil`; our output read back by `plutil -p`; every truncation and every flipped byte of a valid plist.
- **pair-verify**: RFC 8032 and RFC 7748 keys, with the encrypted signatures computed apart from this code by the OpenSSL command line.
- **video key and decryption**: vectors printed by a C program built from UxPlay's own `mirror_buffer.c` and `crypto.c`, packets of uneven sizes, a stream id with its top bit set.
- **playfair through FFI**: the same output as the C code compiled on its own.
- **a whole session over loopback**: a fake phone does every step above with its own keys, and the frames come out as Annex-B.

By hand, on a Mac:

- `curl http://127.0.0.1:<port>/info` answers, and `plutil -p` reads the plist.
- `dig` parses the mDNS answers for both services (PTR, SRV, TXT, A).

**Not tested:**

- **A real iPhone, iPad or Mac.** Not once. The steps above match the reference receivers, but only a phone can say.
- **Multicast on a real network.** The shell this was built in has no local network permission on macOS, so `dns-sd -B` never saw the announcement. The responder is the one Quick Share already uses.
- **Windows and Linux.** The build hook needs a C compiler there (MSVC, clang or gcc). Only macOS arm64 was compiled.
- What the phone does while `allow` waits. It may give up before 30 seconds.

### Manual test with a real phone

1. Run the app on a computer, on the same Wi-Fi as an iPhone. Turn the receiver on.
2. Check it is announced: `dns-sd -B _airplay._tcp` lists its name.
3. On the iPhone: **Control Center → Screen Mirroring**. The computer is in the list.
4. Tap it. The computer asks. Say yes. The phone's screen appears within a couple of seconds.
5. Rotate the phone: the picture follows. Lock it: the picture stands still, and comes back on unlock.
6. Tap **Stop Mirroring** on the phone: the feed ends as "stopped there".
7. Start again and stop from the computer: the phone leaves mirroring by itself.
8. Start again and say no: the phone shows an error and nothing is displayed.
9. Turn the receiver off: the computer leaves the phone's list within a minute.

On macOS, the system's **AirPlay Receiver** holds port 7000. This package listens on any free port and announces that one, so both can run.

## Thanks

To [playfair](https://github.com/EstebanKubata/playfair)'s author and to the people behind RPiPlay and UxPlay, who worked the protocol out. Only playfair's C code is theirs here; the rest is our own Dart, written from what their receivers do.
