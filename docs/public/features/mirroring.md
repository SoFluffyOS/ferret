# Screen

> **TL;DR**
>
> 1. On your computer, open your Android phone in Ferret.
> 2. Click **Show screen**.
> 3. Tap **Start** on the phone's prompt. That's it.

Your phone is charging across the desk. A message comes in, or you want to show an app in a call. Picking the phone up every time gets old.

With Ferret, the phone's screen shows up on your computer. Over your own Wi-Fi, nothing else.

## 📺 The mirror page

- **Fit** scales the picture to the window. **1:1** shows one phone pixel per screen pixel, with scrolling.
- **Full screen** shows where the window can do it.
- The line under the picture tells you how it is going: `H.264 · 1080×2400 · 58 fps · 24 ms · 5.2 Mbps`.
- **Stop** ends it on both devices at once.
- **Back** keeps it running. The home card says "Showing Pixel's screen" with **Open** and **Stop**.

Rotate the phone and the picture follows. Screen off? The page says so, and the picture comes back when you wake the phone.

Mirroring over Ferret is view only. To type or click from afar, see [Control](remote-input.md).

## 🧪 More ways to show a screen

Not every screen has Ferret behind it. A spare phone on your desk, an iPhone, a test device.

Ferret can show those too. This part is **experimental** and off until you ask for it:

1. On the computer, open **Settings → Screen**.
2. Turn on **More ways to show a screen**.

That's it. Screens found this way appear on the home card under **Screens you can show**, each with **Show screen**.

Some devices start it themselves, like an iPhone from Control Center. Those have their own switch right below, such as **Show iPhone and iPad screens here**. It starts off on a Mac, which can already do this by itself.

Ferret asks you first, every time: "Simon's iPhone wants to show its screen here", with **Allow** and **Don't allow**. No answer in 30 seconds is a no. After **Allow**, the screen opens by itself.

- [Mirror a phone without Ferret on it](mirroring-with-a-cable.md): any Android phone, over a cable or Wi-Fi.
- [Show an iPhone's screen](mirroring-from-iphone.md): from Control Center, nothing to install.

A phone you paired shows once. When Ferret's own connection can show it, that is the one used.

Something missing? Settings and the mirror page say what, in plain words with a "How to", and **Check again** once you did it.

Some of these ways let you use the phone from the computer: click, scroll and type on the picture, and press **Back**, **Home** and **Recent apps** under it. No buttons there means view only.

## 🔐 You stay in charge

Nobody sees your screen without you knowing.

- **Every time**, Android asks you with its own prompt. Ferret never remembers a yes. There is no "Always".
- **While it happens**, a notice you can't swipe away says "Sharing screen with MacBook" with **Stop**. The home card says it too, and Android shows its own icon in the status bar.
- **Afterwards**, both devices keep a line such as "MacBook saw this phone's screen for 12 min at 21:10". The last 20 are in **Settings → Screen → History**.
- Don't want it at all? Turn off **Let my computers ask to see this screen** on the phone.

Phone in your pocket when the computer asks? Ferret posts a notice: "MacBook wants to see this screen". Tap it to get the prompt. The question stays for a minute.

Said no? The same computer can ask again after 30 seconds, not before.

Only devices you paired can even ask. One computer at a time.

## 🩺 When it doesn't start

The mirror page always says why, with **Try again**:

| It says | What to do |
|---|---|
| Pixel said no | Someone tapped Cancel on the prompt. Ask again in half a minute |
| Nobody answered on Pixel | Wake the phone, then try again |
| Pixel couldn't show the question | Open Ferret on the phone, or allow its notifications |
| Screen sharing is off on Pixel | On Pixel: open Ferret's settings, then Screen, and turn it on |
| Pixel stopped sharing | Android ends sharing when the phone locks (Android 15 and later) or when you stop it from the status bar |
| Lost the connection to Pixel | Ferret reconnects on its own. Try again after |

## 🎞️ How the picture travels

The phone encodes its screen as H.264 video with its hardware encoder: up to 1080p, up to 60 frames per second, 2 to 8 Mbps. Ferret picks the bitrate from how the connection is doing, and drops frames instead of falling behind.

It travels inside the same encrypted connection as everything else in Ferret. No server, no cloud.

A Mac decodes it with its own hardware decoder. Windows and Linux get a JPEG picture about 10 times per second for now: slower, but it works everywhere with nothing to install.

## 🧭 Limits per platform

| Phone | Shares its screen |
|---|---|
| Android 7 and later | Yes |
| iPhone and iPad | No. iOS only lets an app record itself |

| Computer | Shows the phone | Picture |
|---|---|---|
| macOS | Yes | H.264, up to 60 fps |
| Windows | Yes | JPEG, about 10 fps |
| Linux | Yes | JPEG, about 10 fps |

- **No sound.** Only the picture is sent.
- **Protected screens stay black.** Banking apps, password fields and DRM video can tell Android to hide them from any capture. Ferret can't see them, and shouldn't.
- **Screen off on the phone while mirroring** isn't offered. Android only allows that with root.
- **One app only**: on Android 14 and later the prompt lets you share a single app instead of the whole screen. Ferret shows whatever you pick.
