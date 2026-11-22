---
order: 8
---
# A second display

> **TL;DR**
>
> 1. On your Mac, open your other Mac (or your Android tablet or phone) in Ferret and click **Use as display**.
> 2. On the other device, tap **Allow**.
> 3. Drag a window onto it. That's it.

One screen is never enough. And there's a second screen on your desk doing nothing: an old MacBook, an Android tablet, even your phone.

Ferret turns it into a real extra display for your Mac. Not a mirror: macOS sees one more monitor, so you move windows onto it, arrange it in **System Settings → Displays**, and work on it.

> 🧪 **Beta.** It works in my tests, but it hasn't met enough real devices yet. Something off? [Open an issue](https://github.com/simonpham/ferret/issues).

## 🖥️ Start it

On the Mac whose desktop you want to extend:

- Open the other device in Ferret and click **Use as display**. It may sit behind **More**, where it reads **Use MacBook Air as a display**.
- The first time, macOS asks to let Ferret record the screen. Ferret only ever captures the extra display it makes, nothing else. Turn Ferret on in **Privacy & Security → Screen Recording**, then quit and open Ferret again.
- Allow Ferret in **Accessibility** too, so clicks on the other device land where you point.

Activity says **Asking MacBook Air to be a display…** while you wait.

On the other device, Ferret asks **MacBook Pro wants to use this Mac as a display** (or **this tablet**, **this phone**). Tap **Allow**. Its screen turns into your Mac's extra display, full screen and sharp: the display is made the exact size of that screen, Retina included.

## 🖱️ Use it on a Mac

- The other Mac's mouse, trackpad and keyboard work on it, shortcuts too. **⌘Q** stays on that Mac, so you never quit its Ferret by accident.
- Move the pointer to the top edge for a small bar with **Full screen** and **Stop**.
- **Esc** leaves full screen. The display keeps going in a window.

## 📱 Use it on Android

Your fingers are the mouse:

- **Tap** to click.
- **Drag** to drag: move windows, select text.
- **Hold** for a right-click.
- **Two fingers** to scroll.

A keyboard plugged into the tablet types on your Mac too.

- The display is made the way you hold the tablet when you tap **Allow**, portrait or landscape, and stays that way.
- The screen stays on while it shows, and the system bars hide.
- Tap the small handle at the top for a bar with **Stop**.
- **Back** asks **Stop being MacBook Pro's display?** first, so a stray swipe never ends it.
- Press **Home** and it keeps going: a notice says **This tablet is MacBook Pro's display**, with **Stop**. Tap it and the picture is back in a blink. Ferret stops drawing it meanwhile to save your battery, and ends it after 10 minutes away.

## 🔒 You stay in charge

- The other device always asks first. Nobody answers in 30 seconds? That's a no.
- Both show it the whole time: **MacBook Air is a display for this Mac** on one, **This tablet is MacBook Pro's display** on the other, each with **Stop**.
- **Stop** on either side ends it at once. So does losing the connection or quitting Ferret. The extra display goes away, and its windows move back to your Mac's own screen.
- It goes straight between your devices, encrypted, over your own network.

## 🧩 Good to know

- Both need this version of Ferret. The Mac that lends its desktop needs macOS 12.3 or later.
- The extra display tops out at 60 Hz, even on a 90 or 120 Hz tablet.
- A wired network or a good 5 GHz Wi-Fi makes it feel close to a real monitor.
- 🪟 Windows and 🐧 Linux are coming, both as the screen and as the computer that extends. iPad too.

## Happy Coding 🦊
