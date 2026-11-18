# Pair your devices

Pairing is how your devices learn to trust each other. You do it **once**: pair a new device with any one of yours and it joins all of them.

> TL;DR
> 1. Open Ferret on both devices, on the same Wi-Fi.
> 2. Under **Devices near you**, tap **Pair** next to the other device.
> 3. Both screens show the same six digits. Tap **They match**, then **Pair** on the other device.

No QR code to scan, no address to type.

## 📡 Devices near you

Ferret looks for your other devices by itself. Open it on both, and each one shows the other under **Devices near you**, on the home screen and under **+** (Add a device).

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
- A device that was off catches up the next time it connects.

Copy something on any of them and it reaches all the others.

Removing works the same way. Open a device, tap **Forget this device**, and choose:

- **Remove from all my devices**: every device forgets it.
- **Forget here only**: just this one does.

Prefer to pair each device by hand? Turn off **Settings → Your devices → Share pairings with my devices**. A device with the switch off neither passes its pairings on nor takes any in.

## 🙈 Can't see your device?

Tap **Can't see your device?**. First check the two usual suspects:

1. Ferret is open on the other device.
2. Both are on the same Wi-Fi. Guest networks and some office networks keep devices apart.

Still nothing? Use one of these.

### 📷 A QR code

1. On your computer, open **+**, then **Can't see your device?**. A QR code appears.
2. On your phone, open **+**, **Can't see your device?**, then **Scan the code on your computer**.

Scanning is enough, there are no digits to compare: the code carries a one-time secret that only someone looking at your screen has. It works once and expires after 5 minutes. It also carries your computer's address, so it works on networks where devices can't find each other.

### 🔗 A link or an address

Under **Other ways**, tap **Copy link** and open the link on the other device, or type the other device's address and compare the six digits.

## 🍎 On a Mac: allow the local network

The first time Ferret looks for devices, macOS asks whether it may find devices on your local network. Say **Allow**. Said no, or never saw the question? Ferret tells you so under **Devices near you** with an **Open Settings** button: turn Ferret on under **Privacy & Security → Local Network**.

## 💻 From the command line

```sh
ferret daemon                # shows who is nearby, asks before pairing
ferret offer                 # shows a link
ferret pair "ferret://pair?o=..."
ferret pair 192.168.1.20     # compare codes instead
ferret unpair "Pixel 7" --everywhere
```

The command line is its own device, named after your computer with **· Terminal**. It keeps its key and pairings in `~/.sofluffy/ferret/cli`. Set `FERRET_HOME` to move Ferret's whole folder somewhere else.

## Not connecting?

Tap **Why?** next to the device. The [Connection Doctor](../features/connection-doctor.md) checks your network, VPN and the other device, then tells you what to fix.
