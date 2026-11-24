---
order: 5
---
# Ferret on iPhone

> **TL;DR**
>
> 1. Install Ferret on your iPhone and on your computer, and open both.
> 2. Tap **Pair** next to the iPhone under **Nearby** on your computer. Not there? Tap **Scan the code** on the iPhone and point it at the computer's QR code.
> 3. Keep Ferret open on the iPhone while you use it with your computer.

An iPhone plays by Apple's rules. Ferret follows them, and tells you where they bite instead of failing in silence.

> ⏳ **Coming soon.** The iPhone app isn't on the App Store yet. Today you build it from source with Xcode, like any Flutter app: see **Build from source** in the [README](https://github.com/SoFluffyOS/ferret#readme). This page is how it works once it's on your phone.

<figure class="shot shot-narrow">
  <img src="/assets/docs/iphone-home-light.webp" alt="Ferret on an iPhone: a connected Mac with Send files, Send clipboard and Ring" width="390" height="844" loading="lazy">
</figure>

## 👀 Find it nearby

While Ferret is open on your iPhone, it shows up under **Nearby** on your computer. Open **+** on the computer and it shows up on the iPhone too. Tap **Pair** and check that both screens show the same six digits.

Ferret finds it with Bonjour, the same way your Mac finds AirPlay speakers and printers. No special permission from Apple needed.

## 🔑 The Local Network question

iOS asks once whether Ferret may find and connect to devices on your local network. Ferret doesn't spring that on you at launch.

It waits until you get somewhere that needs it: Home before anything is paired, **Add a device**, **Fix connection**, or scanning a code. First it shows a short card: **Ferret looks for your devices on this Wi-Fi. iOS asks once.** Tap **Continue**, then **Allow** when iOS asks.

Once a device is paired, Ferret looks from launch. Your paired devices reconnect by themselves.

Said no? **Nearby** and **Fix connection** say **Local Network is off for Ferret**, with an **Open Settings** button. Turn on **Local Network** there and come back. That's it.

## 📷 Or scan the code

Not showing up? Scan instead:

1. On your computer, open Ferret and click **+**, then **Pair with a QR code**.
2. On the iPhone, open Ferret and tap **Scan the code**. The camera opens straight away.
3. Point it at the code. That's it.

The iPhone's **Camera** app works too: point it at the code and tap **Open in Ferret**.

Haven't tapped **Continue** yet? Scanning shows the same short card first, so iOS asks with you knowing why.

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
| Files to the computer | **Share → Ferret** from Photos, Files or any app. Or **Send files…** on the device. See [Send from the file manager](../features/share-menu.md) |
| Your iPhone's screen on the Mac | Use AirPlay: see [Mirroring from an iPhone](../features/mirroring-from-iphone.md) |

Ferret feels like an iPhone app where it matters: swipe from the left edge to go back.

## 📥 Files from LocalSend

A friend with [LocalSend](../interop/localsend.md) can send to your iPhone too. Tap **Allow once** next to **Receive a file from a guest**, or turn on **Always receive from LocalSend** in **Settings → Other apps**.

It works **while Ferret is open**. Keep it on screen while they send. Switch away and Ferret stops listening cleanly, then listens again the moment you're back.

Your friend's LocalSend finds the iPhone by asking each address on the Wi-Fi. That takes a few seconds longer than usual. Not showing up? Tap refresh in LocalSend.

## 🍎 With a Mac

Your Mac already does a lot with your iPhone: AirDrop, Universal Clipboard, calls and messages. Keep using those. Ferret adds what Apple doesn't: the same tools with your Android phone and your Windows or Linux PC, and your iPhone in that mix.
