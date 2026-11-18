# Find

> **TL;DR**
>
> 1. Open the device you lost in Ferret.
> 2. Tap **Ring**.
> 3. Follow the sound, then tap **Found it**. That's it.

Your phone is somewhere in the couch. On silent. Calling it does nothing.

With Ferret, any of your devices can make another one ring. Out loud, even on silent.

## 🔔 How it works

- Open the device in Ferret and tap **Ring**.
- It plays a loud alarm for up to 2 minutes. Phones vibrate too, and Android flashes the torch.
- A page shows "Ringing Pixel…" with **Stop**. It stays on top of **Activity** too.
- Found it? Tap the big **Found it** on the ringing device. On Android, a volume key works as well.

Your other device hears how it ended: "Pixel was found", "stopped ringing on its own", or why it didn't ring at all.

Nobody else can ring your devices. Only devices you paired.

## 🤖 On Android: ring on silent

Ferret rings on the alarm volume, at full volume, and puts your volume back afterwards. That already works on silent and vibrate.

**Do Not Disturb** needs your permission:

1. Go to **Settings → Control** in Ferret. Find has its own part there.
2. Tap **Allow in Settings**.
3. Find Ferret in the list and turn it on. Come back to Ferret.

Ferret checks again when you come back. Your other devices show it too: Pixel's page says "Do Not Disturb keeps Pixel quiet" until you allow it.

On Android 14 and later, also allow **full-screen notifications** when Ferret asks. That puts the ringing screen with **Found it** over the lock screen.

## 💻 On a computer

- **Mac**: turns the volume up and unmutes while ringing, then puts it back. Plays a system sound and bounces the Dock icon. A notice and the menubar card have **Found it**.
- **Windows and Linux**: plays a short tone at the current volume, with a **Found it** notice. Keep the sound on. Linux needs `pw-play`, `paplay` or `aplay`, which almost every desktop has.

## ⚙️ Settings

In **Settings → Control**, under **Find**:

- **Ring on silent**: full volume, even on silent or Do Not Disturb. On by default. Turn it off and a silent phone only vibrates.
- **Flash the torch**: blink the flashlight while ringing, to spot it in the dark. Phones with a torch only.
- **Test ring**: ring this device for 5 seconds.

## 🧭 Limits per platform

| Platform | Rings in the background | Through silent | Volume put back | Found it |
|---|---|---|---|---|
| Android | Yes | Yes, Do Not Disturb with permission | Yes | Notification, lock screen, volume key |
| iPhone and iPad | Only while Ferret is open | Yes | Volume is never changed | Ringing screen |
| macOS | Yes | Unmutes | Yes | Notice, menubar card |
| Windows | Yes | No, current volume | Volume is never changed | Notice |
| Linux | Yes | No, current volume | Volume is never changed | Notice |

iOS stops apps soon after they leave the screen, so an iPhone rings only while Ferret is open on it. That is an iOS rule, not a Ferret choice.

A device that is off or out of Wi-Fi can't ring. Ferret says so: "Pixel didn't answer."
