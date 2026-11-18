# interop_localsend

Speaks the open [LocalSend protocol](https://github.com/localsend/protocol) (v2) in pure Dart, so Ferret can send files to and receive files from LocalSend on any platform. Written from the protocol's README, not from LocalSend's source.

## What's inside

- `models/`: the JSON messages (`LocalSendInfo`, `LocalSendFile`, `PrepareUploadRequest`, `PrepareUploadResponse`). Everything read from the network is checked and cleaned.
- `security/`: `LocalSendIdentity`, a self-signed RSA 2048 certificate made on the device. Its SHA-256 is the fingerprint.
- `discovery/`: `LocalSendDiscovery` (multicast on 224.0.0.167:53317) and `LegacyScanner` (asks each address of the local /24).
- `client/`: `LocalSendClient` (`register`, `info`, `prepare-upload`, `upload`, `cancel`) and `LocalSendSendJob`, which sends a set of files with progress and cancel.
- `server/`: `LocalSendServer`, the HTTPS upload API. It does nothing until `start()`, serves one session at a time, and only local addresses.

## Send

```dart
final identity = await LocalSendIdentity.generate();
final client = LocalSendClient(identity: identity);
final job = LocalSendSendJob(client: client, peer: peer, self: me, files: files);
await job.run(onProgress: (sentBytes) => print(sentBytes));
```

## Receive

Implement `LocalSendReceiveDelegate` (decide about each offer, say where parts go, save finished files), then:

```dart
final server = LocalSendServer(identity: identity, self: describe, delegate: delegate);
await server.start();
```

## Trust

LocalSend members use self-signed certificates. The client pins each member's certificate to the fingerprint it announced and refuses to send when they differ. The server can't verify who a sender is: the name and fingerprint in an offer are claims, so always ask a person before accepting.

## Why pointycastle

`dart:io` can serve TLS but can't make a certificate. `pointycastle` (pure Dart, by the Bouncy Castle project) generates the RSA key and signs; the small DER writer in `security/der.dart` builds the certificate around it. No native code.
