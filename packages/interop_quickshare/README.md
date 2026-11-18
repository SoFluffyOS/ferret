# interop_quickshare

Speaks Quick Share (formerly Nearby Share) over the local network in pure Dart, so Android phones can send files and text to Ferret without installing anything.

Quick Share is not an open protocol. This package is written from public descriptions of it: the protocol notes of the [NearDrop](https://github.com/grishka/NearDrop/blob/master/PROTOCOL.md) project, the README of Google's open source [UKEY2](https://github.com/google/ukey2), and the message definitions Google publishes with its open source Nearby code. No code was ported from any implementation.

## What's inside

- `discovery/`: `QuickShareAdvertiser` announces the `_FC9F5ED42C8A._tcp` service with the encoded endpoint info (`QuickShareEndpointInfo`, `QuickShareService`). Underneath sits `mdns/`, a small mDNS responder (`MdnsAdvertiser`, `MdnsResponder`, `DnsMessage`).
- `crypto/`: the UKEY2 handshake (`Ukey2Server`, `Ukey2Client`: P-256 ECDH with a SHA-512 commitment), the key schedule (`Ukey2Keys`, `D2DKeys`: HKDF-SHA256), the encrypted frames (`SecureMessageCodec`: AES-256-CBC, HMAC-SHA256, sequence numbers) and the 4-digit PIN (`QuickSharePin`).
- `connection/`: `QuickShareLink`, the TCP connection with 4-byte length-prefixed frames, and `BytesPayloads`, which joins chunked control payloads.
- `server/`: `QuickShareServer` accepts senders and runs one `InboundSession` each: handshake, paired key frames, introduction, the answer, then files and text.
- `client/`: `QuickShareSendJob`, the sending side. The tests use it as the phone, and it can send to any receiver reachable over TCP.
- `proto/`: the wire format, see below.

## Receive

Implement `QuickShareReceiveDelegate` (decide about each offer, say where parts go, save finished files), then:

```dart
final server = QuickShareServer(delegate: delegate);
final port = await server.start();
final advertiser = QuickShareAdvertiser(
  info: () => const QuickShareEndpointInfo(name: 'Laptop', kind: .laptop),
);
await advertiser.start(port);
```

Every `QuickShareOffer` carries the `pin` the phone shows. Show it and ask a person: the sender's name is only a claim.

`dart run tool/advertise.dart` does exactly this from a terminal, to try a real phone.

## The flow

```
phone                                   Ferret
  | -- mDNS: who has _FC9F5ED42C8A._tcp? -> |
  | <- PTR, SRV, TXT n=<endpoint info>, A - |
  | == TCP ================================ |
  | -- ConnectionRequest ----------------> |
  | -- UKEY2 ClientInit (commitment) ----> |
  | <- UKEY2 ServerInit (public key) ----- |
  | -- UKEY2 ClientFinish (public key) --> |
  | <-> ConnectionResponse (both ways) <-> |
  | ~~ everything below is encrypted ~~~~~ |
  | <-> PairedKeyEncryption, PairedKeyResult
  | -- Introduction (files, texts) ------> |   ask, with the PIN
  | <- Response: accept or reject -------- |
  | -- payload chunks -------------------> |   part file, size check, save
  | <-> Disconnection                      |
```

Both sides send a keep-alive every 10 seconds.

## Protobuf: generated, from our own files

The messages live in `proto/quickshare/*.proto` and the Dart in `lib/proto/generated`, made by `tool/gen.sh` (`protoc` with `protoc-gen-dart`). They are kept apart from `proto/ferret`, which is Ferret's own protocol and its spec.

The files describe only what Ferret reads and writes. Field numbers and enum values are the protocol's; message names are ours where two layers would clash (`OfflineFrame` for the connection layer, `SharingFrame` for the sharing layer). Generated code was chosen over hand-encoding because the nested messages (a sharing frame in a payload chunk in an offline frame in a secure message) are easy to get wrong by hand, and unknown fields from newer phones are skipped for free.

## Why these dependencies

- `pointycastle` (pure Dart, by the Bouncy Castle project): P-256 for the key exchange and AES-CBC for the frames. `dart:io` has neither, and `package:cryptography` has no pure Dart P-256.
- `crypto`: SHA-256, SHA-512 and HMAC.
- `protobuf`, `fixnum`: the runtime of the generated messages.

mDNS is implemented here instead of taken from a package. The maintained pure Dart packages only look services up; announcing one needs a responder, and the ones that have it wrap native code. The responder is small on purpose: IPv4, one service, no probing for name conflicts (instance and host names are random).

No native code anywhere.

## Security notes

- The server only accepts connections from private, link-local and loopback addresses.
- Client public keys are checked to be on the curve. The client's finish must match the SHA-512 it committed to.
- Every encrypted frame is verified before it is decrypted, in constant time, and must carry the next sequence number.
- Frame, payload and attachment counts are capped. File chunks must arrive in order and never exceed the announced size.
- Decrypting runs on a worker isolate (`DecodeWorker`), so a large transfer doesn't stall the app.
- Nothing from the other side is logged: no names, no content, no PINs.

## What it doesn't do

- **Send to Android phones.** A phone only announces its Quick Share service after it hears a Bluetooth LE advertisement from a sender nearby. Without Bluetooth there is nothing to find on the network. `QuickShareSendJob` works against receivers that do listen, such as this package.
- **Bluetooth, Wi-Fi Direct, hotspot upgrade.** Wi-Fi LAN only.
- **Contacts and "your devices".** Those need certificates from Google's servers. Every sender is treated as unknown, and the paired key frames carry random bytes.
- **Wi-Fi credentials, apps, streams.** Answered with "unsupported attachment type".
- **QR code sharing.**

## Tests

- `crypto_test.dart`: HKDF against RFC 5869, P-256 against RFC 5903, the key schedule and the PIN against values computed with an independent implementation of the published steps, UKEY2 client against server, alerts, tampering and replays.
- `discovery_test.dart`: endpoint info, service names, DNS messages, what the responder answers.
- `frame_test.dart`: framing, payload joining, and hand-encoded frames that pin the field numbers.
- `loopback_test.dart`: whole transfers over loopback with `QuickShareSendJob` as the phone: several files, text, accept, decline, cancel from both sides, and senders that break the rules.

Not covered by a test: a real phone. We found no published test vectors for UKEY2, and the mDNS responder is checked packet by packet, not against a live network.
