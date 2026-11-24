---
order: 3
---
# Root (Magisk, KernelSU, APatch)

> **TL;DR**
>
> 1. Your phone is rooted already? Open **Settings → Control → Open Power-ups**.
> 2. Read the warning, then tap **Use root** and confirm in your root manager.
> 3. Turn on **Send automatically in the background** in **Settings → Clipboard**.

[Shizuku](shizuku.md) stops every time your phone restarts. On a rooted phone Ferret can ask root directly, and that survives a restart.

This page is for phones that are rooted already. Ferret never roots a phone, and you don't need root for anything: Shizuku adds the same features.

> ⚠️ Root gives an app full control of your phone. Turn it on only if you rooted the phone yourself and know what that means.

> 🧪 This mode is new. Its helper was tested on an Android 15 emulator, but not yet through `su` on a rooted phone. Treat it as beta.

## 🔑 Turn it on

1. Open **Settings → Control → Open Power-ups** and scroll to **Root**.
2. Ferret says which root manager it found: Magisk, KernelSU or APatch.
3. Tap **Use root**. Your root manager asks you to confirm.

Ferret only looks for root until you tap that button. It never runs `su` before.

On KernelSU and APatch, allow Ferret in the manager app first. They hide root from apps that aren't on their list.

## 💎 What you get

The same as with Shizuku:

- **Clipboard sent on its own**, once **Send automatically in the background** is on.
- **Notification access** and **background running** in one tap.

Plus one thing: it **keeps working after a restart**. Nothing to start again.

## 🔍 What Ferret runs as root

One thing: its own helper, from Ferret's own APK, started with `su`.

Ferret asks `su` to start the helper as Android's shell user, not as root. The shell user is enough to read the clipboard, so the helper gets no more than that. If your `su` can't switch user, the helper runs as root.

The helper is the same one Shizuku runs. It reads the clipboard text, turns on Ferret's notification access, and exempts Ferret from battery optimization. Nothing else, and only when you asked. The table on the [Shizuku page](shizuku.md) lists each one.

Tap **Stop using root** and the helper stops. Take the permission back in your root manager whenever you like.

## 📦 The Magisk module (optional, beta)

The repository has a Magisk module template in [`magisk/`](https://github.com/SoFluffyOS/ferret/tree/main/magisk). It installs Ferret as a privileged system app, for system permissions later versions may use.

You don't need it for anything on this page. It has not been tested on a phone. Read its README before you flash it.

## 🧭 Limits

- **Text only**, up to 200,000 characters per copy, as with Shizuku.
- Root was denied or taken away? A **Power-ups** card says so, with **Ask again** and **Stop using root**.
- Hiding root from other apps is your root manager's job. Ferret doesn't touch it.
