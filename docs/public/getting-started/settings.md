# Find your way around

Ferret has four places: **Home**, a page per **device**, **Add a device** and **Settings**. Everything else is one tap below one of them.

> TL;DR
> 1. Tap a device on Home to see what works with it.
> 2. Tap **+** to add a device.
> 3. Open **Settings** for everything else. Each row shows its state before you open it.

## 📱 A device's page

Tap a device on Home. Its page answers three questions.

**What can I do with it?** The buttons at the top: **Send files**, **Send clipboard**, **Ring**, and more.

**What works with it?** One list, one line per feature:

| Mark | Means | What to do |
|---|---|---|
| ✓ | It works. The line says how: "Syncs by itself", "Arrive in Downloads". | Nothing. |
| – | It's off. The line says where: "Off on Pixel 9". | Tap **How?** for the steps. |
| ⚠ | It's on but something broke, such as a permission Android took back. | Tap **Fix**. |

**What may it do here?** Under **Pixel 9 may** you find the switches that are about this one device, such as letting it control this Mac without asking.

**How full is it?** Next to **Connected** a connected phone or laptop shows its battery, such as **62%**, with a bolt while it charges. When one of your devices drops to 15%, the others say so once: **Pixel 7 is at 15%**. Don't want that? Turn off **Settings → Advanced → Low battery notice**. Desktops have no battery, so they show none.

**Details** holds the device ID, its address and the day you paired. **Forget Pixel 9** is at the bottom. See [Pair your devices](pairing.md).

Not connected? The page says when it was last seen and offers **Why isn't it connecting?**. See [Fix connection](../features/connection-doctor.md).

## ⚙️ Settings

One screen, no scrolling. Each row shows where things stand and opens its own page.

| Row | What's inside |
|---|---|
| **This device** | **Rename** it (your other devices show the new name right away). On a computer, **Start Ferret when I log in**; on a Mac, **Always show in the Dock** too. On Android, how Ferret keeps running. |
| **Clipboard** | [Clipboard](../features/clipboard.md) sync and what it skips. |
| **Files** | Where [files](../features/drop.md) land and who may send them. |
| **Continue & media** | [Continue](../features/handoff.md) pages and [media](../features/media.md) controls. |
| **From your phone** | [Notifications](../features/notifications.md), [messages](../features/messages.md), [calls](../features/calls.md) and the phone's [screen](../features/mirroring.md). On the phone itself this row is **To your computer**. |
| **Control** | [Control](../features/remote-input.md) a computer from your phone, [sleep, restart or run your own actions](../features/computer-actions.md) on it, [find](../features/find.md) a device, and Power-ups on Android. |
| **Other apps** | [LocalSend](../interop/localsend.md), [Quick Share](../interop/quick-share.md), the [browser extension](browser.md) and an [iPhone](../iphone/index.md). |
| **Advanced** | This device's ID and address, **Pair once for all my devices**, on a Mac the keys that **Open Ferret from anywhere** (⌃⌥Space), **Language**, **Low battery notice**, **Check my network** and **Quit Ferret**. |
| **About · Privacy** | The [privacy](../privacy.md) promise, **Show tips again** for the short hints you waved off, **Sponsor Ferret**, the version and the licence. |

A row that can't apply to your device isn't there. No Power-ups on a Mac.

A small orange dot on a row means something you turned on isn't working. Open the row to see what. A feature you never set up stays quiet.

Switches about **one device** are not in Settings. They live on that device's page.

## ❤️ Sponsor Ferret

Ferret is free and open source. If it saves you time, **Settings → About → Sponsor Ferret** opens my GitHub Sponsors page in your browser. On a Mac it's in the **Help** menu too, and on Windows and Linux in the window's **•••** menu.

That's it. No popups, no banners, no reminders.

## 🌐 Language

Ferret follows your system's language. Want another one for Ferret only? Open **Settings → Advanced → Language** and pick it: **English** or **Tiếng Việt**. The app switches right away; menus, the tray icon and notifications follow the next time Ferret starts. On Android 13+ and on iPhone and Mac, Ferret also shows up in the system's per-app language settings.

Want Ferret in your language? See [Translate Ferret](../contributing/translating.md).
