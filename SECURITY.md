# Security

Ferret carries your clipboard, files, texts and calls between your devices. A hole in it matters, so thank you for looking 🙏

## 🔒 Report a vulnerability privately

Please don't open a public issue for a security problem.

Use GitHub's private reporting instead: open the **Security** tab of this repository and click **Report a vulnerability**. Only the maintainers see it.

A good report has:

- What an attacker can do, and what they need first (same Wi-Fi? a paired device? physical access?).
- The steps to reproduce it, on which platforms and which Ferret version.
- A proof of concept, if you have one.

I'll answer within a week, keep you posted while it gets fixed, and credit you in the release notes if you want.

## 🧭 What's in scope

The threat model, with what Ferret protects you from and what it doesn't, is in [docs/spec/security.md](docs/spec/security.md).

- The pairing and the Noise XX channel (`packages/transport`, `packages/engine`).
- Anything that lets an unpaired device do more than ask to pair.
- Anything that lets a paired device do something its owner didn't allow on that device's page.
- Ferret leaking content (clipboard, notifications, texts, files, keys) to logs, other apps or the network.
- The Android power-ups (Shizuku, root, LSPosed) and the browser extension.

## 🙅 Out of scope

- Attacks that need the device unlocked in your hands already.
- A device you paired yourself doing what you allowed it to do.
- Bugs in the operating system or in Shizuku, Magisk or LSPosed themselves.

## 📦 Supported versions

Only the latest release gets security fixes.
