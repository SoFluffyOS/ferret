# Privacy

Ferret is built so your stuff never leaves your devices. That is the whole point.

## 🔒 What Ferret does

- Your devices talk **directly to each other on your network**. Nothing goes through a server.
- Every connection is **end-to-end encrypted** with the [Noise protocol](https://noiseprotocol.org) (`Noise_XX_25519_ChaChaPoly_SHA256`).
- A device can only connect after you **paired** it, by scanning a code or comparing six digits. Strangers on the same Wi-Fi can't read or send anything.
- Each device has its own key, kept in the system keychain on phones and in a file only you can read on computers.

## 🙅 What Ferret never does

- No account. No sign-in. No email.
- No cloud, no relay, no "fallback over the internet".
- No analytics, no crash reporting service, no ads, no tracking of any kind.
- It never logs what you copy, the files you send, your messages or your notifications.

## 🛂 You stay in control

- **Pause** Ferret any time, for an hour or until you resume.
- **Unpair** a device in one click; both sides forget each other.
- Every feature is a switch in Settings, and sensitive ones (notifications, messages, calls) stay off until you turn them on.
- Ferret downloads one thing, and only when you click **Download**: Android's platform tools from Google, for [mirroring a phone without Ferret on it](features/mirroring-with-a-cable.md).

## 🔓 Check it yourself

Ferret is open source. The apps are GPL-3.0 and the protocol is MIT, documented in the [protocol reference](spec/reference.md).
