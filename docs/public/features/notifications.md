# Notifications

> **TL;DR**
>
> 1. On your Android phone, open **Settings → Notifications** in Ferret and tap **Turn on**.
> 2. Turn on Ferret on the Notification access screen, then come back.
> 3. New messages show up on your computer. Reply or dismiss them there.

Your phone buzzes in your bag while you work. You pick it up, unlock it, and it was a message you could have answered from your keyboard.

With Ferret, your phone's notifications show up on your computer. Only new ones, only from the apps you pick, and never the same one twice.

## 🔔 How it works

- A message arrives on your phone.
- Ferret shows it on your connected computers as a normal notification, with the app's icon, grouped per phone.
- **Reply** right from the notification, or **Dismiss** it.

Dismissing works both ways: dismiss it on your computer and it's gone from your phone, dismiss it on your phone and it's gone from your computer.

The Notifications card on the home screen shows the last few from each phone. **Clear all** empties this computer's list, and your phone keeps its notifications.

## 🧘 No floods

- Only notifications posted **after** your phone connects are sent. Nothing that was already on your phone is replayed.
- The same notification is sent once. An app that re-posts it with the same text doesn't ping you again.
- Ongoing ones (music, navigation, downloads), silent ones and group summaries stay on the phone.
- Your computer was asleep? When it reconnects you get **one** summary, "6 notifications while away, from Signal, WhatsApp", not six popups.

## 📱 Pick your apps

Messaging apps are picked for you: WhatsApp, Signal, Telegram, Messages, Messenger, Discord, Slack, Element and more. Everything else stays off.

Change it in **Settings → Notifications → Choose apps**, on the phone or on your computer (your computer asks the phone for its app list).

## 🙈 Not while you're using the phone

If your phone's screen is on and unlocked, you already see the notification there. So by default Ferret doesn't mirror it.

Turn **Pause while I'm using the phone** off if you want them on your computer anyway.

## 🔑 "Android blocked this setting"

On Android 13 and later, Android greys out the Notification access switch for apps installed from a file or from some app stores. Ferret detects it and shows the steps:

1. Tap **Open App info**.
2. Tap **⋮** in the top corner, then **Allow restricted settings**.
3. Come back and open notification access again.

Can't see **Allow restricted settings**? Tap the greyed-out switch once first, then look again.

## 🧭 Limits per platform

| Platform | Sends its notifications | Shows a phone's notifications |
|---|---|---|
| Android | ✅ With notification access | Not yet |
| macOS | No | ✅ Reply and Dismiss |
| Windows | No | ✅ Reply and Dismiss |
| Linux | No | ✅ Reply and Dismiss where your desktop supports actions |
| iOS | No, iOS doesn't let any app read other apps' notifications | While Ferret is open |

Reply works for apps that offer a reply button in their own notification, like most chat apps. Other buttons stay on the phone.

Notification text is never logged and never leaves your network.
