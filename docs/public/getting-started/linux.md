# Ferret on Linux

On Linux, Ferret is one window. Give it the size you like and it arranges itself to fit. That includes a tiling window manager: the layout follows the width it is given, not the kind of computer.

> 1. Narrow window: one column, like on a phone.
> 2. From 600 wide: your devices on the left, the page you picked on the right.
> 3. From 1200 wide: an Activity pane joins on the right.

## 📦 Install

The quickest way, one line, no sudo:

```sh
curl -fsSL ferret.sofluffy.io/install.sh | sh
```

It puts the newest AppImage in `~/.local/opt/ferret`, links `ferret` and `ferret-cli` in `~/.local/bin`, and adds Ferret to your app menu. Run it again to update. AppImages need FUSE 2: the script tells you the package if it's missing.

Rather pick a package? All three install the same Ferret, with the app icon, the tray, and **Send with Ferret** in your file manager. Get them from the [latest release](https://github.com/simonpham/ferret/releases/latest).

> 1. **Flatpak** (any distribution): `flatpak install --user ferret-0.1.0-x86_64.flatpak`
> 2. **AppImage** (no install): `chmod +x Ferret-0.1.0-x86_64.AppImage`, then run it
> 3. **.deb** (Debian, Ubuntu, Mint, Pop!_OS): `sudo apt install ./ferret_0.1.0_amd64.deb`

### Flatpak

```sh
flatpak install --user ferret-0.1.0-x86_64.flatpak
flatpak run io.sofluffy.ferret
```

The sandbox only lets Ferret reach the network, `Downloads/Ferret` for the files you receive, the tray, notifications and media players. Pick another folder for received files and the file chooser asks your desktop for it.

- Ferret's folder is `~/.var/app/io.sofluffy.ferret/.sofluffy/ferret`, not `~/.sofluffy/ferret`.
- The command line is inside too: `flatpak run --command=ferret-cli io.sofluffy.ferret devices`.
- **Check my network** can't see your firewall from the sandbox. If your phone doesn't show up, use the firewall lines under **If your phone doesn't show up** below.
- Showing an Android phone's screen over a USB cable needs `adb`, which the sandbox doesn't have. Use the `.deb` or the AppImage for that.

### AppImage

```sh
chmod +x Ferret-0.1.0-x86_64.AppImage
./Ferret-0.1.0-x86_64.AppImage
```

No `libfuse2` needed. Want the command line too? Link the AppImage as `ferret-cli` and it runs that instead:

```sh
ln -s ~/Apps/Ferret-0.1.0-x86_64.AppImage ~/.local/bin/ferret-cli
```

**Start at login** points at the AppImage file itself, so keep it where it is or turn the switch off and on again after moving it.

### .deb

```sh
sudo apt install ./ferret_0.1.0_amd64.deb
```

You get `ferret` and `ferret-cli` on your `PATH`, and the firewall profiles: `sudo ufw allow Ferret`, or `sudo firewall-cmd --permanent --add-service=ferret && sudo firewall-cmd --reload`. It pulls in `wl-clipboard`, so copies on KDE Plasma and Sway sync by themselves.

### Build them yourself

On a Linux machine, from the source:

```sh
scripts/package_linux.sh          # or: deb, appimage, flatpak
```

The packages land in `build/linux-packages`. It doesn't run on macOS or Windows: Flutter only builds a Linux app on Linux.

## 🪟 The window

- **Your devices** are a list on the left. Click one and it opens to its sections: **Overview**, then what that device offers, such as **Messages**, **Calls**, **Notifications** and **Files**. The line you picked stays highlighted.
- **The page** you picked fills the rest. Anything you open from it opens right there, with a back arrow.
- **Nearby** shows devices you can pair, **+** adds one, and **Activity** and **Settings** sit under your devices.
- **Tile it** or make it small: under 600 wide the list folds away and Ferret is one column, the same as on your phone. Nothing is lost, only stacked.
- **Overview** shows the device, the few things you do most and **More** for the rest. With room, what works with the device sits on the left and what it may do on your computer on the right.
- **Right-click** a device for the same actions, **Fix connection…** and **Forget this device…**. Right-click a line in Activity for what that line offers.
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
| F9 | Show or hide the device list |
| Ctrl+Alt+0 | Show or hide the Activity pane |
| Ctrl+[ | Back |
| Ctrl+? | Keyboard shortcuts |
| Ctrl+Q | Quit Ferret |

## 🧱 If your phone doesn't show up

A firewall is the usual reason. **Add a device → Check my network** says when ufw or firewalld is on and copies the one line that lets Ferret through. See [Fix connection](../features/connection-doctor.md).

Ferret needs `47640/tcp` (`47642`–`47649/tcp` for a second account on the same computer), `47641/udp` and mDNS (`5353/udp`). Installed the `.deb`? It ships profiles for both firewalls:

```sh
sudo ufw allow Ferret
sudo firewall-cmd --permanent --add-service=ferret && sudo firewall-cmd --reload
```

## 💻 The terminal

```sh
ferret send ~/Pictures/photo.jpg       # hands it to the Ferret app, which sends it
ferret-cli devices --json              # paired devices, for scripts and jq
ferret-cli ring pixel                  # rings your phone, the start of its name is enough
ferret-cli camera pixel                # asks your phone for a photo, then prints its path
ferret-cli clipboard get               # the last text copied on another device
ferret-cli clipboard send --to pixel   # sends what you pipe in
ferret-cli action "Family PC" sleep    # sleep, restart, shut_down, mute, or one of its own actions
ferret-cli daemon                      # Ferret without a window, until Ctrl-C
ferret-cli --help                      # everything else
```

`ferret` is the app. `ferret-cli` is the command line, with its own identity, so it can run on a server with no desktop. Both take `send`.

`ferret send` needs the app running. It exits with `69` when it isn't, `66` when a file is missing, `64` on wrong usage and `0` when the app took the files. That makes it easy to bind to a key in your window manager.

`ring` and `clipboard` go through the running app too, take `--json`, and exit with `75` when the device isn't connected right now. `clipboard get` never prints private clips or images.

Everything Ferret keeps is in `~/.sofluffy/ferret`: settings, keys, pairings, and `window.ini` for the window's size. Set `FERRET_HOME` to put it somewhere else. The command line keeps its own identity in `~/.sofluffy/ferret/cli`. Nothing is sent anywhere but your own devices: no telemetry, no account, no cloud.

Not there yet: `ferret clip` to send text from a pipe.

