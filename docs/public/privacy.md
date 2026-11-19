# Privacy

Ferret is built so your stuff never leaves your devices. That is the whole point.

## 🔒 What Ferret does

- Your devices talk **directly to each other on your network**. Nothing goes through a server.
- Every connection is **end-to-end encrypted** with the [Noise protocol](https://noiseprotocol.org) (`Noise_XX_25519_ChaChaPoly_SHA256`).
- A device can only connect after you **paired** it, by comparing six digits or scanning a code. Strangers on the same Wi-Fi can't read or send anything.
- Devices you paired tell each other about your other devices, so you pair once. Only a device you already paired can add one, and you can turn this off under **Settings → Advanced**.
- To find each other, your devices announce their name and kind on your Wi-Fi. Nothing else, and never outside your network.
- Each device has its own key, kept in the system keychain on phones and in a file only you can read on computers.

## 🙅 What Ferret never does

- No account. No sign-in. No email.
- No cloud, no relay, no "fallback over the internet".
- No analytics, no crash reporting service, no ads, no tracking of any kind.
- It never logs what you copy, the files you send, your messages or your notifications.

## 🛂 You stay in control

- **Pause** Ferret any time, for an hour or until you resume.
- **Unpair** a device in one click; both sides forget each other.
- Every feature is a switch in Settings, and sensitive ones (notifications, messages, calls) stay off until you turn them on.
- Ferret asks for each system permission when you turn on the feature that needs it, after a line that says why. Never at first launch.

## 👀 What each device can use

Open a device and tap **What Pixel 7 can use**. You see every feature that device can reach on this one, with a switch each:

| Feature | What it carries |
|---|---|
| Clipboard | What you copy, both ways |
| Files | Files and links you send, both ways |
| Notifications | A phone's notifications, and your replies |
| Messages | A phone's texts and contacts' names, and texts you send from a computer |
| Calls | Who is calling, recent calls, answering and placing calls |
| Continue | The page or thing you were on |
| Media | What's playing, and play, pause and skip |
| Screen | Showing a phone's screen, each time only after it says yes |
| Control | Moving the pointer and typing, only after you allow it |
| Find | Ringing a device to find it |
| Wake-on-LAN | A computer's network card (MAC) addresses, and asking a computer to wake another |

Turn one off and it stops RIGHT AWAY, on both devices: Ferret reconnects, the other device no longer sees the feature, and anything it still sends for it is refused. **Turn everything off** does all of them in one tap and keeps the device paired. To stop it connecting at all, forget it.

## 🙈 On a computer you share

Notifications, texts, callers and copied text from a phone hide while the screen is locked or another account is in front. **Show previews on this computer**, at the bottom of **What Pixel 7 can use**, covers them all the time; it starts off on a computer where other accounts run Ferret. See [A computer the family shares](getting-started/shared-computer.md).

## 🔑 Passwords and codes

- **Passwords you copy** stay here. Password managers mark them as private (`org.nspasteboard.ConcealedType` on a Mac, "sensitive" on Android 13 and later, the KeePassXC and KDE hints on Linux), and Ferret skips them unless you turn on **Include passwords**. See [Clipboard](features/clipboard.md).
- **One-time codes** in your phone's notifications stay on the phone. Your computer shows **Code hidden**. See [Notifications](features/notifications.md).

## 🟢 You see it while it happens

- While another device **sees your screen**, your phone shows Android's own recording icon and Ferret's "Sharing screen with…" notification with **Stop**.
- While a phone **controls your computer**, Ferret shows "Pixel 7 is controlling this computer" until it stops.
- On a Mac, the menubar icon keeps a dot for as long as either lasts, and its tooltip says who.

## 📡 What leaves this device

Checked against the code, line by line:

| What | Where it goes | When |
|---|---|---|
| Your device's name and kind | Your Wi-Fi only (mDNS and a broadcast), so your devices find each other | While Ferret runs and isn't paused |
| What your features carry (table above) | Only to devices you paired, end-to-end encrypted | When you use the feature |
| Whether someone is at this device, and its battery level and charging | Only to devices you paired, end-to-end encrypted | When it changes: the battery in 5% steps, each percent below 20% |
| A computer's network card (MAC) addresses and network, so your devices can wake it | Only to devices you paired, end-to-end encrypted. Turn it off with **Let my devices wake this computer** | When a device connects, and when the cards change |
| A Wake-on-LAN magic packet (only the MAC address, repeated) | Your network, as a broadcast and to the computer's last address | Only when you tap **Wake**, or a phone of yours asks this computer to |
| Files and links | Phones you share with through Quick Share or LocalSend, on your Wi-Fi | Only when you turn that on in Drop |
| A download of Android's platform tools | `dl.google.com` | Only when you click **Download**, for [mirroring with a cable](features/mirroring-with-a-cable.md) |

That's the whole list. Links you tap (like the Shizuku download page) open in your browser, not in Ferret. No update checks, no crash reports, no fonts or images from the internet.

## 🗂️ Where Ferret keeps its data

On a computer, everything Ferret saves sits in **one folder**: `~/.sofluffy/ferret` (`%USERPROFILE%\.sofluffy\ferret` on Windows).

| Folder | What's in it |
|---|---|
| `settings` | Your settings |
| `secrets` | This device's key and your paired devices, readable only by you |
| `features` | What features save, such as your saved texts |
| `tools` | Android's platform tools, if you downloaded them |
| `cache` | Things Ferret can rebuild |
| `cli` | The `ferret-cli` command line's own key, pairings and settings |

On phones, Ferret keeps its data in its own app storage, and its key in the system keychain.

## ⏳ How long Ferret keeps things

| What | Kept |
|---|---|
| Clipboard history | In memory only, the last 20. Gone when Ferret quits. Passwords you chose to sync: 2 minutes |
| Notifications from a phone | In memory only. **Clear all** empties the list |
| A phone's texts, on a computer | Saved in `features/messages` so they show offline. **Forget saved texts** in Settings deletes them, and unpairing the phone does too |
| What you continued between devices | The last 50, never older than 30 days. **Clear** in Settings → Continue & media |
| Times a phone controlled this computer | The last few, with **Clear history** in Settings → Control |

Ferret writes no log file. Release builds print only short status lines to the system log (Console on a Mac, logcat on Android), never what you copy, send, read or type.

## 🧹 Removing Ferret

1. **Unpair** this computer on your other devices.
2. Quit Ferret and delete the app.
3. Delete `~/.sofluffy/ferret`. That's it, nothing is left behind.

On a phone, uninstalling the app removes everything.

## 🔓 Check it yourself

Ferret is open source. The apps are GPL-3.0 and the protocol is MIT, documented in the [protocol reference](spec/reference.md).
