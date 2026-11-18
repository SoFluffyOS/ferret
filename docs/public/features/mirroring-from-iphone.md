# Show an iPhone's screen on your computer

> **TL;DR**
>
> 1. On your computer, click **Turn on** next to Screen in **Do more** on Ferret's home screen.
> 2. On the iPhone, open **Control Center → Screen Mirroring** and pick your computer.
> 3. Say yes on the computer. That's it.

[Screen mirroring](mirroring.md) is for Android phones, with Ferret on both devices. An iPhone can't do that.

But an iPhone already knows how to send its screen: **AirPlay**. So Ferret on your computer answers like an AirPlay screen would. Nothing to install on the iPhone. An iPad works the same way.

> 🧪 This is experimental, and we mean it. It was built and tested without a real iPhone at hand. It may not work with yours yet. Tell us how it goes.

## 🔑 Turn it on

Ferret doesn't listen for iPhones until you ask.

1. On the computer, find **Screen** in **Do more** on Ferret's home screen.
2. Click **Turn on**.

Your computer now shows up on iPhones on the same Wi-Fi, under its Ferret name. Turn off **More ways to show a screen** in **Settings → From your phone** and it is gone from their lists.

## 📱 Start from the iPhone

1. Swipe down from the top right corner to open **Control Center**.
2. Tap **Screen Mirroring** (the two rectangles).
3. Pick your computer.

Ferret asks you on the computer first. Say yes, and the iPhone's screen appears.

Rotate the iPhone and the picture follows. Lock it and the picture stands still until you unlock.

To stop, tap **Stop Mirroring** on the iPhone, or **Stop** in Ferret.

## 🔐 You stay in charge

AirPlay on its own lets anyone on your Wi-Fi put a picture on a screen. Ferret doesn't.

- **Off until you turn it on.** No switch, no listening.
- **It asks every time.** Nothing is shown before you say yes on the computer. No answer in 30 seconds counts as a no.
- **Your network only.** Devices from outside are turned away.
- The name you see is the one the iPhone gives itself. Not sure whose it is? Say no.

The picture goes from the iPhone to your computer over your own Wi-Fi. Nothing goes to the internet.

## 🍎 On a Mac

You don't need this on a Mac. macOS has its own **AirPlay Receiver** in **System Settings → General → AirDrop & Handoff**, and it does more than ours.

So on a Mac, Ferret leaves this off unless you turn it on.

## ⚠️ It can stop working

Apple doesn't document AirPlay. Before an iPhone sends its screen, it checks the receiver with a handshake called FairPlay. The part of Ferret that answers it was worked out by the open source community, years ago.

An iOS update can change that handshake. If it does, iPhones will stop connecting to Ferret, and it stays broken until someone works it out again. We'd rather tell you now.

## 🩺 When it doesn't work

| What you see | What to do |
|---|---|
| The computer isn't in the iPhone's list | Same Wi-Fi on both? Is **More ways to show a screen** on? A guest network often hides devices from each other |
| It is in the list, but connecting fails | Did you say yes on the computer? If you did, your iOS version may not work yet |
| A firewall asks about Ferret | Allow it on private networks. The iPhone has to reach the computer |

## 🧭 Limits

| Computer | Works |
|---|---|
| Windows | Written, not tested yet |
| Linux | Written, not tested yet |
| macOS | Written, off by default. Use the Mac's own AirPlay Receiver |
| Android, iPhone | No. Showing a phone on a phone isn't offered |

- **No sound.** Only the picture is sent.
- **View only.** You can't click or type on the iPhone from the computer. AirPlay only sends the picture.
- **Screen mirroring only.** Sending a video or a song with the AirPlay button isn't supported.
- The iPhone picks the picture quality. Ferret can't change it.

## 🙏 Thanks

This works thanks to [playfair](https://github.com/EstebanKubata/playfair), and to [RPiPlay](https://github.com/FD-/RPiPlay) and [UxPlay](https://github.com/FDH2/UxPlay), whose authors worked out how AirPlay mirroring talks. Ferret uses playfair as it is, under the GPL-3.0.
