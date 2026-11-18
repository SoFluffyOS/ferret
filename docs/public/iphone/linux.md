---
order: 3
---
# iPhone on Linux

> **TL;DR**
>
> 1. In Ferret: **Settings → Other apps → Connect an iPhone**.
> 2. On the iPhone: **Settings → Bluetooth**, tap your computer under **Other Devices**, confirm the code on both.
> 3. Back in Ferret, tap **Use** next to the iPhone.

You need BlueZ 5.56 or later (every current distribution has it) and a Bluetooth adapter that does Bluetooth LE. Ferret talks to BlueZ over D-Bus. Nothing else to install.

## 🔑 Pair the iPhone

On Linux, the pairing starts **from the iPhone**. An iPhone won't let a computer connect to it first, so Ferret makes your computer show up in the iPhone's Bluetooth list.

1. In Ferret, open **Settings → Other apps** and turn on **Connect an iPhone**.
2. On the iPhone, open **Settings → Bluetooth**. Your computer appears under **Other Devices**. Tap it.
3. Both screens show a code. Your desktop (GNOME, KDE, …) asks you to confirm it. Same code? Confirm on both.
4. Back in Ferret, the iPhone is in the list. Tap **Use**.
5. The iPhone asks to share notifications with the computer, right after pairing or when Ferret first connects. **Allow** it.

No confirmation window on the computer? Open your desktop's Bluetooth settings and leave them open while you pair. A bare window manager needs a pairing agent, for example `bluetoothctl` with `agent on`.

## 📡 Why your computer is visible

While Ferret waits for the iPhone, your computer sends a small Bluetooth LE advertisement that says "I'd like notifications". That's what makes the iPhone list it, and what makes the iPhone **reconnect on its own** when you come back.

It stops as soon as the iPhone is connected, and when you turn **Connect an iPhone** off.

## 🧭 Good to know

- Check the switch on the iPhone: **Settings → Bluetooth → ⓘ** next to your computer → **Share System Notifications**.
- Bluetooth must be powered on: `bluetoothctl power on`, or your desktop's toggle.
- **Open Bluetooth settings** in Ferret tries GNOME Settings, KDE System Settings, then Blueman.
- After a suspend, give it up to half a minute.

This part of Ferret is tested against a simulated BlueZ and still needs testing on more distributions. If it doesn't connect on yours, tell us the distribution and `bluetoothctl --version`.
