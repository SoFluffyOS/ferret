# Ferret on your Mac

Ferret lives in your menubar. No Dock icon, no window in the way.

## 📦 Installing on a Mac

Download Ferret from its releases page and drag it to **Applications**. That's it.

Ferret for Mac comes straight from us, not from the Mac App Store. It is signed with a Developer ID and notarized by Apple, so macOS opens it without a warning.

Removing it later? Delete the app and `~/.sofluffy/ferret`, where Ferret keeps its data. See [Privacy](../privacy.md).

Why not the App Store? Apps there must run in Apple's sandbox, and a sandboxed app can't start **adb**, Android's tool that [mirroring a phone without Ferret on it](../features/mirroring-with-a-cable.md) needs.

## 🍎 First run

1. Open Ferret. Its icon (⇆) appears in the menubar and Ferret opens under it, this one time, so you know where it lives.
2. No setup screens. Your other devices running Ferret show up under **Nearby**: tap **Pair**. See [Pair your devices](pairing.md).

Your Mac's name is the one from System Settings. Change it any time in **Settings**.

macOS asks two things the first time:

- **Allow incoming connections?** Say yes, so your phone can reach your Mac.
- **Notifications**: allow them to see things your phone sends, such as calls and messages.

## 🖱️ Using it

- **Click** the icon to open Ferret. **Right-click** for Add a Device, Settings and Quit.
- **Your devices** come first, each with what you can do right on its row: **Send files**, **Send clipboard**, **Ring**. A device that isn't connected shows **Fix** instead.
- **Activity** under them is what just happened: a copy that synced, a file that arrived, a song playing on your phone. **See all** opens the full list.
- **+** adds a device. **•••** holds **Pause**, **Settings** and **Quit Ferret**. While paused, the last line says until when, with **Resume**.
- **Drag** the popover away from the menubar to keep it open as a window.
- **Drop files** on the icon (or the popover) to send them to your phone.

The icon tells you what Ferret is doing. Plain means a device is connected. Dimmed means none is, which is fine. A ring fills while a file moves, then a check shows for a moment. A dot means someone is waiting for your answer: a device that wants to pair, or a file from someone else. A slash means Ferret is paused. Rest the pointer on the icon to read it in words.

## 🔐 Optional permissions

These are asked only when you turn the matching feature on:

| Feature | macOS asks for | Why |
|---|---|---|
| Send current page | Automation (your browser) | To read the page in your browser's front window when you send it. |
| Media | Automation (Music, Spotify) | To show and control what plays here. |

Change them any time in **System Settings → Privacy & Security → Automation**.
