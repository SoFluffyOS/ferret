# Wake-on-LAN

> **TL;DR**
>
> 1. Turn on Wake-on-LAN on the computer once (steps below).
> 2. Let it sleep.
> 3. On your phone, tap **Wake** on its row. It connects within a minute.

Your desktop is asleep in the other room. The file you need is on it. Walking over to press a key is annoying.

Ferret can wake it from any of your devices.

<figure class="shot shot-narrow">
  <img src="/assets/docs/wake-light.webp" alt="A sleeping computer on the phone, waking" width="380" height="822" loading="lazy">
  <img src="/assets/docs/wake-dark.webp" alt="A sleeping computer on the phone, waking" width="380" height="822" loading="lazy">
</figure>

## ⚡ How it works

- Each computer tells your paired devices how to wake it: the hardware (MAC) address and network of its cable and Wi-Fi cards. It says it again when they change.
- When a computer is offline, its row and its page show **Wake**.
- Tap it and Ferret sends a Wake-on-LAN "magic packet" from this device, to the computer's network and to its last address, on ports 9 and 7.
- At the same time it asks every computer of yours that is on to send the packet too. That covers an iPhone, which can't send it, and a phone on another network.
- The row says **Waking MacBook Pro… (up to a minute)**, then turns into **Connected** when the computer is back.
- No answer after about 90 seconds? It says **Didn't wake**, with **Try again** and **How to turn on Wake-on-LAN**.

## 🔌 Cable or Wi-Fi

Be honest with yourself here: Wake-on-LAN is made for a **cable**.

- A computer plugged into the router with a cable wakes reliably once Wake-on-LAN is on.
- Over Wi-Fi, most computers don't wake at all. Their Wi-Fi card is off while they sleep.
- A Mac on Wi-Fi wakes only through a Bonjour Sleep Proxy: an Apple TV or HomePod on the same network.

The computer's page tells you what it found: **Can wake it from sleep**, **Wake-on-LAN is off on Family PC** or **Wi-Fi only: it may not wake**.

Wake it from **sleep**. Waking from shut down works on many PCs too, but needs the firmware setting below and, on Windows, Fast startup off.

## 🍎 Mac

1. Open **System Settings → Battery → Options**.
2. Set **Wake for network access** to **Always** (or **Only on power adapter**).

On a desktop Mac it is under **System Settings → Energy**. Ferret on the Mac shows the setting under **Settings → Control → Wake-on-LAN**.

## 🪟 Windows

1. Open **Device Manager → Network adapters**, then your Ethernet card → **Properties**.
2. **Power Management**: turn on **Allow this device to wake the computer** and **Only allow a magic packet to wake the computer**.
3. **Advanced**: set **Wake on Magic Packet** to **Enabled**.
4. To wake it from shut down too, turn off Fast startup: **Control Panel → Power Options → Choose what the power buttons do**.

## 🐧 Linux

Turn it on for your card (`ip link` shows its name):

```bash
sudo ethtool -s enp3s0 wol g
```

Keep it after a restart, with NetworkManager:

```bash
nmcli connection modify "Wired connection 1" 802-3-ethernet.wake-on-lan magic
```

Ferret reads the setting with `ethtool` when it is installed.

## 🧰 BIOS or UEFI (PCs)

Press **F2**, **Del** or **F12** while the PC starts. Turn on **Wake on LAN**, **Power On by PCI-E** or a setting with a similar name. Turn off **ErP** or **Deep Sleep**: they cut power to the network card.

## 📱 From an iPhone

iOS doesn't let apps broadcast on the network without a special permission from Apple. So an iPhone can't send the magic packet by itself.

Ferret asks another of your devices that is on to send it: a Mac, a PC, or `ferret-cli daemon` on a home server. Keep one of them on and **Wake** works from your iPhone too.

## 🖥️ On a computer

**Settings → Control → Wake-on-LAN** shows this computer's cards and whether they wake, and two switches:

- **Let my devices wake this computer**: shares the MAC address with your paired devices. Turn it off and they forget it.
- **Wake computers for my phones**: when one of your phones asks, this computer sends the packet to another of your computers. It only does that for a computer it is paired with too.

## ⌨️ From the command line

```bash
ferret-cli wake "Family PC"
ferret-cli wake 3c:22:fb:12:34:56
```

It asks the Ferret app running on this computer. Without the app, it wakes the computers paired with `ferret-cli daemon`, or the MAC address you give it. Add `--json` for scripts.

## 🔒 Privacy

A MAC address identifies a computer, so Ferret shares it **only with your paired devices**, end-to-end encrypted, and never anywhere else. Turn off **Let my devices wake this computer**, or turn off Wake-on-LAN for one device in **What Pixel 7 can use**, and it stops. The magic packet itself carries only the MAC address.

That's it. Your computer can sleep, and you still reach it. 🦊
