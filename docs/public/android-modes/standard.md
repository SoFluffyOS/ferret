---
order: 1
---
# Standard

> **TL;DR**
>
> 1. Install Ferret. You are on the Standard mode already.
> 2. Turn on the features you want. Ferret asks for each permission when it needs it.
> 3. Want your clipboard sent on its own? That needs [Shizuku](shizuku.md) or [root](root-magisk.md).

Android gives every app the same small set of abilities. More needs your say-so, one permission at a time.

Ferret shows this as a ladder in **Settings → Power-ups → Open Power-ups**. Each step lists what it adds, with a lock on what your phone doesn't have yet.

## 🪜 The ladder

| Step | What you do | What it adds |
|---|---|---|
| **Basic** | Nothing | Files, **Send clipboard** by tap, handoff, media controls, find my device |
| **+ Notifications** | Turn on notification access | Your phone's notifications on your other devices, with replies |
| **+ Messages & calls** | Allow SMS and phone when asked | Text messages and calls from your computer |
| **+ Shizuku** | [Set up Shizuku](shizuku.md) | Clipboard sent on its own, one-tap setup |
| **+ Root** | [Use root](root-magisk.md) | The same, and it survives a restart |

You don't have to climb it. Basic works on its own, and every step is optional.

## 🔔 Notification access

Tap **Open notification access** on the ladder and turn Ferret on in the list.

Android says the setting is restricted? That happens on Android 13 and later when an app was installed from an APK and not from a store.

1. Tap **App info** on the ladder.
2. Tap the three dots in the corner.
3. Choose **Allow restricted settings**.
4. Go back and turn notification access on.

Easy, right? With Shizuku or root, Ferret does all of it for you with one tap.

## 💬 Messages and calls

Ferret asks for these the first time you turn on **Messages** or **Calls**. Said no by mistake? Tap **App info** on the ladder, then **Permissions**.

## 📋 The clipboard limit

Android doesn't let apps read your clipboard in the background. No app can, not just Ferret.

So in Standard mode you copy, then tap **Send clipboard** in the Ferret notification, the Quick Settings tile or the Clipboard card. See [Clipboard](../features/clipboard.md).

Going the other way needs nothing: what you copy on your computer lands on your phone on its own.

## 🧭 What Standard mode never does

- It never runs anything as another user.
- It never looks for Shizuku or root beyond checking whether they are there.

That is the only way to keep a normal install boring and safe.
