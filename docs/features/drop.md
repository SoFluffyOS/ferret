# Drop

> **TL;DR**
>
> 1. Pair your devices.
> 2. Drop files or folders on Ferret, or pick **Send files…** on a device.
> 3. They land in **Downloads/Ferret** on the other side. That's it.

You need a photo from your phone on your laptop, or a PDF from your laptop on your phone. Cables, chat apps and emailing yourself all work, and all are slow.

With Ferret, files and text go straight from one of your devices to another, over your own network. Nothing is uploaded anywhere.

<figure class="shot shot-narrow">
  <img src="/assets/landing/popover-home-light.webp" alt="The Ferret popover on a Mac: your devices with Send files, and the shelf at the bottom" width="380" height="560" loading="lazy">
  <img src="/assets/landing/popover-home-dark.webp" alt="The Ferret popover on a Mac: your devices with Send files, and the shelf at the bottom" width="380" height="560" loading="lazy">
</figure>

## 📦 Send files

- **In the window:** drag files onto a device in the list on the left. The device under the pointer lights up and says **Send to Pixel 9**. Hold still for a moment and it opens, so you can see where they go. Or drop on the page itself: it goes to the device you have open, or to all your connected devices on **Activity** and **Settings**. The page stays where it was, and a card in the corner shows how sending goes.
- **On a phone or the Mac popover:** drag files over Ferret and it turns into one big tile per device. Drop on the one you want, or on **All my devices**. Or open a device and pick **Send files…**.
- **On a Mac:** drag files onto the menubar icon and hold for a moment. The popover springs open on the same tiles. Drop right on the icon instead and they go to your one connected device, or to the device you dropped files on last while it is connected, after 3 seconds you can **Undo**. The icon's ring fills while they go. Otherwise Ferret shows the tiles so you pick. You can make the icon keep drops on the [shelf](shelf.md) or always ask instead.
- **On Android:** share from any app and tap your device in the share sheet's top row. It goes straight there. Or pick **Send with Ferret** and choose. Photos, PDFs, links, anything. A 1 GB video starts sending right away: Ferret reads it straight from the app you shared it from, with no copy first and no extra space needed.
- **From the file manager:** right-click a file and pick **Share → Ferret** in Finder, **Send to** on Windows or **Open With** on Linux. See [Send from the file manager](share-menu.md).
- **Offline devices** stay on screen, faded, and don't take the drop. In the window, an offline device says **Offline** while you drag over it.

After the drop, the tile shows the progress, then **Sent to Pixel 9**. If something went wrong, it says why and offers **Try again**.

Each transfer sits at the top of **Activity** while it runs, with how far it is and the time left: **26 MB of 42 MB · 1 min left**. You can **Cancel** at any time.

## 📥 Receive files

Files from your paired devices are accepted on their own. No prompt to click.

When a transfer finishes, you get one quiet notice, such as **IMG_2041.jpg from Pixel 9**, with **Open** and **Show in Finder** (**Show in folder** on Windows, Linux and Android). Its line in **Activity** has the same buttons.

On a Mac, that line IS the file: drag it to Finder, your desktop or any app (Mail, Messages, an editor) and a copy lands there. Select it with the arrow keys and press Space for Quick Look.

Files from a phone that isn't paired (LocalSend or Quick Share) wait under **Needs you** at the top of the home screen: **Ana's Pixel wants to send** · **2 files · 6 MB**, with **Decline** and **Accept**. Tap the line to see everything about the offer first.

Every file is checked with a SHA-256 hash before it is saved. A transfer only says **Saved ✓** once the check passed. If the file arrived damaged, Ferret deletes it and says so, and **Try again** sends it again.

Ferret never overwrites a file. If `photo.jpg` already exists, the new one becomes `photo (1).jpg`.

### 💾 Not enough space?

Before a single byte moves, Ferret checks the free space where the files land. If they don't fit, it says no right away, instead of filling your disk halfway and failing.

- **Here:** **Not enough space for clip.mov: needs 2 GB, 1.2 GB free**, with **Open Settings** on Android and **Show in Finder** (**Show in folder** elsewhere) on a computer.
- **On the sending side:** **Pixel 7 is out of space: needs 2 GB, 1.2 GB free**. Make room, press **Retry**, and it goes.

On a Mac, the space macOS can free on its own (caches, purgeable files) counts too, so a nearly full disk doesn't say no too early.

## 📁 Send folders

Drop a whole folder, the same way you drop files. Everything inside goes along, subfolders included.

- **In the window or the popover:** drag the folder onto a device.
- **Pick one:** open a device's **Files** and click **Choose a folder…**, or use **Send a folder** on the device's page. On macOS, Windows and Linux.
- **From Finder or Files:** **Share → Ferret** works on folders too.
- **From the terminal:** `ferret-cli send ~/Pictures/Holiday`.

While it goes, the line counts files as well as bytes: **Photos · 120 of 340 files · 1.2 GB of 3.4 GB**. A dropped connection pauses it at the file it was on, and it goes on from there.

On the other side, the folder lands in the receive folder with its tree as it was: `Downloads/Ferret/Photos/2024/…`. Modified dates are kept on computers.

Ferret NEVER merges into a folder you already have. If `Photos` is there, the new one becomes `Photos (2)`. **Open** opens the folder, **Show in Finder** (**Show in folder** elsewhere) shows it.

A few things stay behind on purpose:

- **Links and special files** don't travel. A link can point anywhere, even outside the folder. The line says how many were left out.
- **System litter** such as `.DS_Store` and `Thumbs.db` is skipped.
- **Names the other side can't use** are cleaned up: no `..`, no paths from the root, no names Windows refuses, nothing too long. A folder that tries to climb out of the receive folder is refused whole.

Sending to a device with an older Ferret? It says **Pixel 7's Ferret is too old for folders. Update it, or send the files.** **Send the files** sends everything inside, without the folders. Nothing gets flattened behind your back.

LocalSend and Quick Share carry folders too: a folder you send to LocalSend arrives as a folder, and a folder a phone shares with Quick Share lands as one here.

## 💬 Send text

Share text to **Send with Ferret** on Android and it arrives as a notice on your other device, with a **Copy** button. A link asks first: send it as text, or **Open on MacBook** to open it there, like [Handoff](handoff.md).

On a Mac, drag text onto a device in the popover or the window: it lands on that device's clipboard. Drag a link and it opens there. See [Clipboard](clipboard.md) and [Handoff](handoff.md).

## 🔁 Dropped connection? It continues

Wi-Fi drops, a laptop goes to sleep, a phone walks out of range. Ferret keeps what already arrived. When the device is back, the transfer continues where it stopped, without starting over.

While it waits, its line in **Activity** stays at the top and says so: **Paused at 620 MB of 1.8 GB. It goes on when Pixel 7 is back.** Nothing to press. **Cancel** stops it for good, **Try now** knocks right away.

Sent something while the other device was away? Same thing: it waits, then goes as soon as the device is back.

Several stopped at once? In the window, the device's **Files** section has **Try all again**. One click, and they go in the order you sent them.

A transfer that crawls says why: **Weak connection · 620 MB of 1.8 GB · 12 min left**. Move closer to the Wi-Fi.

LocalSend and Quick Share can't pick up where they stopped, so those start over.

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
| macOS | Drop on the window or menubar icon, **Share → Ferret** in Finder, or **Send files…** | `~/Downloads/Ferret`, or a folder you pick | **Show in Finder** |
| Windows | Drop on the window, or **Send files…** | `Downloads\Ferret`, or a folder you pick | **Show in folder** opens Explorer |
| Linux | Drop on the window, or **Send files…** | `~/Downloads/Ferret`, or a folder you pick | **Show in folder** uses your file manager |
| Android 10+ | **Send with Ferret** from any app, or **Send files…** | `Download/Ferret`, visible in the Files app | **Show in folder** opens Downloads |
| Android 7 to 9 | Same | Ferret's own folder in `Android/data` | No storage permission asked |
| iPhone and iPad | **Share → Ferret** from any app, or **Send files…** | Ferret's folder in the Files app (**Files › Ferret** in the app) | Receives while Ferret is open, from your devices and from LocalSend |

Folders: drag them anywhere, or **Choose a folder…** on macOS, Windows and Linux. On iPhone and iPad, share a folder from the Files app. Android can't pick a folder to send yet: send the files inside. Android receives folders with their tree, but without their modified dates.

File names and contents are never logged, and nothing leaves your network.

## Send to LocalSend

Ferret also talks to [LocalSend](../interop/localsend.md), so you can send files to friends' phones and computers that run it, iPhones included.

## Receive from any Android phone

No Ferret on that phone? Make your computer visible to [Quick Share](../interop/quick-share.md) for 10 minutes and send from the phone's share menu.

## Receive one file from a guest

A friend without Ferret wants to send you something? On Home, tap **Allow once** next to **Receive a file from a guest**. Your computer shows up in Quick Share and LocalSend for 10 minutes, and closes again once the first file arrives. See [A computer the family shares](../getting-started/shared-computer.md).
