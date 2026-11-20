# Ferret on Android

> **TL;DR**
>
> 1. Install Ferret and open it once.
> 2. Allow notifications, so you can see that Ferret is running.
> 3. Turn off battery optimization for Ferret (and your phone maker's own killer, see below).
> 4. Add the **Ferret** tile to Quick Settings: copy something, tap the tile, and it's on your laptop.

Android loves to stop apps in the background. That is the number one reason apps like Ferret "lose" your phone.

Ferret runs a small background service, shows one quiet notification while it does, and reconnects the moment your phone wakes up or changes network.

<figure class="shot shot-narrow">
  <img src="/assets/docs/android-home-light.webp" alt="Ferret on an Android phone: a connected Mac with Send files, Send clipboard and Ring" width="380" height="822" loading="lazy">
  <img src="/assets/docs/android-home-dark.webp" alt="Ferret on an Android phone: a connected Mac with Send files, Send clipboard and Ring" width="380" height="822" loading="lazy">
</figure>

## 📦 Install

Install the Ferret APK on your phone and open it. Open Ferret on your computer too, on the same Wi-Fi: it shows up under **Nearby**. Tap **Pair** and check that both screens show the same six digits. See [Pair your devices](pairing.md).

That's it. Ferret now keeps running when you close the app.

## 🔔 The notification

Android requires a notification while an app runs in the background. Ferret keeps it useful and silent:

- **Connected to MacBook** when a paired device is connected, or **Waiting for your devices** when none is around.
- **Send clipboard** sends what you copied to your connected devices.
- **Pause 1 h** stops all networking for an hour. Tap **Resume** to come back early.
- Tap the notification to open Ferret.

On Android 13 and later, Ferret asks before showing notifications. If you say no, Ferret still runs. You just won't see the notification.

Don't want to see it at all? Long-press it, then turn off the **Stay connected** category. Ferret keeps running.

## 🔋 Battery settings

Android's battery optimization can put Ferret to sleep, and some phone makers add a second killer on top.

Ferret shows what is in the way on its **Stay connected** card, each with a **Fix** button. For your phone maker it writes the exact steps under the button.

The short version: **Settings → Apps → Ferret → App battery usage → Unrestricted**.

Samsung, Xiaomi, OnePlus, Oppo, Huawei or Vivo? See [Keep Ferret running on Android](android-keep-running.md) for the steps on your phone.

Ferret notices when Android stopped it anyway, and tells you: "Android stopped Ferret 3 times today". That is your hint to check these settings.

## ⚡ The Quick Settings tile

Android doesn't let apps read your clipboard in the background. The **Ferret** tile is the one-tap workaround:

1. Pull down Quick Settings, tap the pencil, and drag **Ferret** into your tiles. On Android 13 and later, Ferret can add it for you.
2. Copy something.
3. Tap the tile. Your clipboard is on your laptop.

Easy, right?

- The tile shows the connected device under its name, or **Not connected**.
- Long-press the tile to open Ferret.

## 🚀 Start when the phone starts

Ferret asks you once, on the **Stay connected** card: **Start Ferret when Pixel 7 restarts?** Tap **Yes** and it's back as soon as you unlock your phone after a restart. Tap **Not now** and it reconnects only when you open it.

Either way, Ferret comes back by itself right after an update. Changed your mind? **Settings → Background → Start when the phone starts**.

## 🔄 After sleep and Wi-Fi changes

Ferret reconnects right away when:

- your phone joins a network, or its Wi-Fi changes,
- the screen turns on, or the phone leaves deep sleep,
- Android lets Ferret back on the network,
- you open the app.

It checks which connections still answer, replaces the ones that died, and calls your paired devices at their last known address without waiting for discovery. While none of your devices is connected, it looks again every 15 minutes, without waking the phone for it. So it stays light on battery.

🦊

## 🔓 Power-ups

Want more? With [Shizuku](../android-modes/shizuku.md) or [root](../android-modes/root-magisk.md), Ferret can send your clipboard on its own and set itself up in one tap. Start with [what works without them](../android-modes/standard.md).
