---
order: 2
---
# Ferret on Windows

On Windows, Ferret is one window. Give it the size you like and it arranges itself to fit.

> 1. Narrow window: one column, like on a phone.
> 2. From 600 wide: your devices on the left, the page you picked on the right.
> 3. From 1200 wide: an Activity pane joins on the right.

<figure class="shot">
  <img src="/assets/docs/windows-overview-light.webp" alt="The Ferret window on Windows: a phone's Overview" width="700" height="504" loading="lazy">
</figure>

## 📦 Install

> ⏳ **Not in the first release yet.** The first release is for Mac and Android. The Windows download follows once it has met enough real PCs. Today you build it from source: see **Build from source** in the [README](https://github.com/simonpham/ferret#readme). This page is how it works once it's installed.

> 1. Download [Ferret-windows-x64-setup.exe](https://github.com/simonpham/ferret/releases/latest/download/Ferret-windows-x64-setup.exe), the newest release
> 2. Run it. No admin needed: it installs just for you
> 3. Keep **Allow Ferret through Windows Firewall** ticked and say **Yes** when Windows asks

That's it. You get Ferret in the Start menu, **Send to → Ferret** when you right-click a file, and `ferret-cli.exe` next to the app.

Windows may say it protected your PC (SmartScreen). Click **More info**, then **Run anyway**.

### The firewall box

Windows hides your PC from your phone until Ferret is allowed through its firewall. The installer does that for you with four rules, on **Private** networks only:

| Rule | Port | For |
|---|---|---|
| Ferret (47640/tcp) | 47640/tcp | Your devices talking to each other |
| Ferret other accounts (47642-47649/tcp) | 47642–47649/tcp | Ferret in another account on the same PC |
| Ferret discovery (47641/udp) | 47641/udp | Finding your devices |
| Ferret mDNS (5353/udp) | 5353/udp | Finding your devices with mDNS |

Said **No**? No problem. **Fix connection** notices the rules are missing and offers **Allow through firewall**. One click, one **Yes**, done.

Public networks (a café, a hotel, a Wi-Fi Windows doesn't know yet) stay closed. At home, set your Wi-Fi to Private: **Settings → Network & internet → Wi-Fi**, pick your network, then **Private network**.

### Uninstall

**Settings → Apps → Installed apps → Ferret → Uninstall.** It removes the app, the shortcuts, the firewall rules and Start at login.

Your keys, paired devices and settings stay in `%USERPROFILE%\.sofluffy\ferret`, so a reinstall picks up where you left off. Delete that folder to forget everything.

## 🪟 The window

- **Your devices** are a list on the left. Click one and it opens to its sections: **Overview**, then what that device offers, such as **Messages**, **Calls**, **Notifications** and **Files**. The line you picked stays highlighted.
- **The page** you picked fills the rest. Anything you open from it opens right there, with a back arrow.
- **Nearby** shows devices you can pair, **+** adds one, and **Activity** and **Settings** sit under your devices.
- **Snap it** to half the screen, or make it small: under 600 wide the list folds away and Ferret is one column, the same as on your phone. Nothing is lost, only stacked.
- **Overview** shows the device, the few things you do most and **More** for the rest. With room, what works with the device sits on the left and what it may do on your PC on the right.
- **Right-click** a device for the same actions, **Fix connection…** and **Forget this device…**. Right-click a line in Activity for what that line offers.
- **A device that goes offline keeps its sections**, under one line that says since when, with **Fix connection**. A section whose feature is off is dimmed.
- **Settings** keeps its list on the left and opens the row you pick next to it.
- Lists and forms stop at a comfortable width and stay centred, however big the window gets.

Nothing paired yet? There is no list to show, so the window is one column that looks for your other devices. See [Pair your devices](pairing.md).

## 🧷 The tray, and closing the window

Ferret puts an icon in the notification area, next to the clock. Click it to show the window. Right-click it for **Open Ferret**, **Send clipboard to my devices**, **Pause syncing for 1 hour** (or **Resume**) and **Quit Ferret**.

- **Closing the window keeps Ferret running in the tray**, so copies and files still arrive. The first time, a notification says where it went. Quit from the tray menu.
- **Open Ferret again** from the app menu and the one already running shows its window. There is only ever one Ferret.
- Windows may tuck the icon under the **^** arrow. Drag it next to the clock to keep it in sight.
- The window opens where you left it, at the size you left it, maximized or not.

## 🚀 Start with Windows

**Settings → Start Ferret when I log in.** Ferret then starts with Windows, straight into the tray, so your devices connect before you need them. It's one line in your user's **Run** key, and turning the switch off removes it. You can also see it under **Task Manager → Startup apps**.

## ⌨️ Keys

There is no menu bar. The **•••** at the end of the window's toolbar holds the same commands, each with its keys next to it, and **Keyboard shortcuts** lists them all.

| Keys | Does |
|---|---|
| Ctrl+1 … Ctrl+6 | Sections of the selected device. Overview is Ctrl+1 |
| Ctrl+Alt+↓ / Ctrl+Alt+↑ | Next / previous device |
| Ctrl+N | Add a device |
| Ctrl+O | Send files to the selected device |
| Ctrl+Shift+V | Send the clipboard to the selected device |
| Ctrl+Shift+A | Activity |
| Ctrl+, | Settings |
| Ctrl+B | Show or hide the device list |
| Ctrl+Alt+0 | Show or hide the Activity pane |
| Ctrl+[ | Back |
| Ctrl+? | Keyboard shortcuts |
| Ctrl+Q | Quit Ferret |

## 🧱 If your phone doesn't show up

Windows Firewall is the usual reason. **Add a device → Check my network** tells you whether Ferret's firewall rules are in place, and **Allow through firewall** adds them. See [Fix connection](../features/connection-doctor.md).
