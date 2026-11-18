# Clipboard

> **TL;DR**
>
> 1. Pair your devices.
> 2. Copy on one.
> 3. Paste on the other. That's it.

You copy a link on your phone and need it on your laptop. Emailing it to yourself is silly.

With Ferret, what you copy on one device lands on the clipboard of your other devices. Text, links and images. No button to press on your computers.

## 📋 How it works

- Copy something on your Mac, Windows or Linux computer.
- Ferret sends it to your connected devices right away.
- Paste it there.

Nothing to open, nothing to press. **Activity** on the home screen keeps the trace: "Copied on Pixel" or "Sent to Laptop", with the first words and a **Copy** button.

Copied while your other device was asleep? If it reconnects within 2 minutes, it still gets your last copy. Older copies are never replayed.

## 🤖 On Android: tap Send clipboard

Android doesn't let apps read your clipboard in the background. No app can, not just Ferret.

So on Android:

1. Copy something.
2. Tap **Send clipboard** in the Ferret notification, the Quick Settings tile, or on your computer's row in Ferret.

Going the other way needs nothing: what you copy on your computer lands on your phone's clipboard on its own.

Want it automatic anyway? With [Shizuku or root](../android-modes/shizuku.md), tap **Turn on** next to Clipboard in **Do more** on the home screen (or the **Send automatically in the background** switch in **Settings → Clipboard**) and Ferret sends what you copy on its own (text only).

## 🍎 On iPhone and iPad

iOS asks before an app reads your clipboard, and only while it is open. Open Ferret, tap **Send clipboard**, and allow the paste.

Receiving works while Ferret is open.

## 🔑 Passwords stay put

Password managers mark what they copy as private. Ferret skips those items by default.

If you turn on **Include passwords**, they are sent marked as private, never shown in Activity, kept out of clipboard history on the other device, and dropped from Ferret's memory after 2 minutes.

## ⚙️ Settings

In **Settings → Clipboard**:

- **Send automatically**: send what you copy here. On by default.
- **Receive automatically**: put what arrives straight on this clipboard. Turn it off and tap **Copy** next to what arrived instead.
- **Images**: sync copied images up to 10 MB.
- **Include passwords**: sync items that password managers mark as private. Off by default.
- **Clear history**: Ferret keeps the last 20 items in memory, never on disk.

The Settings row says how it's set: **Syncs by itself**, **Sends by itself** or **Send by hand**.

Each device page also has **Send clipboard**, to send to just that device. Under **What works** it says which side sends by itself and which side sends by hand.

## 🧭 Limits per platform

| Platform | Sends on its own | Receives | Private items detected |
|---|---|---|---|
| macOS | ✅ | ✅ | Concealed and transient types, set by most password managers |
| Windows | ✅ | ✅ | Items kept out of Windows clipboard history |
| Linux | ✅ | ✅ | KeePassXC and KDE password hint |
| Android | Tap **Send clipboard**, or on its own with Shizuku or root | ✅ | Items marked sensitive (Android 13+) |
| iOS | Tap **Send clipboard** | While open | Concealed type |

On Linux, images need `wl-clipboard` (Wayland) or `xclip` (X11). Text works without them.

Nothing you copy is logged, and nothing leaves your network.
