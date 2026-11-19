# Show an iPhone's screen on your computer

> **TL;DR**
>
> 1. On your computer, click **Show screen** on the iPhone in Ferret.
> 2. On the iPhone, open **Control Center → Screen Mirroring** and pick your computer.
> 3. Click **Show** on the computer. That's it.

[Screen](mirroring.md) over Ferret is for Android phones. An iPhone can't share its screen that way.

But an iPhone already knows how to send its screen: **AirPlay**. So Ferret on your computer answers like an AirPlay screen would. Nothing to install on the iPhone. An iPad works the same way.

> 🧪 This is experimental, and we mean it. It was built and tested without a real iPhone at hand. It may not work with yours yet. Tell us how it goes.

## 🔑 Listening for two minutes

Ferret doesn't listen for iPhones until you ask.

Click **Show screen** on a paired iPhone or iPad. Ferret shows the three steps, with the name to look for, and listens for two minutes. A clock counts them down.

Nobody picked your computer? It stops listening, and says so with **Listen again**.

Want it to listen all the time? Turn on **Show iPhone and iPad screens here** in **Settings → From your phone**, under **Screen**. Then an iPhone can start by itself, and Ferret asks you with a line under **Needs you** and a notification: **Show** or **Don't allow**.

## 📱 Start from the iPhone

1. Swipe down from the top right corner to open **Control Center**.
2. Tap **Screen Mirroring** (the two rectangles).
3. Pick your computer.

Ferret asks you on the computer first, on the same page: "Simon's iPhone is connecting", with **Show** and **Not mine**. Click **Show** and the iPhone's screen appears, right there.

It is view only, and the sound stays on the iPhone for now.

Rotate the iPhone and the picture follows. Lock it and the picture stands still until you unlock.

To stop, tap **Stop Mirroring** on the iPhone, or **Stop** in Ferret.

## 🔐 You stay in charge

AirPlay on its own lets anyone on your Wi-Fi put a picture on a screen. Ferret doesn't.

- **Off until you ask.** No **Show screen**, no switch: no listening.
- **It asks every time.** Nothing is shown before you say yes on the computer. No answer in 30 seconds counts as a no.
- **Your network only.** Devices from outside are turned away.
- The name you see is the one the iPhone gives itself. Not sure whose it is? Say no.

The picture goes from the iPhone to your computer over your own Wi-Fi. Nothing goes to the internet.

## 🍎 On a Mac

You don't need this on a Mac. macOS has its own **AirPlay Receiver** in **System Settings → General → AirDrop & Handoff**, and it does more than ours.

So on a Mac, **Show screen** on an iPhone says "Macs already do this" first. Click **Use Ferret anyway** if you want ours.

## ⚠️ It can stop working

Apple doesn't document AirPlay. Before an iPhone sends its screen, it checks the receiver with a handshake called FairPlay. The part of Ferret that answers it was worked out by the open source community, years ago.

An iOS update can change that handshake. If it does, iPhones will stop connecting to Ferret, and it stays broken until someone works it out again. We'd rather tell you now.

## 🩺 When it doesn't work

| What you see | What to do |
|---|---|
| The computer isn't in the iPhone's list | Same Wi-Fi on both? Is Ferret still listening (the clock on the page)? A guest network often hides devices from each other |
| It is in the list, but connecting fails | Did you say yes on the computer? If you did, your iOS version may not work yet |
| A firewall asks about Ferret | Allow it on private networks. The iPhone has to reach the computer |

## 🧭 Limits

| Computer | Works |
|---|---|
| Windows | Written, not tested yet |
| Linux | Written, not tested yet |
| macOS | Written, off by default. Use the Mac's own AirPlay Receiver |
| Android, iPhone | No. Showing a phone on a phone isn't offered |

- **No sound yet.** Only the picture is sent. AirPlay sound comes later.
- **View only.** You can't click or type on the iPhone from the computer. AirPlay only sends the picture.
- **Screen mirroring only.** Sending a video or a song with the AirPlay button isn't supported.
- The iPhone picks the picture quality. Ferret can't change it.

## 🙏 Thanks

This works thanks to [playfair](https://github.com/EstebanKubata/playfair), and to [RPiPlay](https://github.com/FD-/RPiPlay) and [UxPlay](https://github.com/FDH2/UxPlay), whose authors worked out how AirPlay mirroring talks. Ferret uses playfair as it is, under the GPL-3.0.
