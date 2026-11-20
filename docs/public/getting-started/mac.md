# Ferret on your Mac

Ferret lives in your menubar. No Dock icon, no window in the way. Want a real window? It has one too.

<figure class="shot">
  <img src="/assets/landing/window-overview-light.webp" alt="The Ferret window on a Mac: a phone's Overview with a call, a song and a file on the way" width="700" height="504" loading="lazy">
  <img src="/assets/landing/window-overview-dark.webp" alt="The Ferret window on a Mac: a phone's Overview with a call, a song and a file on the way" width="700" height="504" loading="lazy">
</figure>

## 📦 Installing on a Mac

> 1. Download `Ferret-<version>.dmg` from the releases page
> 2. Open it and drag **Ferret** onto **Applications**
> 3. Open Ferret from Applications

That's it. Ferret needs macOS 12 Monterey or later, on Apple silicon or Intel.

Ferret for Mac comes straight from us, not from the Mac App Store. It is signed with a Developer ID and notarized by Apple, so macOS opens it without a warning.

Prefer Homebrew?

```sh
brew install --cask ferret
```

### The command line

`ferret-cli` comes inside the app. Homebrew puts it on your `PATH` for you. Installed from the DMG? Link it once:

```sh
ln -s /Applications/Ferret.app/Contents/Helpers/ferret-cli /usr/local/bin/ferret-cli
```

It runs on Apple silicon Macs. See [Pair your devices](pairing.md) for what it does.

### Removing it

Delete the app and `~/.sofluffy/ferret`, where Ferret keeps its data. See [Privacy](../privacy.md). With Homebrew, `brew uninstall --zap ferret` does both.

### Build it yourself

From the source, on a Mac with the Developer ID certificate:

```sh
scripts/package_macos.sh
```

The signed DMG lands in `build/macos-packages`. See `packaging/macos/README.md` for notarizing it.

Why not the App Store? Apps there must run in Apple's sandbox, and a sandboxed app can't start **adb**, Android's tool that [mirroring a phone without Ferret on it](../features/mirroring-with-a-cable.md) needs.

## 🍎 First run

1. Open Ferret. Its icon, the ferret, appears in the menubar and Ferret opens under it, this one time, so you know where it lives.
2. No setup screens. Your other devices running Ferret show up under **Nearby**: tap **Pair**. See [Pair your devices](pairing.md).

Your Mac's name is the one from System Settings. Change it any time in **Settings**.

Want it there every morning? Turn on **Start Ferret when I log in** in **Settings → This device** (macOS 13 or later).

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
- **Drop files** on the icon (or the popover) to send them to your phone. Dropped right on the icon, they go to your one connected device, or to the device you sent files to last. The icon's ring fills while they go. With no way to tell, the popover opens so you pick.
- **Drop text or a link** on a device in the popover or the window. Text lands on that device's clipboard. A link opens there, like **Send a link…**.
- **Drag a file out of Activity**: a file that just arrived is a real file. Drag its line to Finder, Mail or any app. Press Space on it for Quick Look.

### ⌨️ The popover from the keyboard

Press **⌃⌥Space** in any app and Ferret opens under its icon. Press it again to close it.

| Keys | Does |
|---|---|
| ⌃⌥Space | Open or close Ferret, from any app |
| ⌃⌥V | Recent clips, from any app: the last things you copied on any device. Change or turn it off in **Settings → Advanced** |
| ↓ / ↑ | Next / previous device or Activity line |
| ↩ | Open the device, or the line (a file opens) |
| ⌘V | On a device: send it your clipboard |
| Space | On a file that arrived: Quick Look |
| ⌘N | Add a device |
| ⌘, | Settings |
| Esc | Back a page, or close Ferret |

⌃⌥Space taken by another app? Pick other keys in **Settings → Advanced → Open Ferret from anywhere**: click **Change** and press the new ones. **Turn off** if you don't want any.

No Accessibility permission needed. Ferret asks macOS for just that one key combination, so it never sees anything else you type.

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
- **Drag files** onto a device in the list to send them there. Rest on it for a moment and it opens. Dropped on the page, they go to the device you have open.
- **Right-click** a device for the same actions, **Fix Connection…** and **Forget This Device…**. Right-click a line in Activity for what that line offers.
- **A device that goes offline keeps its sections.** You still read what was there, under one line that says since when, with **Fix connection**. A section whose feature is off is dimmed, and says how to turn it on.
- **Settings** keeps its list on the left and opens the row you pick next to it. Each row has its own coloured icon, the same one as in the popover.
- **Your devices** has a **+** that adds one. **Nearby** shows devices you can pair, and folds away with a click on its name. **Activity** and **Settings** sit under your devices.
- **A toolbar** runs along the top of the page. It says where you are, and its buttons hide or show the device list and the Activity pane. Rest the pointer on a button, or on a line of the device list, and it tells you its keys.
- **Make it wide** (1200 points or more) and an **Activity** pane joins on the right: what is going on now, and the last things that happened with that device.
- Lists and forms stop at a comfortable width and stay centred. Nothing stretches across a big screen.

The device list runs all the way to the top, with the traffic lights sitting on it, like Notes or Mail. Drag the top edge to move the window, and double-click it to zoom.

The window's title says where you are, such as **Pixel 9 — Messages**. You see it in the **Window** menu and when you switch apps, and VoiceOver reads it.

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

The same commands are in the **File**, **View** and **Device** menus. One that can't apply right now is greyed out. **Help** lists every key under **Keyboard Shortcuts**, and has **Fix Connection…** and **Check My Network…**.

## 🔐 Optional permissions

These are asked only when you turn the matching feature on:

| Feature | macOS asks for | Why |
|---|---|---|
| Send current page | Automation (your browser) | To read the page in your browser's front window when you send it. |
| Media | Automation (Music, Spotify) | To show and control what plays here. |

Change them any time in **System Settings → Privacy & Security → Automation**.
