---
order: 5
---
# Limits, and what comes next

An iPhone gives a paired Bluetooth device a short list of things. Ferret uses two of them today. Here's the whole picture, and the plan for the rest.

## 🧭 What an iPhone offers over Bluetooth

| What | Bluetooth profile | In Ferret |
|---|---|---|
| Notifications and their actions | ANCS (Bluetooth LE) | **Yes** |
| What's playing, media controls | AMS (Bluetooth LE) | **Yes** |
| Text messages (SMS and iMessage) | MAP (classic Bluetooth) | Planned |
| Contact names for messages and calls | PBAP (classic Bluetooth) | Planned, with messages |
| Calls: ring, answer, talk | HFP (classic Bluetooth) | Planned |
| Files, clipboard, handoff, photos | None. Apple devices only | No |

## 🔔 Limits of notifications today

- **No app icons.** The iPhone sends the app's name, not its icon.
- **No inline reply.** The iPhone offers at most two actions per notification: a positive one (**Answer**) and a negative one (**Clear**, **Decline**). Typing a reply isn't one of them.
- **Text is cut at 256 bytes.** Enough for a preview, not for a long message.
- **The time is the iPhone's local time.** Ferret assumes your computer is in the same time zone.
- **One listener.** If another app on the computer (Phone Link, a watch tool) holds the iPhone's notification service, Ferret may get nothing.
- **Bluetooth range.** About 10 metres. Out of reach means no notifications, and nothing is queued: what you missed stays on the iPhone.

## 🎵 Limits of media today

- **No artwork.** The iPhone doesn't send covers over this service.
- **No seeking.** Play, pause, next, previous and volume steps only.
- **Volume in steps.** Up and down, the same as the iPhone's side buttons.
- The position moves on by itself between updates from the iPhone, so it can be a second off.

## 💬 Plan: messages (MAP)

The Message Access Profile is how car screens show your texts. With it Ferret can list recent messages, show new ones as conversations, and send a text.

1. **Classic Bluetooth link.** MAP runs over classic Bluetooth (RFCOMM and OBEX), not the low-energy link Ferret uses today. Windows has it through its RFCOMM APIs; Linux through BlueZ's `obexd` (`org.bluez.obex.MessageAccess1`).
2. **Read.** Open a message session, list the inbox, fetch messages, and listen for the "new message" event.
3. **Names.** Fetch the address book over PBAP so a number shows as a person.
4. **Send.** Push a message through the iPhone. The iPhone picks SMS or iMessage itself.
5. **The iPhone's switch.** MAP needs **Show Notifications** turned on for the computer in the iPhone's Bluetooth settings, like ANCS needs **Share System Notifications**. Ferret will check it and say so.

What MAP on an iPhone can't do, and Ferret won't pretend otherwise: no history from before the link, no group threads, no pictures, and no telling SMS from iMessage. Messages will feed Ferret's existing **Messages** page, marked as "from iPhone over Bluetooth" with those limits stated up front.

## 📞 Plan: calls (HFP)

The Hands-Free Profile is how a headset takes your calls.

1. **Call state first.** Ringing, who's calling, answer, decline, hang up. This is the control channel only (AT commands over RFCOMM) and comes first. Answer and decline already work today through the notification's actions.
2. **Then audio.** Talking on the computer needs the call's audio channel (SCO) wired to the microphone and speakers. Windows only exposes that to apps through its call-control APIs on recent builds; Linux does it through PipeWire or oFono. This is the hard part, so it ships after call state.
3. **One hands-free device at a time.** If the iPhone is also connected to a headset or a car, it picks one. Ferret will show who has the call.

## 🚫 What won't come

Files, clipboard, handoff and photos between an iPhone and a non-Apple computer have no Bluetooth profile. For those, install Ferret on the iPhone: see [Pair your devices](../getting-started/pairing.md).
