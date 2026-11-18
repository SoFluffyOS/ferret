# Send from the file manager

> **TL;DR**
>
> 1. Right-click a file in Finder, or tap **Share** on your iPhone.
> 2. Pick **Ferret**.
> 3. Pick the device. That's it.

The file is right there in Finder. Opening Ferret first, then finding the file again, is one trip too many.

So Ferret sits where the file already is: in Finder's Share menu, in the iPhone and iPad share sheet, in **Send to** on Windows, and in **Open With** on Linux. Files go the same way as a [drop](drop.md): straight to your device, over your own network.

## 🍎 Mac: Share → Ferret

Select one file or a hundred, right-click, and pick **Share → Ferret**. The Share button in Finder's toolbar, in Preview and in Photos works too.

A small list of your connected devices shows up:

- **Click a device** and the files go there.
- **All my devices** sends them to every connected one. It shows when two or more are connected.
- **No device connected?** Pick **Open Ferret**. Ferret sends as soon as it finds your device, or asks which one when there are several.

Ferret doesn't have to be running. The Share menu starts it.

Text and links work too: select text, or use the Share button in Safari, and it arrives on the other device as a notice with a **Copy** button.

### Ferret isn't in the Share menu?

macOS lets you choose which apps show there, and a new one can start switched off.

1. Open Ferret once, so macOS knows about it.
2. Open **System Settings → General → Login Items & Extensions**.
3. Under **Extensions**, open **Sharing** and switch on **Ferret**.

Or, in the Share menu itself, pick **Edit Extensions…** at the bottom. It opens the same list.

## 📱 iPhone and iPad: Share → Ferret

In Photos, Files, Safari or any app, tap **Share** and pick **Ferret**. Photos, videos, files, text and links all work.

A short list of your devices shows up, the ones Ferret was connected to last time it was open:

- **Tap a device.** Ferret opens and sends right away. You see the progress in **Activity**.
- **All my devices** sends to each of them. It shows when there are two or more.
- **No device yet?** Tap **Open Ferret**. It connects and sends as soon as it finds one.

Files go the same way as a [drop](drop.md). Text and links go the way [Handoff](handoff.md) sends them: a link opens on the other device, text lands there ready to copy.

Why does Ferret open? iOS stops apps in the background, so Ferret only sends while it is on screen. Opening it is what makes the send happen right now, not "later, maybe". Keep it open until the files are across.

### Ferret isn't in the share sheet?

1. Open Ferret once, so iOS knows about it.
2. Tap **Share**, scroll the row of apps to the end and tap **More**.
3. Tap **Edit**, then add **Ferret**. Drag it up the list to keep it close.

### It says "Open Ferret to send"?

Some iOS versions don't let the share sheet open another app. Your files are ready anyway: open Ferret yourself and it sends them right away.

## 🐧 Linux: Open With → Send with Ferret

Ferret understands `ferret send`, followed by files:

```bash
ferret send ~/Pictures/photo.jpg ~/Documents/report.pdf
```

To get it into your file manager, save this as `~/.local/share/applications/io.sofluffy.ferret.send.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=Send with Ferret
Exec=ferret send %F
Icon=io.sofluffy.ferret
Terminal=false
NoDisplay=true
MimeType=application/octet-stream;text/plain;image/jpeg;image/png;video/mp4;application/pdf;application/zip;
```

Then tell your desktop about it:

```bash
update-desktop-database ~/.local/share/applications
```

If `ferret` isn't on your `PATH`, put its full path after `Exec=`. The same file, with more file types, is in Ferret's source at `apps/ferret/linux/share`.

Now right-click a file and pick **Open With → Send with Ferret**.

## 🪟 Windows: Send to → Ferret

Windows has a **Send to** menu, and anything you put in its folder shows up there.

1. Press **Win + R**, type `shell:sendto` and press Enter. A folder opens.
2. Right-click in it and pick **New → Shortcut**.
3. For the location, type the path to Ferret followed by `send`, such as `"C:\Program Files\Ferret\ferret.exe" send`.
4. Name it **Ferret**.

Now right-click any files and pick **Send to → Ferret** (on Windows 11, under **Show more options**).

## 🧭 What happens next

On Linux and Windows there is no list in the menu, so Ferret decides the simple case for you:

- **One device connected:** the files go straight to it.
- **Several:** Ferret comes to the front and asks which one.
- **None:** you get a notice saying so. Nothing is sent later behind your back.

Is Ferret already running? The files are handed to it and no second Ferret starts. Not running? It starts, waits a few seconds for your devices to connect, and sends.

Either way the transfer shows in **Activity** like any other, with progress and **Cancel**.

## Limits

| Platform | Where | Picks the device | Notes |
|---|---|---|---|
| macOS | **Share → Ferret** | In the Share menu | Files, photos, text and links. You may have to switch it on once in System Settings |
| iPhone, iPad | **Share → Ferret** | In the share sheet | Files, photos, videos, text and links. Ferret opens to send them |
| Linux | **Open With → Send with Ferret** | In Ferret, when there are several | You copy one `.desktop` file |
| Windows | **Send to → Ferret** | In Ferret, when there are several | You make the shortcut once |
| Android | **Share → Send with Ferret** | In Ferret, when there are several | See [Drop](drop.md) |

Folders aren't sent yet: pick the files inside them.

On a Mac and an iPhone, Ferret gets its own copy of what you share. On the same disk that copy is instant and takes no extra space, and Ferret deletes it once the files are sent.
