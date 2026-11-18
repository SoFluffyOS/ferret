# Ferret on Linux

On Linux, Ferret is one window. Give it the size you like and it arranges itself to fit. That includes a tiling window manager: the layout follows the width it is given, not the kind of computer.

> 1. Narrow window: one column, like on a phone.
> 2. From 600 wide: your devices on the left, the page you picked on the right.
> 3. From 1200 wide: an Activity pane joins on the right.

## 🪟 The window

- **Your devices** are a list on the left. Click one and it opens to its sections: **Overview**, then what that device offers, such as **Messages**, **Calls**, **Notifications** and **Files**. The line you picked stays highlighted.
- **The page** you picked fills the rest. Anything you open from it opens right there, with a back arrow.
- **Nearby** shows devices you can pair, **+** adds one, and **Activity** and **Settings** sit under your devices.
- **Tile it** or make it small: under 600 wide the list folds away and Ferret is one column, the same as on your phone. Nothing is lost, only stacked.
- **Overview** shows the device, the few things you do most and **More** for the rest. With room, what works with the device sits on the left and what it may do on your computer on the right.
- **Right-click** a device for the same actions, **Fix Connection…** and **Forget This Device…**. Right-click a line in Activity for what that line offers.
- **A device that goes offline keeps its sections**, under one line that says since when, with **Fix connection**. A section whose feature is off is dimmed.
- **Settings** keeps its list on the left and opens the row you pick next to it.
- Lists and forms stop at a comfortable width and stay centred, however big the window gets.

Nothing paired yet? There is no list to show, so the window is one column that looks for your other devices. See [Pair your devices](pairing.md).

## 🧷 The tray, and closing the window

Ferret puts an icon in your panel's tray. Click it to show or hide the window. Its menu has **Open Ferret**, **Send clipboard to my devices**, **Pause syncing for 1 hour** (or **Resume**) and **Quit Ferret**.

- **With a tray, closing the window keeps Ferret running there**, so copies and files still arrive. The first time, a notification says where it went. Quit from the tray menu.
- **Without a tray, closing the window quits Ferret.** A hidden window you can't get back would be worse. Stock GNOME has no tray: turn on the **AppIndicator and KStatusNotifierItem Support** extension (Ubuntu ships it on) and log in again.
- **Open Ferret again** from the app menu and the one already running shows its window. There is only ever one Ferret.
- KDE Plasma, Xfce, Cinnamon, MATE, Budgie and waybar show the icon as they are.
- The window opens at the size you left it. On X11 it also opens where you left it. On Wayland the compositor decides where windows go, so only the size is kept.

## 🚀 Start at login

**Settings → Start Ferret when I log in.** Ferret then starts with your desktop, straight into the tray, so your devices connect before you need them. No tray? It opens its window instead.

It's a normal XDG autostart entry, `~/.config/autostart/io.sofluffy.ferret.desktop`, which GNOME, KDE Plasma, Xfce and the rest all read. Turn the switch off and the file is gone. Inside a Flatpak, Ferret asks the desktop through the Background portal instead.

Prefer a systemd user service, or a line in your tiling WM's config? Run `ferret --hidden`. That's all autostart does.

The icon speaks StatusNotifierItem over D-Bus. Nothing to install, and inside a Flatpak it only needs to talk to `org.kde.StatusNotifierWatcher`.

## ⌨️ Keys

There is no menu bar. The **•••** at the top of the device list holds the same commands, each with its keys next to it, and **Keyboard Shortcuts** lists them all.

| Keys | Does |
|---|---|
| Ctrl+1 … Ctrl+6 | Sections of the selected device. Overview is Ctrl+1 |
| Ctrl+Alt+↓ / Ctrl+Alt+↑ | Next / previous device |
| Ctrl+N | Add a device |
| Ctrl+O | Send files to the selected device |
| Ctrl+Shift+V | Send the clipboard to the selected device |
| Ctrl+Shift+A | Activity |
| Ctrl+, | Settings |
| F9 | Show or hide the device list |
| Ctrl+Alt+0 | Show or hide the Activity pane |
| Ctrl+[ | Back |
| Ctrl+? | Keyboard shortcuts |
| Ctrl+Q | Quit Ferret |

## 🧱 If your phone doesn't show up

A firewall is the usual reason. **Add a device → Check my network** says when ufw or firewalld is on and copies the one line that lets Ferret through. See [Fix connection](../features/connection-doctor.md).
