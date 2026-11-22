---
order: 9
---
# A work computer

You brought your work laptop home. Your phone sits right next to it. And Ferret can't see it.

On a company Mac or PC, three things usually get in the way: a VPN that carries everything, a firewall you can't change, and settings your IT team manages. Here's how to tell which one, and what to send IT.

> **TL;DR**
>
> 1. Open the device and tap **Fix connection**. It says when your VPN takes the traffic, or when the firewall needs an administrator
> 2. Office or guest Wi-Fi? It often keeps devices apart. Try your home Wi-Fi or your phone's hotspot
> 3. Still stuck? Send your IT team the [section below](#-for-your-it-team). It lists everything Ferret needs

## 🔌 The VPN carries everything

Many work VPNs send ALL traffic through the office, even to the phone on your desk. Ferret finds devices on your Wi-Fi, so it finds nothing.

**Fix connection** checks which way your computer sends traffic to your phone. When it goes into the VPN, it says so: **Your VPN (utun4) carries everything…**

What helps:

- **Allow local network access in the VPN app.** Cisco Secure Client calls it **Allow local (LAN) access when using VPN**, in its preferences. It only shows when IT allows it.
- **Ask IT for it.** In GlobalProtect, Zscaler and Netskope it's a setting on their side, not yours.
- **Disconnect the VPN** for a moment, if you're allowed to.

Your phone's hotspot doesn't help here. The VPN carries the hotspot's traffic too.

## 🧱 The firewall needs an administrator

On Windows, **Allow through firewall** shows a prompt that needs an administrator. No admin account? Windows doesn't add the rules, and Fix connection says so, with the ports to give IT.

One catch: when you dismiss Windows' own "allow this app?" question without admin rights, Windows can quietly add a rule that BLOCKS Ferret. IT can remove it.

## 🍎 Permissions your IT team manages

Some features need a permission on a Mac: **Accessibility** to let your phone move the pointer and type, **Screen Recording** to use another Mac as a second display. On a managed Mac the switch can be greyed out, or ask for an admin password. Ferret then says **Switch greyed out? On a work Mac, your IT team decides.**

Everything else works without them.

## 📶 Office and guest Wi-Fi

Office, guest and hotel Wi-Fi often keep devices apart. Fix connection names that too. Put both on your phone's hotspot, or use Ferret at home.

## 🧾 For your IT team

Hi! This part is for whoever manages this computer. It's short and factual. Ferret is open source, so you can check every line.

### What Ferret is

A local app that connects a person's own phone and computers on the same network: clipboard, files, notifications, screen. No account, no cloud, no relay server. Devices talk directly to each other, end-to-end encrypted with Noise (`Noise_XX_25519_ChaChaPoly_SHA256`), and only after the person paired them by comparing six digits.

### Network

All inbound, on the local network only.

| Port | Protocol | What for |
|---|---|---|
| 47640 | TCP | Connections between paired devices |
| 47642–47649 | TCP | The same, for Ferret in a second account on the same computer |
| 47641 | UDP | Discovery: multicast to `239.255.70.84` and a broadcast |
| 5353 | UDP | Bonjour/mDNS, service `_ferret._tcp` |
| 53317 | TCP + UDP | Only if the person turns on LocalSend sharing (multicast `224.0.0.167`) |
| random | TCP | Only if the person turns on Quick Share sharing (mDNS `_FC9F5ED42C8A._tcp`) |

On Windows the installer adds these rules for the **Private** profile only:

| Rule name | Protocol | Local port |
|---|---|---|
| `Ferret (47640/tcp)` | TCP | 47640 |
| `Ferret other accounts (47642-47649/tcp)` | TCP | 47642-47649 |
| `Ferret discovery (47641/udp)` | UDP | 47641 |
| `Ferret mDNS (5353/udp)` | UDP | 5353 |

With **local rule merge** turned off by policy, these rules are ignored. Deploy the same rules centrally instead (Intune firewall rules or GPO), and remove any block rule for `ferret.exe` that the "allow this app?" prompt left behind. The app installs per user, in `%LOCALAPPDATA%\Programs\Ferret\ferret.exe` (or `C:\Program Files\Ferret\ferret.exe` for all users).

Ferret also works over the person's own VPN to their own devices (Tailscale, ZeroTier, WireGuard), only for a device they turned that on for. It never goes through your corporate VPN to reach anything.

### What leaves the device

| What | Where | When |
|---|---|---|
| Device name, kind, device id, port | The local network (mDNS and the discovery broadcast) | On networks where it met the person's devices before, or while they add a device. Elsewhere only an empty question |
| What features carry (clipboard, files, notifications…) | Only paired devices, encrypted | When the person uses them |
| An update check, `User-Agent: Ferret`, nothing else | `api.github.com` (HTTPS) | Once a day. Off with **Settings → About → Check for updates** |
| The update file and its `SHA256SUMS` | `github.com` and GitHub's release file host (HTTPS) | Only when the person clicks **Install** |
| Android platform tools | `dl.google.com` | Only when the person clicks **Download**, for screen mirroring with a cable |

No analytics, no crash reports, no telemetry. Ferret uses environment proxy variables (`HTTPS_PROXY`, `NO_PROXY`) but not the system proxy or PAC file yet. Behind a proxy that blocks GitHub, the check fails quietly and tries again hours later. The full list is on the [Privacy](../privacy.md) page.

### Mac

| | |
|---|---|
| Bundle id | `io.sofluffy.ferret` (Share extension: `io.sofluffy.ferret.Share`) |
| Team ID | `66UZUS2MST` (Developer ID, notarized) |
| Login item | `SMAppService.mainApp`, only when the person turns on **Start at login** |

Designated requirement (`codesign -d -r -`):

```
anchor apple generic and identifier "io.sofluffy.ferret" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "66UZUS2MST")
```

Privacy permissions Ferret asks for, each only when the person turns on the feature that needs it:

| Permission | PPPC service | Feature | What a profile can do |
|---|---|---|---|
| Accessibility | `Accessibility` | A phone moves the pointer and types | Allow |
| Input Monitoring | `ListenEvent` | Shared keyboard and mouse between computers | Let a standard user allow it (`AllowStandardUserToSetSystemService`) |
| Screen Recording | `ScreenCapture` | Using another Mac as a second display | Let a standard user allow it. Apple doesn't let a profile grant it |
| Automation | `AppleEvents` | Continue a browser page, music; restart or shut down when asked | Allow, per target app |
| Local Network | none | Everything | Nothing: Apple offers no MDM key. The person clicks **Allow** once |
| Bluetooth | `BluetoothAlways` | iPhone notifications and media over Bluetooth | Allow |

A PPPC payload (`com.apple.TCC.configuration-profile-policy`) entry for Accessibility:

```xml
<key>Accessibility</key>
<array>
  <dict>
    <key>Identifier</key>
    <string>io.sofluffy.ferret</string>
    <key>IdentifierType</key>
    <string>bundleID</string>
    <key>CodeRequirement</key>
    <string>anchor apple generic and identifier "io.sofluffy.ferret" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "66UZUS2MST")</string>
    <key>Authorization</key>
    <string>Allow</string>
  </dict>
</array>
```

For the login item, a `com.apple.servicemanagement` rule with `RuleType` `TeamIdentifier` and `RuleValue` `66UZUS2MST` keeps it allowed.

### Windows

- Installs per user with no admin rights. Only the firewall step asks for elevation.
- `ferret.exe`, `ferret-cli.exe` and the setup are signed with Authenticode when a release is built with the certificate.
- Data in `%USERPROFILE%\.sofluffy\ferret`. The device key is a file only the user can read.

### Something missing?

[Open an issue](https://github.com/simonpham/ferret/issues). I'll add it here.

## Happy Coding 🦊
