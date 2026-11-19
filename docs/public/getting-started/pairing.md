# Pair your devices

Pairing is how your devices learn to trust each other. You do it **once**: pair a new device with any one of yours and it joins all of them.

> TL;DR
> 1. Open Ferret on both devices, on the same Wi-Fi.
> 2. Under **Nearby**, tap **Pair** next to the other device.
> 3. Both screens show the same six digits. Tap **They match**, then **Pair** on the other device.

No QR code to scan, no address to type.

## 📡 Nearby

Ferret looks for your other devices by itself. Open it on both, and each one shows the other under **Nearby**, on the home screen and under **+** (Add a device).

1. Tap **Pair** on the row of the device you want.
2. Both screens now show the **same six digits**, like `482 913`.
3. On the device where you tapped Pair: check the digits and tap **They match**.
4. On the other device: tap **Pair**.

That's it. The device moves to **Your devices** and connects on its own from now on.

The other device waits 30 seconds for your answer. Too slow? Tap **Try again**.

### Why the six digits?

Anyone on the Wi-Fi could pretend to be your phone. The digits come from the encrypted connection between the two devices plus a random number from each side, so they only match when the two screens really talk to each other. Different digits? Tap **Cancel** or **Not now**. Nothing is paired.

## 👨‍👩‍👧 Pair once, join them all

You have a Mac and a tablet that already work together, and you get a new phone. Pair the phone with the Mac. Done: the tablet knows the phone too, with no second pairing.

- The device you pair on tells you first: **You'll also be connected to Tablet.**
- Your other devices say **Pixel 7 joined your devices (added by MacBook Pro)**, with **Undo**. Undo forgets the phone on that device only.
- Several at once? One card and one notification: **iPad, ThinkPad X1, DESKTOP joined your devices**, with **Keep all** or **Review** to undo just one.
- A device that was off catches up the next time it connects.

Copy something on any of them and it reaches all the others.

Removing works the same way. Open a device, tap **Forget Pixel 7** at the bottom, and choose:

- **Remove from all my devices**: every device forgets it.
- **Forget on this Mac only**: just this one does.

The question opens right there on the page. Changed your mind? **Cancel**.

Prefer to pair each device by hand? Turn off **Settings → Advanced → Pair once for all my devices**. A device with the switch off neither passes its pairings on nor takes any in.

## 📱 Lots of devices

Two phones, a tablet and three computers? The list stays easy to read.

- 🕒 **Recently used first**: connected devices on top, then the ones you used last. A device you just used moves up after half a minute, or when you close the list, so it never slides away under your pointer. Offline ones fold into one line from 4 devices on.
- 📌 **Pin to Top**: open a device and tap **Pin to Top**, or right-click it in the window. Pinned devices lead their group, with a small pin by their name.
- 🏷️ **Two called Pixel 7?** Ferret adds the end of each one's id: **Pixel 7 (0718)** and **Pixel 7 (3F2A)**. Open one and tap **Rename…** to call it **Old Pixel** on this device only. The phone keeps its own name everywhere else.
- 🧹 **Not seen in 30 days**: Home offers **Remove…** for the devices nobody has seen in a month. Pinned ones stay. Your other devices keep them.
- 🔎 **Find a device**: with 9 or more, the window's list gets a search field.
- 🗂️ **Activity by device**: on Activity, tap **Pixel 7** or **iPhone** to see only what came from it.

## 🙈 Don't see it?

**Add a device** goes from the least effort to the most. Nearby devices first. Not listed? Check the two usual suspects:

1. Ferret is open on the other device.
2. Both are on the same Wi-Fi. Guest networks and some office networks keep devices apart.

An iPhone never shows up here: it can't look for devices by itself. Pair it with a QR code. See [Ferret on iPhone](iphone.md).

Not sure about your network? **Check my network** looks at this device's Wi-Fi and VPN and tells you what it found.

Still nothing? Two more rows wait below.

### 📷 Pair with a QR code

1. On your computer, open **+**, then **Pair with a QR code**. The code appears.
2. On your phone, open **+**, then **Pair with a QR code** (on an iPhone: **Scan the code on your computer**). The camera opens: point it at the code.

Nothing paired yet on the phone? The button on its home screen opens the camera straight away.

Scanning is enough, there are no digits to compare: the code carries a one-time secret that only someone looking at your screen has. It works once and expires after 5 minutes. **New code** makes a fresh one. It also carries your computer's address, so it works on networks where devices can't find each other.

### 🔗 Other ways

For networks that hide devices from each other:

- **With a link**: tap **Copy link** and open the link on the other device, or paste the other device's link and tap **Pair with link**.
- **With an address**: type the other device's address and tap **Pair with address**, then compare the six digits. The address is under **Settings → Advanced** on the other device.

On a phone, **Show a QR code** is here too, for pairing two phones.

## 🍎 On a Mac: allow the local network

The first time Ferret looks for devices, macOS asks whether it may find devices on your local network. Say **Allow**. Said no, or never saw the question? Ferret tells you so under **Nearby** with an **Open Settings** button: turn Ferret on under **Privacy & Security → Local Network**.

## 💻 From the command line

```sh
ferret-cli daemon                # shows who is nearby, asks before pairing
ferret-cli offer                 # shows a link
ferret-cli pair "ferret://pair?o=..."
ferret-cli pair 192.168.1.20     # compare codes instead
ferret-cli unpair "Pixel 7" --everywhere
ferret-cli devices --json        # for scripts
ferret-cli send report.pdf       # hands files (or a folder) to the running Ferret app
ferret-cli ring "Pixel 7"        # rings it, even on silent
ferret-cli clipboard get         # the last text copied on another device
ferret-cli clipboard send "hi"   # or pipe it in: date | ferret-cli clipboard send
```

`ferret` is the app itself. `ferret-cli` is the command line, so both can sit on your `PATH`. `ferret send` works with either one.

The command line is its own device, named after your computer with **· Terminal**. It keeps its key and pairings in `~/.sofluffy/ferret/cli`. Set `FERRET_HOME` to move Ferret's whole folder somewhere else.

## Not connecting?

Tap **Fix** next to the device. [Fix connection](../features/connection-doctor.md) checks your network, VPN and the other device, then tells you what to fix.
