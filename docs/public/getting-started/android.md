# Ferret on Android

> **TL;DR**
>
> 1. Install Ferret and open it once.
> 2. Allow notifications, so you can see that Ferret is running.
> 3. Turn off battery optimization for Ferret (and your phone maker's own killer, see below).
> 4. Add the **Ferret** tile to Quick Settings: copy something, tap the tile, and it's on your laptop.

Android loves to stop apps in the background. That is the number one reason apps like Ferret "lose" your phone.

Ferret runs a small background service, shows one quiet notification while it does, and reconnects the moment your phone wakes up or changes network.

## 📦 Install

Install the Ferret APK on your phone and open it. Open Ferret on your computer too, on the same Wi-Fi: it shows up under **Devices near you**. Tap **Pair** and check that both screens show the same six digits. See [Pair your devices](pairing.md).

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

Android's battery optimization can put Ferret to sleep. Ferret asks you to turn it off when you turn on something that needs to stay connected. You can also do it yourself: **Settings → Apps → Ferret → App battery usage → Unrestricted**.

Some phone makers add a second killer on top. Ferret detects your phone's maker and opens the right screen when it can. Here is where to look:

- **Xiaomi, Redmi, POCO:** Settings → Apps → Manage apps → Ferret → turn on **Autostart**, and set **Battery saver** to **No restrictions**. Lock Ferret in the recent apps view (long-press its card, then the lock).
- **Samsung:** Settings → Battery → Background usage limits → **Never sleeping apps** → add Ferret. Then Settings → Apps → Ferret → Battery → **Unrestricted**.
- **OnePlus:** Settings → Apps → Ferret → Battery usage → turn on **Allow background activity**. Lock Ferret in the recent apps view.
- **Huawei, Honor:** Settings → Battery → App launch → Ferret → turn off **Manage automatically**, then turn on **Auto-launch**, **Secondary launch** and **Run in background**.
- **Oppo, realme:** Settings → Apps → Ferret → Battery usage → turn on **Allow background activity** and **Allow auto launch**.
- **Vivo, iQOO:** Settings → Battery → Background power consumption management → Ferret → **Allow**. Turn on **Autostart** for Ferret in i Manager too.

Menus move between versions. When in doubt, [dontkillmyapp.com](https://dontkillmyapp.com) has the steps for your exact phone.

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

Ferret doesn't start by itself after a restart unless you ask for it. Turn on **Start when the phone starts** in Ferret's settings, and it's back as soon as you unlock your phone.

## 🔄 After sleep and Wi-Fi changes

Ferret reconnects right away when:

- your phone joins a network, or its Wi-Fi changes,
- the screen turns on, or the phone leaves deep sleep,
- you open the app.

It checks which connections still answer, replaces the ones that died, and calls your paired devices at their last known address without waiting for discovery. No polling in between, so it stays light on battery.

🦊

## 🔓 Power-ups

Want more? With [Shizuku](../android-modes/shizuku.md) or [root](../android-modes/root-magisk.md), Ferret can send your clipboard on its own and set itself up in one tap. Start with [what works without them](../android-modes/standard.md).
