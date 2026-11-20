# Coming from another app

You used KDE Connect, GSConnect, Phone Link, Intel Unison or Samsung Flow for years. Your hands know where everything was. Here's where each of those things lives in Ferret, under which name, and what isn't there yet.

> **TL;DR**
>
> 1. Pair your devices (see [Pair your devices](pairing.md)).
> 2. Open a device in Ferret. Almost everything you do WITH that device is on its page: the buttons at the top, **More**, and on a computer the sections under its name.
> 3. Turning things on and off is in **Settings**, grouped by what they're for. Find your old feature in the table below.

## 🗺️ Where things are

The name in the first column is what the other apps call it. Ferret's name is in bold.

| You know it as | In Ferret | Where |
|---|---|---|
| Share and receive, Send to, File transfer | **Send files**, **Send a folder** | The device's page (first button). Or drop files on the device's row, or use your file manager's Share / Send to menu: see [Send from the file manager](../features/share-menu.md) |
| Clipboard sync, Cross-device copy and paste | **Clipboard** | Syncs by itself. On Android, tap **Send clipboard** in the notification, the Quick Settings tile, or on the computer's row: see [Clipboard](../features/clipboard.md) |
| Ring my phone, Find my phone | **Ring** | The device's page (with **Ring** in **More** when the buttons don't fit). Rings even on silent: see [Find](../features/find.md) |
| Run commands | **Your actions** | Add them on the computer in **Settings → Control → Your actions**. Run them from the phone: open the computer, under **Your actions**. See [Computer actions](../features/computer-actions.md) |
| Remote input, Virtual input | **Control** | On the phone, open the computer and tap **Control**: a touchpad and a keyboard. See [Control](../features/remote-input.md) |
| Presentation remote, Slideshow remote | **Present** | On the phone, open the computer, **More → Present on MacBook Air** |
| Multimedia control, Media control | **Media** | **Now playing** on the device's page while something plays there, and a line at the top of **Activity**. See [Media](../features/media.md) |
| Pause media during calls | **Pause during calls** | **Settings → Continue & media → Media**. On by default |
| SMS, Messages | **Messages** | The phone's page, **Messages**. See [Messages](../features/messages.md) |
| Telephony, Calls | **Calls** | Calls ring on the computer; **Call…** on the phone's page starts one. You talk on the phone: see [Calls](../features/calls.md) |
| Notification sync, Notifications with reply | **Notifications** | Notices on the computer with **Reply** and **Dismiss**. Pick apps with **Choose apps** on the phone's page. See [Notifications](../features/notifications.md) |
| Battery monitor | Battery level | Next to the device's name, on Home and on its page. A notice when the phone runs low |
| Photos, Recent photos | **Photos** | The phone's page, **Photos**. See [Photos](../features/photos.md) |
| Apps, Phone screen, Screen mirroring | **Show screen** | The phone's page. With a cable, or over Wi-Fi. See [Screen](../features/mirroring.md) |
| Virtual display | **Use as display** | **More** on the other Mac or Android tablet's page. See [A second display](../features/second-display.md) |
| Phone as webcam | **Use camera** | **More** on the phone's page. Or USB on its own: see [Your Android phone as a webcam](../features/android-webcam.md) |
| Lock the computer from the phone | **Lock** | The computer's page. Or let it lock when your phone leaves: see [Computer actions](../features/computer-actions.md) |
| Open a link on the other device | **Send a link…**, **Continue** | **More** on the device's page. See [Continue](../features/handoff.md) |
| Command-line tool (`kdeconnect-cli`) | `ferret-cli` | `ferret-cli devices`, `send`, `ring`, `clipboard send`, `notify`, `action`. See [Scripting](../features/scripting.md) |

On a computer, the window has a keyboard shortcut for the big ones too. **Help → Keyboard shortcuts** lists them.

## 🚫 Not in Ferret (yet)

Straight answers, so you don't hunt for them:

- **Browse the phone's files** (the SFTP / "Browse device" mount). Not there. Photos and screenshots are in **Photos**; for anything else, send it from the phone with **Send files**.
- **Your computer's notifications on the phone.** Not mirrored. A script can still put a notice on your phone with `ferret-cli notify`.
- **Call audio on the computer.** You answer on the computer, but you talk on the phone. It's planned.
- **Send a ping.** Not needed: the device's page says whether it's connected, and **Fix connection…** checks the path for you.
- **Unlock the computer with the phone.** Ferret locks, but it never unlocks. On purpose.
- **Instant hotspot.** Ferret can't turn on your phone's hotspot. When a network keeps your devices apart, **Fix connection…** tells you to join the phone's hotspot yourself.
- **An account.** There is none, and nothing goes through a cloud. Pair once and you're done.

## 🔁 Things that work differently

- **Everything starts off.** Each feature is off until you turn it on, on the device that shares. Your phone asks for each permission the moment you turn a feature on, never at install.
- **Clipboard on Android needs a tap.** Android doesn't let any app read the clipboard in the background. Ferret is no exception. With [Shizuku](../android-modes/shizuku.md) it sends on its own.
- **Per-device access.** Each device has **What Pixel 7 can use** (with its own name) on its page. Turn off what you don't want one device to do, without touching the others.
- **Works on a Mac and an iPhone too.** Same app, same pairing, on Android, iPhone, Mac, Windows and Linux. An iPhone can't share its notifications or texts (iOS doesn't let any app), but it can do everything else it's allowed to.

## 🧹 Running both for a while?

You can. They don't share anything. Two things to watch:

- Two apps syncing the clipboard at once can send the same copy back and forth. Turn clipboard sync off in the old app.
- Both may show the same phone notification. Turn notifications off in one of them.

## Happy Coding 🦊
