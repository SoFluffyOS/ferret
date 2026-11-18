# Messages

> **TL;DR**
>
> 1. On your Android phone, tap **Set up** next to Messages in **Do more** on Ferret's home screen (or open **Settings → To your computer**), then **Turn on**.
> 2. Allow **SMS** and **Contacts** when Android asks.
> 3. On your computer, open **Messages** from your phone's card. Read, scroll back, reply.

A text arrives while you're at your desk. You reach for your phone, unlock it, type with your thumbs, and lose your train of thought.

With Ferret, your phone's texts are on your computer. Every conversation, with names and photos, pictures included. Answer with a real keyboard.

## 💬 How it works

- Open **Messages** from your phone's card on the home screen, or from the phone's page.
- Your 30 most recent conversations show up first, with contact names. Scroll down and older ones load.
- Open a conversation and scroll up for older texts. Pictures show inline; click one to see it full size.
- Type in the box and click **Send**. Your reply shows as "Sending…" until the phone confirms it went out.

Didn't go out? Ferret says why, in plain words ("Pixel 9 has no signal"), with **Send again**.

## 🔔 New texts

When a text arrives and that conversation isn't open on your computer, you get a notification with **Reply** and **Mark as read**. Several texts in the same conversation update one notification ("Alex · 3 new"). No floods.

Texts that arrived while your computer was off are not replayed as notifications. They're simply there when you open Messages.

Turn the notifications off in **Settings → From your phone** on your computer, under Messages.

## 💾 Works offline too

Your computer keeps your recent conversations and texts, so they're still there when the phone is out of reach. Replying works again as soon as the phone is back.

They're saved in Ferret's folder on your computer (`~/.sofluffy/ferret/features/messages`) and never leave your network. **Settings → From your phone → Forget saved texts** deletes them.

## 🔑 Permissions on the phone

Ferret asks for SMS and Contacts only when you tap **Turn on**, never before.

- **SMS** to read and send texts.
- **Contacts** to show names and photos instead of numbers. Without it, everything still works with numbers.

Tapped "Don't allow" twice? Android stops asking. Ferret shows **Open settings**: tap **Permissions**, allow **SMS** and **Contacts**, and come back. Ferret checks again on its own.

## 🧭 Limits

- **RCS chats can't be read.** RCS conversations (the "chat" ones in Google Messages) live inside Google Messages and no other app can read them. Use [Notifications](notifications.md) for those: allow Google Messages there and you can see and answer RCS chats from your computer.
- **Group texts are read-only.** Answering a group needs MMS, which only your phone's messaging app can send. Ferret shows group conversations and says so in the reply box.
- **Read state stays on the computer.** Android lets only the default messaging app mark texts as read. Ferret clears the unread count on your computer, and your phone keeps its own.
- **Pictures** are sent as small previews. The full picture loads from the phone when you click it (up to 16 MB).

| Platform | Shares its texts | Reads a phone's texts |
|---|---|---|
| Android | ✅ SMS and MMS | No |
| macOS | No | ✅ |
| Windows | No | ✅ |
| Linux | No | ✅ |
| iOS | No, iOS doesn't let any app read texts | No |

Texts are never logged and only travel between your own paired devices, encrypted.
