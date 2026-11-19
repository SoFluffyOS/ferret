# Control

> **TL;DR**
>
> 1. On your phone, open your computer in Ferret.
> 2. Tap **Control**.
> 3. Click **Always allow** or **Allow once** on the computer. That's it.

You're on the couch. The laptop is across the room, playing a movie. You want to pause it, or click "Next episode".

With Ferret, your phone becomes the computer's touchpad and keyboard. Over your own Wi-Fi, nothing else.

## 🖱️ The touchpad

- **One finger** moves the pointer. A quick flick goes further.
- **Tap** to click. Tap twice for a double click.
- **Hold** to right-click. A **two-finger tap** works too.
- **Two fingers** scroll. Flick them and the page on the computer glides on for a moment, like on a laptop.
- **Tap, then slide** to drag. Or hold **Left click** under the pad and move with another finger.

The page itself never scrolls or bounces under your fingers, and the iPhone's swipe back is off while you're in control. **Stop control** or Back leaves.

## ⌨️ The keyboard

Tap **Keyboard** and type: the text appears on the computer, in any language. Backspace and Enter work as you'd expect.

Done typing? Tap **Hide keyboard**, or just touch the pad. While the keyboard is up, the pad shrinks to stay above it.

Under it: Esc, Tab, the arrows, Backspace and Enter. Then **Ctrl**, **Alt**, **Shift** and **Cmd** (Win or Super on Windows and Linux). Tap one, then a letter: that's a shortcut, such as Cmd then C to copy.

Next to them sit the media keys: previous, play or pause, next, and the volume. A row that doesn't fit slides sideways.

## 🎤 Present from your phone

Giving a talk and the clicker is at home? On your phone, open the computer and tap **Present on MacBook Air** (under **More**).

- 👉 A huge **Next**, plus **Previous**. They press Page Down and Page Up, like a clicker, so they work in PowerPoint, Keynote, Google Slides and PDFs in full screen.
- ⬛ **Black screen** blacks the slides out (the `B` key), and **Show slides** brings them back.
- ⏱️ A timer starts with the first slide. Tap the time to start over.

It asks for control like the touchpad does, and lets go when you close the page.

## 🔒 Lock this computer

Walked away from your desk and forgot to lock it? On your phone, open the computer and tap **Lock MacBook Air** (under **More**).

The first time, the computer asks: **Let Pixel 7 lock this Mac?** Pick **Always allow** and next time it locks right away, with no question. A phone you always allow to control the computer may lock it too.

- 🍎 macOS: the same lock as **Apple menu → Lock Screen**. No Accessibility access needed.
- 🪟 Windows: the same as Windows+L.
- 🐧 Linux: `loginctl lock-session`, which GNOME, KDE Plasma and most desktops follow. Falls back to `xdg-screensaver lock`.

Only locking, never unlocking. Change your mind in the computer's **What Pixel 7 can use → Lock this Mac without asking**.

## 🔐 You stay in charge

Nobody takes over your computer without you knowing.

- **The first time** a phone asks, the computer asks you: "Let Pixel control this computer?" with **Always allow**, **Allow once** and **Don't allow**. It shows up as a notice, on top of Ferret, and on the home card.
- **While it happens**, a notice says "Pixel is controlling this Mac" with **Stop control**, and so does the top line of **Activity**, with **Stop**. Either cuts the phone off right away and lets go of any held key.
- **Afterwards**, **Activity** keeps a line such as "Pixel controlled this Mac · For 4 min" until you dismiss it with **✕**. The last 20 are in **Settings → Control**, under **History**.
- Changed your mind about Always allow? On the computer, open the phone in Ferret and turn off **Control this Mac without asking**. The same switch turns it on without waiting for the phone to ask.
- Don't want it at all? Turn off **Let my phones control this computer** in **Settings → Control**.

Control also ends on its own after 10 minutes without any input, or when the phone leaves the touchpad page.

Only devices you paired can even ask.

## 🍎 On a Mac: Accessibility access

macOS asks before any app may move the pointer or type. Ferret asks the first time it needs it:

1. Click **Allow access** in **Settings → Control** (or **Open Settings** on the card).
2. Turn on **Ferret** in **Privacy & Security → Accessibility**.
3. Come back to Ferret. It checks again on its own.

If a phone asks before that, the Mac tells you why it couldn't, and the phone says "Mac needs Accessibility access first".

## 🐧 On Linux

Ferret picks the best way it finds:

1. **uinput**: a virtual mouse and keyboard. Works on X11 and Wayland. Needs write access to `/dev/uinput` (for example a udev rule giving your user's group access).
2. **ydotool** on Wayland (1.0 or later, with the `ydotoold` service running).
3. **xdotool** on X11.

None of them? **Settings → Control** says what to install, with **Check again**.

With uinput, text types through a US keyboard layout. Ferret hands anything else, such as accents, to xdotool or ydotool when one is installed.

## 🧭 Limits per platform

| Computer | Works | Needs |
|---|---|---|
| macOS | Yes | Accessibility access |
| Windows | Yes | Nothing. Apps running as administrator ignore it, a Windows rule |
| Linux | Yes | uinput access, ydotool or xdotool |

| Phone | Touchpad |
|---|---|
| Android | Yes |
| iPhone and iPad | Yes, while Ferret is open |

### Controlling a phone from the computer

Not yet. Android only lets an app tap and type for you through an Accessibility service (a big warning, and Google Play rules) or through Shizuku or root. iOS doesn't allow it at all.

The plan for Android: the same messages, the phone as the controlled side, behind an Accessibility service you turn on yourself, with the same consent, indicator and history. Shizuku would make it work without that service.
