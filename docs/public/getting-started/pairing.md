# Pair your devices

Pairing is how two devices learn to trust each other. You do it once per device.

> TL;DR
> 1. Open Ferret on your computer and choose **Pair a device**.
> 2. On your phone, tap **Scan the code on your computer**.
> 3. Done. They connect on their own from now on.

## 📷 With a QR code (fastest)

1. On your computer, open Ferret and click **+** (Pair a device). A QR code appears.
2. On your phone, open Ferret, tap **+**, then **Scan the code on your computer**.
3. Point the camera at the code. That's it.

The code works once and expires after 5 minutes. It also carries your computer's address, so pairing works even on networks where devices can't see each other.

## 🔢 Without a camera: compare a code

Pairing two computers, or no camera handy? Use a code instead.

1. Both devices on the same network: the other one shows up under **Nearby**. Tap it.
2. Both screens show the **same six digits**. Check they match, then tap **Pair** on the other device.

Matching digits prove nobody sits in between. If they don't match, don't pair.

## 🔗 With a link

Click **Copy link** under the QR code and open it on the other device, or paste it into **Use a link**.

## 💻 From the command line

```sh
ferret offer                 # shows a link
ferret pair "ferret://pair?o=..."
ferret pair 192.168.1.20     # compare codes instead
```

## Not connecting?

Tap **Why?** next to the device. The [Connection Doctor](../features/connection-doctor.md) checks your network, VPN and the other device, then tells you what to fix.
