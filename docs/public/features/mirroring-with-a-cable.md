# Mirror a phone without Ferret on it

> **TL;DR**
>
> 1. On the phone, turn on **USB debugging** (or **Wireless debugging**).
> 2. Plug it into your computer and tap **Allow** on the phone.
> 3. In Ferret on the computer, pick the phone under **Screens you can show** and click **Show**.

[Screen mirroring](mirroring.md) needs Ferret on both devices. But sometimes the phone isn't yours to set up, or it is a spare one, or a test phone on your desk.

Ferret can show any Android phone that has debugging turned on. No Ferret on the phone, no root, nothing to install there. And this way you can click and type on the phone too.

> 🧪 This is experimental. Turn on **More ways to show a screen** in **Settings → Screen mirroring** on your computer first. It was tested on a Mac with an Android 15 emulator, not yet with a real phone or on Windows and Linux.

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
3. The phone shows up in Ferret under **Screens you can show**. Click **Show**.

That's it.

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

The phone now shows up in Ferret like a plugged-in one, marked **On your network**.

Pairing is once per computer. The second address changes every time wireless debugging is turned on again, so `adb connect` is for each time.

## 🖱️ Control the phone

Click, drag and scroll on the picture like on a touch screen. Type on your keyboard. The buttons under the picture are **Back**, **Home** and **Recent apps**.

Accents and emoji don't go through the keyboard. Copy the text on the computer and paste it instead.

## 🔐 What you are allowing

Debugging is a strong permission. Be sure about it.

- A computer you allowed can see and control the phone **without asking again**. There is no prompt each time, unlike [Screen mirroring](mirroring.md) with Ferret on the phone.
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
| Get Android's helper tool | adb isn't on this computer. Click **Download**, or install the platform tools yourself, then **Check again** |
| Start Android's helper tool | adb is here but Ferret can't start it. Open Android Studio, or run `adb start-server` in Terminal, then **Check again** |
| The phone needs one setting turned on | Turn on USB debugging, as above |
| Allow this computer on the phone | Unlock the phone and tap **Allow**. No question on the phone? Unplug it and plug it in again |

## 🧭 Limits

| Computer | Works |
|---|---|
| macOS | Yes |
| Windows | Written, not tested yet |
| Linux | Written, not tested yet |
| Android, iPhone | No. Showing a phone on a phone isn't offered |

- **Android 5 and later** for the picture. Wireless debugging needs Android 11.
- **No sound.** Only the picture is sent.
- **Protected screens stay black**: banking apps, password fields, DRM video.
- The picture quality is set when it starts. It doesn't adapt to a slow Wi-Fi while running.

## 🙏 Thanks

This works thanks to [scrcpy](https://github.com/Genymobile/scrcpy) by Genymobile, under the Apache License 2.0. Ferret ships its server as it is.
