# Reach your devices away from home

> **TL;DR**
>
> 1. Put both devices on your own VPN: Tailscale, ZeroTier or WireGuard.
> 2. In Ferret, open the device and tap **Reach away from home**.
> 3. Turn on **Also reach Pixel 7 over your VPN**. That's it.

Ferret talks over your local network. Leave the house with your phone and it drops off: your laptop at the office can't see it, and the phone on mobile data can't see your desktop at home.

If you already run a VPN between your devices, Ferret can use it. No Ferret account, no Ferret server, nothing in the middle. The VPN is yours, so the path is yours too.

## 🔑 How it works

- Turn on **Also reach Pixel 7 over your VPN** on the device's page. It's off by default, for each device.
- This device asks Pixel 7 for its VPN addresses. Pixel 7 sends them right away, or the next time they connect, over the same encrypted connection as everything else.
- When your local network doesn't find Pixel 7, Ferret dials those addresses. It tries a few seconds after the local network, then waits a bit longer after each miss, up to every 5 minutes.
- The local network ALWAYS comes first. Back home, Ferret moves the connection to your Wi-Fi by itself.
- The connection is checked exactly like at home: Pixel 7 has to prove it holds its own key, the one you paired. Someone else on your VPN can't pretend to be it.
- While it's connected that way, the device's **Details** say **Reached over your VPN**.

Big files over a VPN can be slower than at home, especially from a phone on mobile data. When the link is slow, Ferret says so, the same way it does far from the Wi-Fi.

## 📶 Mobile data

Away from Wi-Fi, everything that goes over your VPN counts toward your mobile data. On BOTH ends, if both are on mobile data.

- Clipboard, notifications and texts are tiny.
- Files and photos cost what they weigh.
- **Show screen** uses the most. Keep it for Wi-Fi.

While a device is reached over your VPN, **Reach away from home** shows how much went over it since it connected.

Both on mobile data? Your VPN may not get a direct path, and passes the traffic through its own relay (Tailscale calls them DERP). It stays encrypted end to end, by Ferret and by the VPN. It's only slower.

Your laptop on your phone's hotspot is different: that's a local network, and what goes between the laptop and the phone uses NO mobile data. Ferret finds the phone there by itself, no VPN needed.

## 🦎 Tailscale

1. Install [Tailscale](https://tailscale.com/download) on both devices and sign in to the same tailnet.
2. Check both show up in the Tailscale app, with a `100.x.y.z` address.
3. In Ferret, turn on **Also reach Pixel 7 over your VPN** while both are still at home. Ferret learns the addresses right away.

Already away? Type the address in **Reach at**: the `100.x.y.z` one, or its MagicDNS name such as `pixel-7.tail1234.ts.net`.

On Android, keep Tailscale running (it's a VPN app, so Android shows a key icon).

## 🌐 ZeroTier

1. Install [ZeroTier](https://www.zerotier.com/download/) on both devices and join the same network.
2. Authorize both in your network's admin page.
3. Turn on **Also reach Pixel 7 over your VPN** in Ferret, or type the ZeroTier address in **Reach at**.

## 🔐 WireGuard

1. Give each device a peer in your WireGuard setup, with **AllowedIPs** that let them reach each other's WireGuard address.
2. Bring the tunnel up on both.
3. Turn on **Also reach Pixel 7 over your VPN**. Ferret picks up addresses on WireGuard interfaces (`wg0`, `utun` on a Mac). If yours is named differently, type the address in **Reach at**.

Ferret listens on port 47640. Your VPN must let TCP through on that port between your devices. Ferret in another account on the same computer uses the next free port: add it to the address, such as `10.8.0.2:47642`.

## 🧭 Not connecting?

Open the device and tap **Fix connection**. With the switch on, it says Ferret also tries the VPN. With a VPN on and the switch off, it offers **Reach over your VPN**.

Still nothing? Check that:

- The VPN is on, on BOTH devices.
- Ferret is open on the other device. On Android, see [Keep Ferret running](../getting-started/android-keep-running.md).
- Your VPN's access rules let the two devices talk.

## 🙈 What's shared

- Your VPN addresses go only to devices that have this switch on for this device. No other paired device ever hears them.
- They travel inside the encrypted connection, never on your Wi-Fi in the open.
- Turn the switch off and Ferret forgets that device's VPN addresses, and stops any connection over the VPN.
- An address you type in **Reach at** stays on this device.

See [Privacy](../privacy.md).
