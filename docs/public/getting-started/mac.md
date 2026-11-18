# Ferret on your Mac

Ferret lives in your menubar. No Dock icon, no window in the way. Want a real window? It has one too.

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

- **Click** the icon to open Ferret. **Right-click** for Open Ferret Window, Add a Device, Settings and Quit.
- **Your devices** come first, each with what you can do right on its row: **Send files**, **Send clipboard**, **Ring**. A device that isn't connected shows **Fix** instead.
- **Activity** under them is what just happened: a copy that synced, a file that arrived, a song playing on your phone. **See all** opens the full list.
- **+** adds a device. **•••** holds **Pause syncing** (for an hour, until tomorrow, or until you resume), **Open Ferret window**, **Settings** and **Quit Ferret**. While paused, the last line says until when, with **Resume**.
- **Things that need room open the window**: click a device, **Settings**, a phone's texts or its notifications, and the window opens right there. The popover steps aside. A notification you click does the same.
- **Drag** the popover away from the menubar to keep it open as a window.
- **Drop files** on the icon (or the popover) to send them to your phone.

The icon tells you what Ferret is doing. Plain means a device is connected. Dimmed means none is, which is fine. A ring fills while a file moves, then a check shows for a moment. A dot means someone is waiting for your answer: a device that wants to pair, or a file from someone else. A slash means Ferret is paused. Rest the pointer on the icon to read it in words.

## 🪟 The window

The popover is small on purpose. For a longer look, open Ferret in a normal window.

1. Click **•••** in the popover, or right-click the icon.
2. Pick **Open Ferret window**.

That's it. The window and the popover are the SAME Ferret: pause in one and the other shows it right away. Each keeps its own place, so you can read your texts in the window while the popover stays on your devices.

The window is not a big popover. It has room, so it uses it:

- **Your devices** are a list on the left. Click one and it opens to its sections: **Overview**, then what that device offers, such as **Messages**, **Calls**, **Notifications** and **Files**. The line you picked stays highlighted.
- **The page** you picked fills the rest. Anything you open from it (Fix connection, a settings page) opens right there, with a back arrow. The list never moves.
- **Overview** shows the device, the few things you do most (**Send files**, **Show screen**, **Send clipboard**, **Ring**) and **More** for the rest. With room, what works with the device sits on the left and what it may do on your Mac on the right.
- **Right-click** a device for the same actions, **Fix Connection…** and **Forget This Device…**. Right-click a line in Activity for what that line offers.
- **A device that goes offline keeps its sections.** You still read what was there, under one line that says since when, with **Fix connection**. A section whose feature is off is dimmed, and says how to turn it on.
- **Settings** keeps its list on the left and opens the row you pick next to it.
- **Nearby** shows devices you can pair, **+** adds one, and **Activity** and **Settings** sit under your devices.
- **Make it wide** (1200 points or more) and an **Activity** pane joins on the right: what is going on now, and the last things that happened with that device.
- Lists and forms stop at a comfortable width and stay centred. Nothing stretches across a big screen.

The window's title says where you are, such as **Pixel 9 — Messages**.

- **Resize** it like any window. It opens where you left it, at the size you left it, on the device and section you left it on.
- **Close** it (⌘W or the red button) and only the window goes. Ferret keeps running in the menubar.
- **The Dock** shows Ferret while the window is open, and a click on its Dock icon brings the window back to the front. Close the window and the Dock icon leaves with it.

Want Ferret in the Dock all the time? Turn on **Settings → Always show in the Dock**. Then a click on the Dock icon opens the window.

### ⌨️ Keys and menus

Everything in the window has a key, and a place in the menu bar.

| Keys | Does |
|---|---|
| ⌘1 … ⌘6 | Sections of the selected device. Overview is ⌘1 |
| ⌥⌘↓ / ⌥⌘↑ | Next / previous device |
| ⌘N | Add a device |
| ⌘O | Send files to the selected device |
| ⇧⌘V | Send the clipboard to the selected device |
| ⇧⌘A | Activity |
| ⌘, | Settings |
| ⌃⌘S | Show or hide the device list |
| ⌥⌘0 | Show or hide the Activity pane |
| ⌘[ | Back |
| ⌘W | Close the window |

The same commands are in the **File**, **View** and **Device** menus. One that can't apply right now is greyed out.

## 🔐 Optional permissions

These are asked only when you turn the matching feature on:

| Feature | macOS asks for | Why |
|---|---|---|
| Send current page | Automation (your browser) | To read the page in your browser's front window when you send it. |
| Media | Automation (Music, Spotify) | To show and control what plays here. |

Change them any time in **System Settings → Privacy & Security → Automation**.
