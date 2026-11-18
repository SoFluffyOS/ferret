---
order: 2
---
# Shizuku

> **TL;DR**
>
> 1. Install [Shizuku](https://shizuku.rikka.app/download/) and start it.
> 2. In Ferret, open **Settings → Power-ups → Open Power-ups** and tap **Allow Ferret**.
> 3. Turn on **Send automatically in the background** in **Settings → Clipboard**.
> 4. Copy anywhere on your phone. It lands on your other devices.

Android doesn't let apps read your clipboard in the background. So in [Standard mode](standard.md) you tap **Send clipboard** after every copy.

Shizuku fixes that without rooting your phone. It is a free, open-source app that lets other apps do a few things Android keeps for the system. You stay in charge: every app has to ask, and you can take the permission back in Shizuku at any time.

> 🧪 This mode is new. Its helper was tested on an Android 15 emulator, but not yet through Shizuku on a real phone. If it misbehaves on yours, tap **Stop using Shizuku** and tell us.

## 📦 Set it up

Ferret walks you through it, one button per step:

1. **Install Shizuku.** Tap **Get Shizuku**. It is on F-Droid too.
2. **Start Shizuku.** Tap **Open Shizuku** and follow its Start steps. On Android 11 and later that is wireless debugging, no computer needed. On older phones you run one command from a computer.
3. **Allow Ferret.** Come back to Ferret and tap **Allow Ferret**. Shizuku asks you to confirm. Choose **Allow all the time**.

Ferret checks again every time you come back to it, so each step ticks itself off.

That's it.

## 💎 What you get

- **Clipboard sent on its own.** Turn on **Send automatically in the background** in **Settings → Clipboard**. Text you copy in any app goes to your connected devices, also while Ferret is closed.
- **Notification access in one tap.** **Turn on now** on the ladder, with no trip through the system settings and no "restricted setting" block.
- **Background running in one tap.** **Turn on** under *Keep Ferret running in the background* exempts Ferret from battery optimization.

Everything else on the ladder stays the same.

## 🔁 After a restart

Shizuku stops when your phone restarts. Android gives it no way around that without root.

Ferret tells you: a **Power-ups** card shows up on the home screen with an **Open Shizuku** button. Start Shizuku again and background clipboard picks up where it left off. Until then **Send clipboard** works as always.

## 🔑 What Ferret does with it

Ferret runs a small helper through Shizuku. The helper can do exactly three things:

| What | How | When |
|---|---|---|
| Read the clipboard text | Asks Android's clipboard service, as the shell user | Only while **Send automatically in the background** is on |
| Turn on Ferret's notification access | `cmd notification allow_listener` for Ferret's own listener | Only when you tap **Turn on now** |
| Exempt Ferret from battery optimization | `cmd deviceidle whitelist` for Ferret's own package | Only when you tap **Turn on** |

There is no way to make the helper run anything else. It can't run a command Ferret sends it; the three above are built in.

And the usual rules hold:

- Items a password manager marks as private are skipped, unless you turned on **Private items**.
- Nothing you copy is logged.
- Nothing leaves your network.

## 🧭 Limits

- **Text only.** Images still need **Send clipboard**.
- **Up to 200,000 characters** per copy in the background.
- Android may show its own "pasted from your clipboard" notice when the helper reads a copy.
- Nothing runs until you tapped **Allow Ferret**. Tap **Stop using Shizuku** in Power-ups and it all stops.
