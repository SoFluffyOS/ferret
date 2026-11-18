---
order: 1
---
# iPhone with a Windows or Linux PC

> **TL;DR**
>
> 1. In Ferret on the computer, open **Settings → iPhone** and turn on **Connect an iPhone**.
> 2. Pair the iPhone with the computer over Bluetooth, and allow it to share notifications.
> 3. Pick the iPhone in Ferret. That's it.

Your iPhone buzzes on the desk. You're at your PC. You pick the phone up, read, put it down. Twenty times a day.

Ferret brings the iPhone's notifications and its music controls to your computer. Over Bluetooth. With **nothing to install on the iPhone**.

Every iPhone already offers this to a paired Bluetooth device. It's how smartwatches get your notifications. Ferret speaks the same two services: Apple's notification service (ANCS) and Apple's media service (AMS).

## 💎 What works

- **Notifications, as they arrive.** App, title and text, grouped by app.
- **Their actions.** **Clear** removes it on the iPhone too. A call shows **Answer** and **Decline**. A missed call shows **Call back**.
- **Now playing on iPhone.** A card with the track, where it is, and play, pause, next, previous and volume.
- **Automatic reconnect.** Walk away, come back, it picks up again.

Nothing leaves your desk. Bluetooth only, no account, no cloud.

## 🚧 What doesn't work yet

- **Texts as conversations.** You see the notification for an SMS or iMessage. You can't read the thread or reply.
- **Calls on the computer.** You can answer or decline from the PC, but you talk on the iPhone.
- **Files, clipboard, handoff.** Apple keeps those for its own devices.

The why and the plan are in [Limits](limits.md).

## 🔑 Set it up

The first pairing is different on each system. Pick yours:

- [Windows](windows.md)
- [Linux](linux.md)
- [macOS](mac.md) (experimental)

## 🔔 How notifications behave

- **New ones only.** What was already on the iPhone when it connects stays on the iPhone. No flood after a reconnect.
- **A burst stays quiet.** After the first few in a row, the rest arrive without a sound.
- **Gone there, gone here.** Read it on the iPhone and the notice leaves your computer.
- **Actions do the real thing.** **Clear** clears it on the iPhone. If the iPhone is out of reach, Ferret tells you it didn't get there.

## ⚙️ Settings

In **Settings → iPhone**:

- **Connect an iPhone**: off by default. Turning it on is when Ferret first touches Bluetooth.
- **Show notifications**: turn it off to keep only the media card.
- **Hide what notifications say**: show only which app it is. For when others can see your screen.
- **Media controls**: the "Now playing on iPhone" card.
- **Use another iPhone**: forget the one you picked.

## 🩺 When it doesn't work

Ferret says what's wrong, on the home card and in Settings:

| Ferret says | What to do |
|---|---|
| **Bluetooth is off** | Turn it on. **Open Bluetooth settings** takes you there |
| **Pick your iPhone** | Pair it first, then choose it. See the page for your system |
| **iPhone isn't sharing with this computer** | On the iPhone: **Settings → Bluetooth → ⓘ** next to your computer → turn on **Share System Notifications** |
| **iPhone is out of reach** | Nothing. Ferret reconnects when it's back |
| **Ferret can't use Bluetooth** | Allow Bluetooth for Ferret in your system's privacy settings |

Still stuck? Remove the pairing on **both** sides (**Forget This Device** on the iPhone), then pair again.
