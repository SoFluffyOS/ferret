---
order: 5
---
# Ferret on iPhone

> **TL;DR**
>
> 1. Install Ferret on your iPhone and on your computer, and open both.
> 2. On the iPhone, tap **Scan the code on your computer**. On the computer, click **Pair with a QR code**. Point the camera at it.
> 3. Keep Ferret open on the iPhone while you use it with your computer.

An iPhone plays by Apple's rules. Ferret follows them, and tells you where they bite instead of failing in silence.

> ⏳ **Not in the first release yet.** The iPhone app isn't on the App Store. Today you build it from source with Xcode, like any Flutter app: see **Build from source** in the [README](https://github.com/simonpham/ferret#readme). This page is how it works once it's on your phone.

<figure class="shot shot-narrow">
  <img src="/assets/docs/iphone-home-light.webp" alt="Ferret on an iPhone: a connected computer with Send files and Send clipboard" width="380" height="822" loading="lazy">
</figure>

## 📷 Pair by scanning

An iPhone can't look for devices on the network by itself: Apple keeps that for apps it hands a special permission. So your iPhone never shows up under **Nearby** on your computer, and the computer never shows up on the iPhone.

Scan instead:

1. On your computer, open Ferret and click **+**, then **Pair with a QR code**.
2. On the iPhone, open Ferret and tap **Scan the code on your computer**. The camera opens straight away.
3. Point it at the code. That's it.

The iPhone's **Camera** app works too: point it at the code and tap **Open in Ferret**.

The first time, iOS asks whether Ferret may find and connect to devices on your local network. Tap **Allow**. Said no? The pairing says it couldn't reach the computer, with an **Open Settings** button: turn on **Local Network** for Ferret.

More about codes and the other ways in [Pair your devices](pairing.md).

## ⏸️ Keep Ferret open

iOS stops apps soon after you leave them. So Ferret on an iPhone syncs **while it's open**, and pauses when you switch away or lock the phone.

- The iPhone's home screen says so at the bottom: **Keep Ferret open to sync**.
- Your computer says it too. A paused iPhone reads **Connects when Ferret is open on it**, not "offline". Nothing is broken.
- Open Ferret again and it reconnects by itself.

## 💎 What works, and how

| | On the iPhone |
|---|---|
| Copy on the computer, paste on the iPhone | Arrives while Ferret is open |
| Copy on the iPhone, paste on the computer | Tap **Send clipboard**, then allow the paste. iOS only lets apps read the clipboard when you ask |
| Files from the computer | Saved in Ferret's folder in the Files app, while Ferret is open |
| Files to the computer | **Send files…** on the device |
| Your iPhone's screen on the Mac | Use AirPlay: see [Mirroring from an iPhone](../features/mirroring-from-iphone.md) |

Ferret feels like an iPhone app where it matters: swipe from the left edge to go back.

## 🍎 With a Mac

Your Mac already does a lot with your iPhone: AirDrop, Universal Clipboard, calls and messages. Keep using those. Ferret adds what Apple doesn't: the same tools with your Android phone and your Windows or Linux PC, and your iPhone in that mix.
