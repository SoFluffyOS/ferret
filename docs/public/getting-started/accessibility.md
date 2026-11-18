# Accessibility

An app you can't read, hear or reach with a keyboard is an app you can't use. Ferret works with a screen reader, a keyboard, large text and both colour modes. This page says how, and where it still falls short.

> TL;DR
> 1. Turn on VoiceOver or TalkBack: every button has a name, every switch says on or off.
> 2. No mouse? **Tab** walks the window, **Enter** or **Space** presses, **Esc** says "Not now".
> 3. Set your system's text size as large as you like. Ferret follows it.

## 🔊 With a screen reader

VoiceOver on a Mac or an iPhone, TalkBack on Android. Nothing to set up in Ferret.

- **Buttons have names.** **+** is "Add a device", **•••** is "More", the cross on a tip is "Got it". Not "button, button, button".
- **Switches say their name and their state.** "Sync clipboard, switch, on". One stop, not two.
- **The pairing code is read digit by digit.** "Code: 4 8 2 0 1 7", as soon as it shows up, so you can compare it with what your other device says.
- **Status comes in words.** A device is "Connected" or "Not connected". A line under **What works** says "OK", "Off" or "Needs attention" before its name. The colour is extra.
- **What changes is spoken.** A file that finished, a transfer that failed, a phone that asks to send you something.
- **Right-click menus are actions.** What a right-click offers on a device or an Activity line is in your screen reader's actions menu for that line.

In the window, the device list on the left and the page next to it are both there. Move between them like in any other app.

## ⌨️ With a keyboard

On a computer you never need the mouse.

| Key | What it does |
|---|---|
| **Tab** / **Shift Tab** | Next / previous button, switch or row. From the page it goes on into the device list, and back |
| **Enter** or **Space** | Press what has the focus. Flips a switch |
| **Esc** | Close a menu. On a pairing request it answers **Not now** |

What has the focus wears a blue ring. A blue button wears one that stands out from it, so you see it either way.

The window has shortcuts for everything you do often: ⌘1 to ⌘6 for a device's sections, ⌘N to add a device, ⌘, for Settings. The full list is on the [Mac page](mac.md).

## 🔎 With large text

Ferret follows your system's text size. No setting of its own.

Every main screen is checked at 200%: no button ends up out of reach. Rows that hold a title next to a value put the value below. Two buttons side by side stack. The pairing code always stays on one line, all six digits.

## 🌗 Contrast

Text has a contrast of at least 4.5:1 with what is behind it, in light and in dark mode, checked on every main screen. That includes the grey secondary lines, the links, and the green, orange and red status lines.

Nothing is said with colour alone. A status dot always has words next to it, or under your pointer.

## 🚧 Where it falls short

Better you hear it from me:

- **Small buttons on phones.** Some buttons and links are lower than the 48 dp Android asks for (44 pt on iPhone). Bigger touch areas are on the way.
- **Icons don't grow with the text.** At 200% the words are big and the icons next to them stay small.
- **An empty page keeps Tab.** In the window, a page with nothing to press doesn't hand Tab over to the device list. ⌘1 to ⌘6 and the menu bar still get you there.
- **The mirrored screen.** Your phone's screen in a window is a picture to a screen reader. Use the phone's own screen reader for what is on it.

Found something that isn't on this list? Open an issue. Say which screen reader and which screen, and it gets fixed.
