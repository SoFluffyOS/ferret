# Drop

> **TL;DR**
>
> 1. Pair your devices.
> 2. Drop files on Ferret, or pick **Send files…** on a device.
> 3. They land in **Downloads/Ferret** on the other side. That's it.

You need a photo from your phone on your laptop, or a PDF from your laptop on your phone. Cables, chat apps and emailing yourself all work, and all are slow.

With Ferret, files and text go straight from one of your devices to another, over your own network. Nothing is uploaded anywhere.

## 📦 Send files

- **On a computer:** drag files over the Ferret window. It turns into one big tile per device. Drop on the one you want, or on **All my devices**. Or open a device and pick **Send files…**.
- **On a Mac:** drag files onto the menubar icon and hold for a moment. The popover springs open on the same tiles. Drop right on the icon instead and they go to your one connected device, or Ferret shows the tiles so you pick.
- **On Android:** share from any app and pick **Send with Ferret**. Photos, PDFs, anything.
- **From the file manager:** right-click a file and pick **Share → Ferret** in Finder, **Send to** on Windows or **Open With** on Linux. See [Send from the file manager](share-menu.md).
- **Offline devices** stay on screen, faded, and don't take the drop.

After the drop, the tile shows the progress, then **Sent to Pixel 9**. If something went wrong, it says why and offers **Try again**.

The Files card on the home screen shows each transfer while it runs: progress, speed and time left. You can **Cancel** at any time.

## 📥 Receive files

Files from your paired devices are accepted on their own. No prompt to click.

When a transfer finishes, you get one quiet notice with **Open** and **Show in folder**.

Every file is checked with a SHA-256 hash before it is saved. A transfer only says **Saved ✓** once the check passed. If the file arrived damaged, Ferret deletes it and says so, and **Try again** sends it again.

Ferret never overwrites a file. If `photo.jpg` already exists, the new one becomes `photo (1).jpg`.

## 💬 Send text

Share text to **Send with Ferret** on Android and it arrives as a notice on your other device, with a **Copy** button.

## 🔁 Dropped connection? It continues

Wi-Fi drops, a laptop goes to sleep, a phone walks out of range. Ferret keeps what already arrived. When the device is back, the transfer continues where it stopped, without starting over.

If something fails for another reason, its line in **Activity** says why in plain words, with a **Retry** button.

## ⚙️ Settings

In **Settings → Files**:

- **Receive folder**: where files land. `~/Downloads/Ferret` on computers. On Android, a folder inside **Download**, `Ferret` by default.
- **Accept from my devices**: on by default. Turn it off to approve each transfer with **Accept** or **Decline**.

The row itself says where files go, such as **To Downloads › Ferret**.

LocalSend and Quick Share have their own switches in **Settings → Other apps**. See [LocalSend](../interop/localsend.md) and [Quick Share](../interop/quick-share.md).

Each device's page lists **Files** under **What works**: where files arrive, or how the last transfer with that device ended. A transfer that broke has a **Fix** button that picks it up again.

## 🧭 Limits per platform

| Platform | Send | Receive into | Notes |
|---|---|---|---|
| macOS | Drop on the window or menubar icon, **Share → Ferret** in Finder, or **Send files…** | `~/Downloads/Ferret`, or a folder you pick | **Show in folder** opens Finder |
| Windows | Drop on the window, or **Send files…** | `Downloads\Ferret`, or a folder you pick | **Show in folder** opens Explorer |
| Linux | Drop on the window, or **Send files…** | `~/Downloads/Ferret`, or a folder you pick | **Show in folder** uses your file manager |
| Android 10+ | **Send with Ferret** from any app, or **Send files…** | `Download/Ferret`, visible in the Files app | **Show in folder** opens Downloads |
| Android 7 to 9 | Same | Ferret's own folder in `Android/data` | No storage permission asked |
| iPhone and iPad | **Send files…** | Ferret's folder in the Files app | Receives while Ferret is open |

Folders aren't sent yet: pick the files inside them.

File names and contents are never logged, and nothing leaves your network.

## Send to LocalSend

Ferret also talks to [LocalSend](../interop/localsend.md), so you can send files to friends' phones and computers that run it, iPhones included.

## Receive from any Android phone

No Ferret on that phone? Make your computer visible to [Quick Share](../interop/quick-share.md) for 10 minutes and send from the phone's share menu.
