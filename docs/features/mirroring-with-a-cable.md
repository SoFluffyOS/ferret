# Show a phone with a cable

> **TL;DR**
>
> 1. Click **Show screen** on the phone in Ferret, then **How**.
> 2. Follow the three steps on the phone. Each one ticks itself.
> 3. The picture starts by itself. That's it.

[Screen](mirroring.md) over Wi-Fi needs Ferret on both devices, and you can only look. But sometimes the phone is a spare one, or a test phone on your desk. Or you want to click and type on it.

Ferret can show any Android phone that has debugging turned on. No Ferret on the phone, no root, nothing to install there. And this way the mouse and the keyboard work on the phone too.

> 🧪 **Beta.** It was tested on a Mac with an Android emulator, not yet on Windows and Linux.

## ✅ The steps tick themselves

You don't set this up in Settings. The steps show up where you need them:

- **Show screen** on a paired phone that isn't connected, then **How**.
- Or the **View only** chip on a picture, then **How**.

Ferret shows a checklist: plug the phone in, turn on USB debugging, tap Allow. It looks at the phone every two seconds and ticks each step as it happens. When the last one ticks, the picture starts. There is no "Try again" to press.

Opening the checklist also turns on **Look for phones on a cable** in **Settings → From your phone**, under **Screen**. Turn it off there when you're done with cables.

A phone that isn't paired with Ferret shows up under **Nearby**, on the home screen and in the window's device list, with **Show screen**.

## 🔑 Turn on debugging on the phone

Debugging is a switch Android hides until you ask for it. You do this once.

1. Open **Settings → About phone**.
2. Tap **Build number** seven times. The phone says "You are now a developer!".
3. Go back to **Settings → System → Developer options**.
4. Turn on **USB debugging**.

On some phones the names differ a little. Search the phone's settings for "Build number" and "USB debugging".

## 🔌 With a cable

1. Plug the phone into the computer.
2. The phone asks **Allow USB debugging?**. Tap **Allow**. Tick **Always allow from this computer** so it won't ask again.
3. The picture starts. That's it.

Nothing shows up? Try another cable. Many cables only charge.

## 📶 Without a cable

Android 11 and later can do the same over Wi-Fi. Both devices must be on the same network.

1. On the phone, open **Developer options** and turn on **Wireless debugging**.
2. Tap **Wireless debugging**, then **Pair device with pairing code**. The phone shows a 6-digit code and an address such as `192.168.1.20:37123`.
3. Pair from your computer with that address and code:
   ```bash
   adb pair 192.168.1.20:37123
   ```
4. Go back one screen on the phone. Under **IP address & Port** is a second address, with another port. Connect to that one:
   ```bash
   adb connect 192.168.1.20:41567
   ```

The phone now shows up in Ferret like a plugged-in one, marked **Wi-Fi debugging**.

Pairing is once per computer. The second address changes every time wireless debugging is turned on again, so `adb connect` is for each time.

## 🖱️ Control the phone

Click, drag and scroll on the picture like on a touch screen. Right-click is Back, middle-click is Home, two fingers on a trackpad scroll. Type on your keyboard, `⌘V` pastes.

The toolbar has **Back**, **Home**, **Recents**, **Rotate** and **Keyboard**. Volume, Power and the notifications panel are behind **•••**. The whole list is in [Screen](mirroring.md).

Accents and emoji just work. Ferret passes them through the phone's clipboard.

## 🔀 Paired AND plugged in

A phone with Ferret on it that is also plugged in still goes over Wi-Fi first. That way the phone asks you, like always.

Want to click and type? Click **View only → Control with the cable**. Ferret switches over, and says once that a cable doesn't ask each time.

When Ferret can't reach the phone at all, it uses the cable by itself and tells you: "Showing over the cable instead."

## 🔐 What you are allowing

Debugging is a strong permission. Be sure about it.

- A computer you allowed can see and control the phone **without asking again**. There is no prompt each time, unlike [Screen](mirroring.md) with Ferret on the phone.
- Only allow computers that are yours.
- Done? Turn **USB debugging** off again, or tap **Revoke USB debugging authorizations** in Developer options to forget every computer.

## 📦 One download, only if you ask

Ferret never talks to the internet on its own.

The small helper that captures the screen on the phone is **scrcpy's server**. It ships inside Ferret. Ferret checks it, copies it to the phone for as long as the picture runs, and it deletes itself after.

Ferret also needs **adb**, Android's tool for talking to phones. Have Android Studio? Then you have it, and Ferret uses that one.

No adb on this computer? Ferret says **Get Android's helper tool**, with a **Download** button. Click it and Ferret downloads Google's [platform tools](https://developer.android.com/tools/releases/platform-tools) from Google, about 16 MB, once. It checks the file against a fingerprint built into Ferret before it uses it, and keeps it in `~/.sofluffy/ferret/tools`. That is the only time this feature reaches the internet, and only when you click.

Nothing about you or your phone is sent anywhere. The picture goes from the phone to your computer, over the cable or your own Wi-Fi.

## 🩺 When it doesn't work

| Ferret says | What to do |
|---|---|
| Get Android's helper tool | adb isn't on this computer. Click **Download**, or install the platform tools yourself. The checklist moves on by itself |
| Start Android's helper tool | adb is here but Ferret can't start it. Open Android Studio, or run `adb start-server` in Terminal |
| Turn on USB debugging stays unticked | Follow the steps under it. Samsung and Xiaomi name things differently: open **Samsung, Xiaomi, others** |
| Many cables only charge | Nothing showed up for 20 seconds. Try another cable |
| Clicks do nothing on a Xiaomi | Also turn on **USB debugging (Security settings)** |
| Tap Allow on the phone | Unlock the phone and tap **Allow**. No question on the phone? Unplug it and plug it in again |

## 🧭 Limits

| Computer | Works |
|---|---|
| macOS | Yes |
| Windows | Written, not tested yet |
| Linux | Written, not tested yet |
| Android, iPhone | No. Showing a phone on a phone isn't offered |

- **Android 5 and later** for the picture. Wireless debugging needs Android 11.
- **Sound** needs Android 11 or later, and an unlocked phone when the picture starts. Pick where it plays in **••• → Sound**.
- **Protected screens stay black**: banking apps, password fields, DRM video.
- The picture quality is set when it starts. Pick **Fast** behind the three bars and Ferret restarts the picture with it.

## 🙏 Thanks

This works thanks to [scrcpy](https://github.com/Genymobile/scrcpy) by Genymobile, under the Apache License 2.0. Ferret ships its server as it is.
