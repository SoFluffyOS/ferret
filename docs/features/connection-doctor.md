# Fix connection

When a paired device won't connect, Ferret tells you why. No guessing.

<figure class="shot">
  <img src="/assets/docs/fix-connection-light.webp" alt="Fix connection in the window: the network checks for a phone that is offline, with Try again" width="700" height="504" loading="lazy">
  <img src="/assets/docs/fix-connection-dark.webp" alt="Fix connection in the window: the network checks for a phone that is offline, with Try again" width="700" height="504" loading="lazy">
</figure>

## How to open it

Tap **Fix** next to a device that isn't connected, or open the device and tap **Find out why**.

The device you want to pair doesn't show up at all? **+** → **Check my network** runs the first two checks for this device alone. It's under **Settings → Advanced** too.

## What it checks

1. **This device's network.** Is it on Wi-Fi or Ethernet at all? A phone on mobile data only is told so: Ferret needs the same Wi-Fi, or your own VPN with **Reach over your VPN**.
2. **VPN.** A VPN can hide devices on your network. Allow local network access in the VPN, or turn it off for a moment. Is it your own VPN, such as Tailscale? Tap **Reach over your VPN** and Ferret uses it to reach the device away from home. With that on, it says Ferret also tries the VPN. See [Reach your devices away from home](away-from-home.md).
3. **Same network.** Were both devices last seen on the same Wi-Fi? Guest and office networks often keep devices apart.
4. **Is the other device answering?** If not, open Ferret on it. On Android, battery saving may have stopped it: see [Ferret on Android](../getting-started/android.md).
5. **Does it still know this device?** If it was reset or reinstalled, pair again.

Each problem comes with a button that fixes it, or tells you exactly where to go. The real fix is the filled button. **Connect by address** and **Copy diagnostics** sit as small links next to **Try again**, for when you or a friend dig deeper.

## On Windows: the firewall

The first time Ferret opens, Windows asks whether to allow it on your network. Close that question, or tick only one kind of network, and your other devices can't find this computer. Windows never asks again.

The installer can add Ferret's firewall rules for you (see [Ferret on Windows](../getting-started/windows.md)). Fix connection checks for them whenever your other device doesn't show up or doesn't answer:

- **Rules in place?** It says so. Still hidden? Your network is probably set to Public (below).
- **Rules missing?** Click **Allow through firewall**, then **Yes** when Windows asks. Then **Try again**.

Rather do it by hand? Click **Open Windows Firewall**, then **Change settings**, tick **Ferret** under both **Private** and **Public**, and select **OK**.

No button? Open **Windows Security → Firewall & network protection → Allow an app through firewall**. It's the same list.

Windows treats a new Wi-Fi as **Public** and hides your computer on it. That is why both boxes matter. On your home Wi-Fi you can also switch it: **Settings → Network & internet → Wi-Fi**, pick your network, then **Private network**. Do that only on a network you trust.

## On Linux: ufw and firewalld

Linux never asks whether to let an app through. If **ufw** (Ubuntu, Mint) or **firewalld** (Fedora, openSUSE) is on, it simply drops what your other devices send, and nothing tells you.

Fix connection checks which one is on, without asking for your password, and names it. **Copy the command** puts the right line on your clipboard. Paste it in a terminal:

```bash
# ufw
sudo ufw allow 47640/tcp && sudo ufw allow 47642:47649/tcp && sudo ufw allow 47641/udp && sudo ufw allow 5353/udp

# firewalld
sudo firewall-cmd --permanent --add-port=47640/tcp --add-port=47642-47649/tcp --add-port=47641/udp --add-service=mdns && sudo firewall-cmd --reload
```

That's it. `47640/tcp` is Ferret itself (`47642`–`47649` when another account on the same computer runs Ferret too), `47641/udp` and `5353/udp` (mDNS) are how your devices find each other.

## On café, hotel or campus Wi-Fi

Many public and guest networks keep devices apart on purpose (client isolation). Your laptop reaches the internet, your phone reaches the internet, but they can't see each other.

Fix connection spots it: the router answers, your other device doesn't, and Ferret never heard anyone on this network. It says **This network keeps devices apart**. Nothing on your devices can fix that. So it names your phone: **Turn on Pixel 7's hotspot and join it from this Mac.** Ferret works over a hotspot like over any Wi-Fi, and what goes between your devices never touches mobile data. Or use a home network.

**Check my network** says it too, as a "may", when Ferret hasn't heard any other device for a while.

## Reconnecting… and weak connection

A device whose connection just dropped, say the Wi-Fi hopped to another access point, says **Reconnecting…** and keeps its place in the list. Ferret dials it again after 1, 3, 10 and 30 seconds, then every few minutes. After that it reads **Last seen**.

A device that answers slowly says **Connected · weak connection**. Things still work, just slower. Move closer to the Wi-Fi or use 5 GHz.

## Connect by address

Some networks block devices from finding each other but still let them connect. Tap the **Connect by address** link at the bottom and type the address shown under **Settings → Advanced** on the other device, such as `192.168.1.20:47640`.

## Report a problem

The **Copy diagnostics** link at the bottom puts a short report on your clipboard. It has no names, no addresses and no content, so it's safe to paste into an issue.
