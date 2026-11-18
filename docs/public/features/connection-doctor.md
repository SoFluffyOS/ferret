# Fix connection

When a paired device won't connect, Ferret tells you why. No guessing.

## How to open it

Tap **Fix** next to a device that isn't connected, or open the device and tap **Why isn't it connecting?**.

The device you want to pair doesn't show up at all? **+** → **Check my network** runs the first two checks for this device alone. It's under **Settings → Advanced** too.

## What it checks

1. **This device's network.** Is it on Wi-Fi or Ethernet at all?
2. **VPN.** A VPN can hide devices on your network. Allow local network access in the VPN, or turn it off for a moment.
3. **Same network.** Were both devices last seen on the same Wi-Fi? Guest and office networks often keep devices apart.
4. **Is the other device answering?** If not, open Ferret on it. On Android, battery saving may have stopped it: see [Ferret on Android](../getting-started/android.md).
5. **Does it still know this device?** If it was reset or reinstalled, pair again.

Each problem comes with a button that fixes it, or tells you exactly where to go.

## On Windows: the firewall

The first time Ferret opens, Windows asks whether to allow it on your network. Close that question, or tick only one kind of network, and your other devices can't find this computer. Windows never asks again.

Fix connection names it whenever your other device doesn't show up or doesn't answer:

1. Click **Open Windows Firewall**, then **Change settings**.
2. Tick **Ferret**, under both **Private** and **Public**.
3. Select **OK**, then **Try again**.

No button? Open **Windows Security → Firewall & network protection → Allow an app through firewall**. It's the same list.

Windows treats a new Wi-Fi as **Public** and hides your computer on it. That is why both boxes matter. On your home Wi-Fi you can also switch it: **Settings → Network & internet → Wi-Fi**, pick your network, then **Private network**. Do that only on a network you trust.

## On Linux: ufw and firewalld

Linux never asks whether to let an app through. If **ufw** (Ubuntu, Mint) or **firewalld** (Fedora, openSUSE) is on, it simply drops what your other devices send, and nothing tells you.

Fix connection checks which one is on, without asking for your password, and names it. **Copy the command** puts the right line on your clipboard. Paste it in a terminal:

```bash
# ufw
sudo ufw allow 47640/tcp && sudo ufw allow 47641/udp && sudo ufw allow 5353/udp

# firewalld
sudo firewall-cmd --permanent --add-port=47640/tcp --add-port=47641/udp --add-service=mdns && sudo firewall-cmd --reload
```

That's it. `47640/tcp` is Ferret itself, `47641/udp` and `5353/udp` (mDNS) are how your devices find each other.

## Connect by address

Some networks block devices from finding each other but still let them connect. Use **Connect by address** and type the address shown under **Settings → Advanced** on the other device, such as `192.168.1.20:47640`.

## Report a problem

**Copy diagnostics** puts a short report on your clipboard. It has no names, no addresses and no content, so it's safe to paste into an issue.
