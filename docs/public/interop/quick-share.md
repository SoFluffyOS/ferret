# Quick Share

> **TL;DR**
>
> 1. On the computer, tap **Visible for 10 min** next to **Receive from Quick Share** on the Drop card.
> 2. On the Android phone, pick **Share → Quick Share → your computer**.
> 3. Check that both screens show the same **PIN**, then **Accept**. The files land in your receive folder. That's it.

A friend has an Android phone and three photos for you. Installing an app on their phone for that is too much.

Every Android phone already has **Quick Share** (it used to be called Nearby Share). Ferret speaks it, so the phone can send to your computer with **nothing installed** on it. No pairing, no Google account, and nothing leaves your network.

## 📥 Send from an Android phone to your computer

1. In Ferret on the computer, open the Drop card and tap **Visible for 10 min** next to **Receive from Quick Share**.
2. The card shows the name the phone will see and a countdown: **Visible as Laptop · 9:41 left**.
3. On the phone, open the photo or file, tap **Share**, then **Quick Share**.
4. Your computer shows up under the nearby devices. Tap it.
5. The phone shows a 4-digit **PIN**. Ferret comes to the front with the offer and the same PIN.
6. Same PIN on both? Tap **Accept**. You see progress, speed and time left, like any other drop.

Different PIN, or an offer you don't expect? Tap **Decline**. Nothing is saved.

You can **Cancel** at any time, also in the middle of a file. What already arrived is deleted.

### Text and links

Share a link or a piece of text the same way. It shows up on the Drop card with a **Copy** button. The text stays hidden until you accept it.

### Where the files go

In the same receive folder as every other drop, **Downloads/Ferret** unless you changed it.

Each file is written to a temporary file first. Ferret checks that every announced byte arrived, and only then moves it in place. Nothing is ever overwritten: a second `photo.jpg` becomes `photo (1).jpg`.

## 👀 Visibility

Your computer is **invisible** to Quick Share until you turn it on. While it's off, Ferret doesn't listen for Quick Share and doesn't announce anything.

- **Visible for 10 min** makes the computer show up on every phone on your network that opens Quick Share.
- After 10 minutes it hides again by itself. A transfer that is still running gets to finish first.
- **Stop** hides it right away. Offers that were waiting are declined.

There is no "always visible". Phones went the same way: "Everyone" turns itself off after 10 minutes there too.

## 🔑 The PIN

Anyone on your network can name their phone "Mum's Pixel". So the name proves nothing.

The PIN does. Both devices compute it from the encryption keys they just agreed on. When the two PINs match, the offer on your screen comes from the phone in front of you, and nobody sits in between.

That is the only check there is, so **look at it** before you accept.

## 📱 The phone doesn't show your computer

- Both devices must be on the **same Wi-Fi**. Guest networks often keep devices apart.
- The countdown must still be running. Tap **Visible for 10 min** again if it ran out.
- Turn off a **VPN** on either device. It hides the local network.
- On the phone, Quick Share itself wants **Bluetooth** and **Location** turned on before it searches. That is the phone's rule, the files still travel over Wi-Fi.
- Close the share sheet on the phone and open it again. It looks for devices when it opens.
- On Windows and Linux, allow Ferret through the firewall on **private** networks. It needs UDP port 5353 to be found.

Ferret says **Couldn't become visible** on the card when it can't announce itself at all, with **Try again** next to it.

## ⚙️ Turn it off completely

In **Settings → Drop**, turn off **Work with Quick Share**. The row disappears from the Drop card and Ferret never sends or answers a Quick Share packet.

## 🔒 Privacy

- **Nothing on a schedule.** Ferret announces itself only while the countdown runs.
- **What others see.** While visible, every device on your network can see your computer's Ferret name and that it accepts Quick Share. The rest is random and new each time: no hardware address, no computer host name, no account.
- **Local network only.** Ferret refuses every connection that doesn't come from a private network address. There is no internet fallback, no Bluetooth and no Wi-Fi Direct.
- **Encrypted.** Each transfer starts with a fresh key exchange (UKEY2 on P-256). After that, everything is AES-256 encrypted and signed, frame by frame.
- **No Google.** Ferret doesn't talk to Google and doesn't need an account. That is also why it can't tell your own phone from a stranger's: every offer asks first.
- **Not the same as pairing.** A paired Ferret device proved who it is, once, for good. A Quick Share sender proves it for one transfer, with the PIN.
- **Nothing is logged.** No file names, no text, no PINs, no device names.

## What works

| | |
|---|---|
| Show up in Quick Share on Android, Wi-Fi only | ✅ |
| Receive files, each offer asked first, with the PIN | ✅ |
| Receive text and links | ✅ |
| Several phones at once | ✅ |
| Cancel from either side | ✅ |
| Wi-Fi passwords and apps shared from the phone | No. The phone says it can't send them |
| Send from Ferret to an Android phone | No, see below |
| Bluetooth and Wi-Fi Direct | No. Same Wi-Fi only |
| Resume after a dropped connection | No. Send again from the phone |
| Your own devices without asking | No. That needs a Google account |

### Why Ferret can't send to a phone this way

An Android phone doesn't listen for Quick Share on Wi-Fi all the time. It starts when it hears a **Bluetooth** signal from a sender nearby. Ferret stays off Bluetooth, on purpose: it is a local-network app.

Two ways that do work:

- Install Ferret on the phone and [pair it](../getting-started/pairing.md). Then drops go both ways, with no questions asked.
- Use [LocalSend](localsend.md) on the phone.

## Limits per platform

- **macOS.** Allow **Local Network** access for Ferret when macOS asks. Without it the phone never sees the computer.
- **Windows and Linux.** A firewall may ask to allow Ferret, or block it silently. Allow it on **private** networks.
- **Android.** A phone already has Quick Share, so this is off there. You can turn it on in **Settings → Drop**, but treat it as an experiment: Android may keep Ferret from hearing the phones that look for it.
- **iPhone and iPad.** Not available. iOS doesn't let apps announce themselves this way.

Quick Share is Google's protocol and isn't documented. Ferret's side is written from public descriptions of it, so an Android update can break it. If your phone stops seeing Ferret, tell us which phone and which Android version.

More about files between your own devices: [Drop](../features/drop.md).
