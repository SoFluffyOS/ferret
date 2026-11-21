# Security

Ferret can read your clipboard, your phone's notifications and texts, and move your mouse. So you should know exactly what it protects you from, and what it doesn't. Here is the honest list.

> **TL;DR**
>
> 1. Someone else on your Wi-Fi can't read or change what your devices send each other, and can't get in without you saying yes.
> 2. A device you paired is trusted. It can do what you allowed on its page, and it can add devices to your other ones.
> 3. On a Mac, Ferret's key sits in your login keychain. On Windows and Linux it's a file anything running as you can read.

Found a hole? Please report it privately, see [SECURITY.md](https://github.com/simonpham/ferret/blob/main/SECURITY.md).

## 🔐 How a connection works

- **Transport.** TCP on your network. Each frame starts with a 2-byte length, as Noise suggests.
- **Encryption.** `Noise_XX_25519_ChaChaPoly_SHA256` with the prologue `ferret/1`. The handshake lives in `packages/transport`, on top of the X25519, ChaCha20-Poly1305 and SHA-256 of the Dart `cryptography` package. It's checked byte for byte against the cacophony test vectors.
- **Nonces.** One counter per direction, starting at zero for every connection. Every reconnect runs a new handshake with new ephemeral keys. There is no rekey inside a connection: the counter would need 2⁶³ messages to run out, and Ferret stops before it.
- **Identity.** Each device has a long-term X25519 key. Its device id is the first 80 bits of the key's SHA-256, written in base32. Pairing stores the **whole key**, and every later connection must present exactly that key. A device id alone never gets anyone in.
- **Messages.** Up to 64 MiB once paired, split into Noise frames. Before pairing: 64 KiB.

## 🤝 How pairing works

There are two ways, and both bind the pairing to one Noise handshake, so nobody in the middle can reuse it.

- **Scanning a QR code** (or opening a pairing link). The code carries the device's key and a 16-byte one-time secret. The scanner checks the key, then proves it saw the secret with HMAC-SHA256(secret, handshake hash). The code works once, for 5 minutes, and **whoever scans it pairs without a question**. Treat it like a password: show it, don't post it.
- **Comparing six digits.** The asking side commits to a random nonce (sends its hash), the other side sends its own nonce, then the first one is revealed. Both screens show six digits from HMAC-SHA256(handshake hash, both nonces). Neither side can steer the digits, so someone in the middle gets one guess in a million per try. Both people must say yes.

## 🧱 What Ferret protects you from

- **Someone on the same Wi-Fi** (a café, a hotel, a compromised router). They can't read anything your devices send each other, change it, or pretend to be one of your devices.
- **A stranger who tries to connect.** Before pairing, all a device can do is finish a Noise handshake and ask to pair. At most 4 strangers at a time, each with messages of up to 64 KiB and a time limit on every answer. Nothing is handled before you said yes, except the pairing messages themselves.
- **Pairing prompts on repeat.** Say **Not now** to a request, or let it time out, and that address and that device can't ask again for 60 seconds. Each new no doubles the wait, up to 10 minutes. Those requests are turned down without a prompt. Paired devices and QR codes never wait.
- **A paired device adding or removing others behind your back.** With **Pair once for all my devices** on (the default), a paired device can ask to add a device to your other ones, or to remove one. Each of your devices asks you first: **Pixel 7 wants to add Anna's iPad to your devices** with **Add** or **Not now**, and **… wants to remove ThinkPad X1 from this Mac** with **Remove** or **Keep**. Nothing changes before your yes. No answer within a day counts as **Not now** for an addition and **Keep** for a removal. A device added this way starts with the same features turned off as the one that added it.
- **Spoofed announcements.** Ferret only uses what a device announces as a hint where to dial. Who answers must hold the key it paired with, or the connection drops. A forged announcement can't unpair anything.
- **Web pages in your browser.** The browser extension's bridge listens on `127.0.0.1` only, checks the `Origin` and `Host` headers before anything else, and needs a token you allowed. See the [browser bridge protocol](https://github.com/simonpham/ferret/blob/main/extensions/browser/PROTOCOL.md).
- **Apps that copy your key** (Mac). The key lives in your login keychain, under `io.sofluffy.ferret`, never synced to iCloud and never moved to another Mac. Only Ferret reads it without a question. Any other app makes macOS ask you first.
- **Other people's accounts on a shared computer** (macOS and Linux). Ferret's folder is `chmod 700`, its secrets file `600`. On Windows it sits in your profile folder, which only you and administrators can open.
- **Files with tricky names.** A received name never becomes a path: no `..`, no folders it didn't create, no drive letters, no Windows device names like `CON`, no marks that flip text direction, and it never overwrites a file. Quick Share and LocalSend senders aren't paired, so every one of their offers asks you first, and nothing they send is saved before your yes.

## ⚠️ What it doesn't protect you from

- **A device you paired.** It's yours, so it's trusted. It can use every feature you left on in **What Pixel 7 can use**. Files from it arrive without a question (turn that off in Drop's settings).
- **A device you just paired.** For 2 minutes after you pair a device by hand, the devices it brings along join without a question: the pairing prompt just named them. After that, every addition asks. Don't want any of it? Turn **Pair once for all my devices** off.
- **Apps running as you.** On Windows and Linux the key is still a file your user account can read, so any program you run can copy it and pretend to be this computer. That's the same deal as your SSH keys. Your paired devices sit in a file on every computer, Mac included, so an app running as you could add one. And `app_control.json` lets anything running as you drive the app, the way `ferret-cli` does. If malware runs as you, it has your clipboard anyway.
- **Someone with your unlocked device.** They can open Ferret, pair a new device, or read what's on the screen.
- **Being seen on the network.** Your device announces its name, kind and device id on every Wi-Fi it joins, so someone there can tell it's the same device as yesterday. **Pause** Ferret on networks you don't trust. Anyone can also see that two addresses talk, and roughly how much.
- **Hook scripts that trust their input.** A [hook](../features/scripting.md#-hooks) gets the other device's name in `FERRET_DEVICE_NAME`. That device picks its own name, so quote it in your script.
- **Denial of service.** Anyone on your network can keep Ferret busy, fill its 4 pairing slots, or flood it. Ferret limits what that costs, but can't stop it.

## 🔑 Where the key lives

| Device | The key | Your paired devices |
|---|---|---|
| iPhone, Android | The system keychain (Keystore on Android) | The same |
| Mac | Your login keychain | `~/.sofluffy/ferret/secrets`, readable only by you |
| Windows, Linux | `secrets` in Ferret's folder, readable only by you | The same |
| `ferret-cli` | `cli/secrets`, readable only by you | The same |

- **Coming from an older Ferret on a Mac?** On its first start, Ferret writes the key to the keychain, reads it back and checks it. Only then does the file lose the key and keep a marker. If the keychain says no, the key stays in the file and Ferret tries again next time. Your devices stay paired either way.
- **Windows and Linux** come later: DPAPI on Windows, the Secret Service (GNOME Keyring, KWallet) on Linux.
- **Why not `ferret-cli`?** It's a small command you run in a Terminal, and macOS ties a keychain item to the exact program that saved it. A copy you built yourself, or a new version, would make macOS ask on every run. Through Apple's `security` tool there's no question at all, but then any app can read it the same way, which beats the point. So the CLI keeps its own key in a file. It's a device on its own page: turn off what it doesn't need, or forget it when you're done.

## 🔍 What hasn't been checked

- No outside audit yet. If you know your way around Noise, a look at `packages/transport` and `packages/engine` is the most useful thing you can do.
- The primitives come from a pure-Dart library. They are correct against the test vectors, but nobody has checked them for timing side channels.

## Happy Coding 🦊
