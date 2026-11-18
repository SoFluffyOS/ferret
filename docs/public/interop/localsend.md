# LocalSend

> **TL;DR**
>
> 1. **To send:** pick **Send files…** on the Drop card. Devices running LocalSend show up next to your own, labelled **LocalSend**.
> 2. **To receive:** tap **On for 10 min** next to **Receive from LocalSend**.
> 3. Accept the offer when it shows up. The files land in your receive folder. That's it.

Your friend has an iPhone and you don't want to install another app just to get three photos. Or your second laptop only runs [LocalSend](https://localsend.org).

Ferret speaks the open [LocalSend protocol](https://github.com/localsend/protocol). No pairing, no account, and nothing leaves your network.

## 📤 Send to a LocalSend device

1. Open LocalSend on the other device. Keep it on screen.
2. In Ferret, pick **Send files…** on the Drop card.
3. Ferret looks for LocalSend devices. They appear under your own devices with a **LocalSend** label.
4. Pick one, then pick the files.
5. The other device asks to accept. Once it does, you see progress, speed and time left, like any other drop.

You can **Cancel** at any time, also while the other side is still deciding.

Files you drag onto Ferret still go straight to your own connected device. A LocalSend device is never picked without asking you first.

### The device asks for a PIN

Some people protect LocalSend with a PIN. The transfer stops with **Enter PIN**. Type the PIN shown on the other device and Ferret sends again.

### The device doesn't show up

- Both devices must be on the **same Wi-Fi**. Guest networks often keep devices apart.
- LocalSend must be **open** on the other device. On iPhone it stops listening when it goes to the background.
- Tap **Search again**. When devices can't hear each other's broadcasts, Ferret asks each address on your network instead, which takes a few seconds.
- A VPN on either device can hide the local network.

## 📥 Receive from a LocalSend device

Receiving is **off** until you turn it on. While it's off, Ferret doesn't listen for LocalSend at all.

1. On the Drop card, tap **On for 10 min** next to **Receive from LocalSend**.
2. The card shows the name the other device will see and a countdown: **Visible as Laptop · 9:41 left**.
3. On the other device, open LocalSend, pick the files and pick your device.
4. Ferret shows the offer. Check it, then **Accept** or **Decline**.

After 10 minutes Ferret stops listening by itself. A transfer that is still running gets to finish first. **Stop** ends it right away.

### From an iPhone

1. Install **LocalSend** from the App Store and open it. Allow **Local Network** access when iOS asks. Without it the iPhone can't see anything.
2. In Ferret, turn on **Receive from LocalSend**.
3. On the iPhone, tap **Send**, pick your photos or files, then tap your device under **Nearby devices**. Not listed? Tap the refresh button.
4. Accept in Ferret.

Keep LocalSend open on the iPhone until Ferret says **Saved ✓**. iOS pauses the transfer when the app goes to the background.

### What the offer shows

Every offer from LocalSend asks first. There is no auto-accept, because these devices aren't paired with you.

- The **name** the sender picked, always marked **(LocalSend)**.
- The **device model** it reports and its **address** on your network.
- Its **fingerprint**. Compare the first characters with the one in the sender's LocalSend settings if you want to be sure.
- The **files** and their **total size**.

Anyone on your network can pick any name. So accept only what you expect. Text messages stay hidden until you accept them.

### Where the files go

In the same receive folder as every other drop, **Downloads/Ferret** unless you changed it.

Each file is written to a temporary file first. Ferret checks that every byte arrived, and the SHA-256 hash when the sender gave one, and only then moves it in place. Nothing is ever overwritten: a second `photo.jpg` becomes `photo (1).jpg`.

### Keep it on

In **Settings → Drop**, turn on **Always receive from LocalSend**. Ferret then listens whenever it runs, also after a restart. Every offer still asks first.

## ⚙️ Turn it off completely

In **Settings → Drop**, turn off **Work with LocalSend**. The LocalSend row and the LocalSend devices disappear, and Ferret never sends or answers a LocalSend packet.

## 🔒 Privacy

- **Nothing on a schedule.** Ferret sends LocalSend packets in two cases only: while you look for devices to send to, and while receiving is on.
- **Looking makes you visible for a moment.** To find LocalSend devices, Ferret has to announce itself, so it can show up in their lists while you search. They can't send you anything unless receiving is on.
- **Local network only.** The receive server refuses every address that isn't on a private network.
- **Encrypted.** Transfers use HTTPS with a certificate made on your device. Its SHA-256 is your LocalSend fingerprint. When sending, Ferret checks that the device shows the same certificate it announced, and sends nothing if it doesn't.
- **Not the same as pairing.** A paired Ferret device proved who it is. A LocalSend sender only claims a name and a fingerprint. That is why every LocalSend offer asks first.
- **Nothing is logged.** No file names, no text, no fingerprints of other devices.

## What works

| | |
|---|---|
| Find devices (multicast, then asking each address) | ✅ |
| Send files, with progress and cancel | ✅ |
| Send to a PIN-protected device | ✅ |
| Receive files, each offer asked first | ✅ |
| Receive text messages | ✅ |
| HTTPS with fingerprints | ✅ |
| Devices with encryption turned off (plain HTTP) | Send only |
| Share via link (browser download) | Not yet |
| Resume after a dropped connection | No. LocalSend can't; send again |

## Limits per platform

- **Port.** LocalSend uses port 53317. When the LocalSend app runs on the same computer, Ferret takes the next free port and tells the other devices.
- **Windows and Linux.** A firewall may ask to allow Ferret, or block it silently. Allow it on **private** networks.
- **macOS.** Allow **Local Network** access for Ferret when macOS asks.
- **Android.** Receiving works while Ferret runs. Battery savers can stop it in the background.
- **iPhone.** Ferret on iOS can only receive while it's open on screen.

More about files between your own devices: [Drop](../features/drop.md).
