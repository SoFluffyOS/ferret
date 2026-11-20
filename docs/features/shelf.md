# Shelf

> **TL;DR**
>
> 1. On a Mac, open Ferret from the menubar. The **Shelf** box sits at the bottom of every page.
> 2. Drop files, photos, text or links on it. Turn on **Keep copies** and what you copy lands there too.
> 3. Drag anything straight back out, into any app or onto a device.

You're moving a few things from one place to another: two PDFs from Downloads, a photo from your phone, a link from Slack. You drag one, then go back for the next, and the first window is gone. Or you copy something, copy something else, and the first copy is lost.

The shelf is a box to put things down for a moment. It lives at the bottom of the Ferret popover, always open, so you see what's in it at a glance and take it out in one move.

<figure class="shot shot-narrow">
  <img src="/assets/docs/shelf-items-light.webp" alt="The Ferret popover with the shelf box at the bottom showing a link, text, a photo, a folder and a file as tiles with their names" width="380" height="560" loading="lazy">
  <img src="/assets/docs/shelf-items-dark.webp" alt="The Ferret popover with the shelf box at the bottom showing a link, text, a photo, a folder and a file as tiles with their names" width="380" height="560" loading="lazy">
</figure>

## 📥 Put things in

- **Drag** files, folders, photos, text or links from Finder or any app onto the box. The whole box lights up and says **Drop to keep it**. Let go and the new tile pops in at the front.
- **Drag a photo out of your phone's Photos** in Ferret and drop it on the box. Ferret fetches it from the phone and keeps a copy.
- **Copy** anything on your Mac: text, a link, a picture, files in Finder. With **Keep copies** on, it shows up in the box by itself. Clips that arrive from your other devices show up too.

<figure class="shot shot-narrow">
  <img src="/assets/docs/shelf-drop-light.webp" alt="Something dragged over the shelf box: it turns blue and says Drop to keep it" width="380" height="560" loading="lazy">
  <img src="/assets/docs/shelf-drop-dark.webp" alt="Something dragged over the shelf box: it turns blue and says Drop to keep it" width="380" height="560" loading="lazy">
</figure>

Your own files stay where they are. The shelf only points at them, so a 4 GB video costs nothing. Text, links, pictures and phone photos are kept in Ferret's own folder.

Moved or deleted a file? Its tile goes grey and says **Moved or deleted** when you point at it. Take it off with ⓧ.

## 📤 Take things out

Every tile is the real thing. No clicking first.

- **Drag a tile** to take just that one.
- **Drag All** at the start of the box: everything goes at once.
- **⌘-click** a few tiles (or **⇧-click** for a range), then drag one of them: the whole selection goes.
- **Drop it on a device** in the popover to send it there.

Point at a tile and a ⓧ shows up in its corner to take it off. Right-click for **Quick Look**, **Show in Finder**, **Copy** (text and links) or **Remove**. **Space** previews what you selected, **Delete** takes it off.

**Clear** in the box's corner takes everything off. With six things or more, it asks once more. Your files stay where they are either way.

## 📋 The list

Want more detail? Click the list button next to **Clear**. You get every item with where it came from (copied, dropped, or from your phone), and the **Keep copies** switch.

<figure class="shot shot-narrow">
  <img src="/assets/docs/shelf-list-light.webp" alt="The shelf as a list: a link, text, a photo, a folder and a file, each with where it came from and a button to take it off" width="380" height="560" loading="lazy">
  <img src="/assets/docs/shelf-list-dark.webp" alt="The shelf as a list: a link, text, a photo, a folder and a file, each with where it came from and a button to take it off" width="380" height="560" loading="lazy">
</figure>

## 📋 Keep copies

Off by default. Your clipboard sees everything: passwords, codes, that message you didn't send. It shouldn't pile up on disk unless you ask.

Open the list and turn on **Keep copies**. That's it. Then pick how long they stay with **Keep them**:

<figure class="shot shot-narrow">
  <img src="/assets/docs/shelf-copies-light.webp" alt="The shelf list with Keep copies turned on and Keep them set to Until quit" width="380" height="560" loading="lazy">
  <img src="/assets/docs/shelf-copies-dark.webp" alt="The shelf list with Keep copies turned on and Keep them set to Until quit" width="380" height="560" loading="lazy">
</figure>

- **Until quit**: gone when you quit Ferret. The default.
- **1 day** or **7 days**: still there after a restart, then gone.

Turn **Keep copies** off and the copies come off the shelf right away. What you dropped stays.

It's also in **Settings → Clipboard → Shelf**.

## 🧹 It tidies itself

The shelf keeps the last 50 things. When it's full, the oldest copies make room first. What you dropped on it stays until **you** take it off, even after a restart.

## 🔒 Private

- The shelf never leaves your computer. Nothing on it is synced or sent to your other devices, unless you drop it on one.
- Copies from a password manager, or anything marked private, never go on it. Neither does anything an app put on the clipboard by itself.
- While your screen is locked, or on a [computer the family shares](../getting-started/shared-computer.md), the box only says how many things it holds. A clip from a phone whose previews you hid shows as **Hidden**.
- Ferret's copies live in `~/.sofluffy/ferret/cache/shelf`. Taking something off deletes Ferret's copy, never your own file.

## ❓ Good to know

- The shelf is on the Mac for now. Windows and Linux get it later.
- With **Keep copies** on, copies show up even when **Send automatically** is off in [Clipboard](clipboard.md). Ferret still never sends them unless you asked it to.
- With both off, Ferret doesn't watch your clipboard at all.
- Things you drag out of Ferret itself (a photo, a clip, something on the shelf) land on a device or the shelf, never on the menubar icon. Dropping on the icon is for files from other apps, so nothing goes to your last device by accident.
