# Screen

> **TL;DR**
>
> 1. On your computer, click **Show screen** on your phone in Ferret.
> 2. On the phone, choose to share the entire screen, then **Start**.
> 3. Done? Click **Stop**. That's it.

Your phone is charging across the desk. A message comes in, or you want to show an app in a call. Picking the phone up every time gets old.

With Ferret, the phone's screen shows up on your computer. Over your own Wi-Fi, nothing else.

## 🚀 One button

**Show screen** is on every phone and tablet in Ferret, connected or not. It is all you need to know.

Ferret picks the way by itself:

1. **Ferret on the phone**, over your Wi-Fi. The phone asks you every time. You can look.
2. **A cable**, when Ferret can't reach the phone. You can look, click and type. See [Show a phone with a cable](mirroring-with-a-cable.md).
3. **An iPhone or iPad** gets three steps to do on the iPhone. See [Show an iPhone's screen](mirroring-from-iphone.md).

The name on top of the page says which one you got: **Wi-Fi**, **Cable** or **AirPlay**.

A no is a no. If someone taps Cancel on the phone, Ferret NEVER goes around it with the cable.

Phone not connected? The page says so, waits, and starts by itself the moment the phone shows up.

## ⏳ While the phone asks

The page tells you what to tap, and how long the question stays:

- "On Pixel, choose to share the entire screen, then Start."
- A clock counts down the minute you have.
- Nothing on the phone after a few seconds? Open the notice from Ferret there.

Android asks every time. Ferret can't skip it, and wouldn't.

## 🧰 The toolbar

One small toolbar sits over the bottom of the picture. Stop moving the pointer and it hides. Move, and it is back. It never hides while the pointer is on it.

| Button | Does | Keys |
|---|---|---|
| Back | The phone's Back | right-click, `⌘[`, `Esc` |
| Home | Home | middle-click, `⌘1` |
| Recents | Recent apps | `⌘2` |
| Rotate | Turns the phone's picture | `⌘R` |
| Keyboard | A field for accents, emoji, another language | `⌘K` |
| The three bars | How the picture is doing, and its presets | |
| ••• | Keep toolbar visible, Notifications panel, Volume, Power | |
| Stop | Ends it on both devices | |

On Windows and Linux the keys use `Ctrl`.

The phone's own buttons only show when you can press them, which is over a cable. Over Wi-Fi you get one chip instead: **View only**. Click it and it says why. Phone already plugged in? It offers **Control with the cable**.

Too narrow for all of it? The toolbar folds what you use least behind **•••**. In a wide window it stands beside the picture, with words.

Want it to stay? **••• → Keep toolbar visible** puts it under the picture for good.

## 🖱️ The mouse is a finger

This is for a phone on a cable:

- **Click** is a touch. **Drag** is a swipe. Click and hold is a long press.
- **Right-click** is Back. **Middle-click** is Home.
- The **wheel** scrolls. So do **two fingers on a trackpad**.
- **Typing types.** Letters go as text, so your keyboard layout holds.
- `⌘V` pastes your computer's clipboard on the phone. `⌘C`, `⌘X`, `⌘A` and `⌘Z` do on the phone what they do here.
- Accents and emoji go through the phone's clipboard. You don't have to think about it.

## 📶 Good, Slow, Poor

No row of numbers under the picture. Three bars, one word.

Click the bars for three presets:

- **Auto**: Ferret adapts.
- **Sharp**: full size.
- **Fast**: smaller, smooth.

Over a cable a change restarts the picture at once. Over Wi-Fi the phone would have to ask you again, so it applies next time.

The numbers are still there, at the bottom of that panel, for when you want them.

## 🔁 When the connection drops

Wi-Fi hiccups. Ferret keeps the last picture, dims it and says "Reconnecting to Pixel…".

Back within 20 seconds? The picture goes on, with NO new prompt. It is the same sharing you said yes to.

Longer than that, the phone stops sharing for real. The page says "Lost Pixel" and waits. When the phone is back, Ferret asks it again, once.

Pulled the cable? Plug it back in and the picture picks up by itself.

## 🛑 Stopping

**Stop** ends it on both devices. So does leaving the page: Back asks "Stop showing Pixel?" first.

Nothing shares from a page that is closed.

While a screen is shown, Activity has a pinned line, "Showing Pixel's screen", with **Stop**. Click it to get back to the picture.

Asked for a second phone while one is on screen? Ferret asks before it swaps them. Never silently.

Rotate the phone and the picture follows. Screen off? The picture dims and says so, with **Wake** when the phone is on a cable.

Want it the other way round, your phone driving the computer? That is [Control](remote-input.md).

## 🔐 You stay in charge

Nobody sees your screen without you knowing.

- **Every time**, Android asks you with its own prompt. Ferret never remembers a yes. There is no "Always".
- **While it happens**, a notice you can't swipe away says "Sharing screen with MacBook" with **Stop**. The home card says it too, and Android shows its own icon in the status bar.
- **Over a cable it is different.** A phone that allowed your computer for debugging doesn't ask each time, and shows no notice. Ferret says so the first time, right over the picture. Only do this with your own phone.
- **Afterwards**, both devices keep a line such as "MacBook saw this phone's screen for 12 min at 21:10". The last 20 are under **Screen**: in **Settings → To your computer** on the phone, in **Settings → From your phone** on the computer.
- Don't want it at all? On the phone, turn off **Let my computers ask to see this screen** in **Settings → To your computer**.
- Only one computer you'd rather keep out? On the phone, open that computer in Ferret and turn off **Ask to see this phone's screen**. It can't even ask anymore.

Phone in your pocket when the computer asks? Ferret posts a notice: "MacBook wants to see this screen". Tap it to get the prompt. The question stays for a minute.

Said no? The same computer can ask again after 30 seconds, not before.

Only devices you paired can even ask. One computer at a time.

## 🩺 When it doesn't start

The page always says why, with the button that fits:

| It says | What to do |
|---|---|
| Pixel said no | Someone tapped Cancel on the prompt. **Ask again** lights up after half a minute, with a countdown |
| Nobody answered on Pixel | Wake the phone, then **Ask again** |
| Pixel isn't connected | Open Ferret on the phone, or plug it in. It starts by itself |
| Pixel couldn't show the question | Open Ferret on the phone, or allow its notifications |
| Screen sharing is off on Pixel | On Pixel: open Ferret's settings, then Screen, and turn it on |
| Stopped on Pixel | Someone tapped Stop there. **Show again** |
| Pixel stopped sharing | Android ends sharing when the phone locks (Android 15 and later) or when you stop it from the status bar. Unlock it, then **Show again** |
| Lost Pixel | The page waits and picks up when the phone is back |

**Try again** only shows after a real failure.

## 🎞️ How the picture travels

The phone encodes its screen as H.264 video with its hardware encoder: up to 1080p, up to 60 frames per second, 2 to 8 Mbps. Ferret picks the bitrate from how the connection is doing, and drops frames instead of falling behind.

It travels inside the same encrypted connection as everything else in Ferret. No server, no cloud.

A Mac decodes it with its own hardware decoder. Windows and Linux get a JPEG picture about 10 times per second for now: slower, but it works everywhere with nothing to install.

## 🧭 Limits per platform

| Phone | Shares its screen |
|---|---|
| Android 7 and later | Yes |
| iPhone and iPad | No. iOS only lets an app record itself |

| Computer | Shows the phone | Picture |
|---|---|---|
| macOS | Yes | H.264, up to 60 fps |
| Windows | Yes | JPEG, about 10 fps |
| Linux | Yes | JPEG, about 10 fps |

- **No sound.** Only the picture is sent.
- **Protected screens stay black.** Banking apps, password fields and DRM video can tell Android to hide them from any capture. Ferret can't see them, and shouldn't.
- **One app only**: on Android 14 and later the prompt lets you share a single app instead of the whole screen. Ferret shows whatever you pick.
- **Screenshots and its own window** aren't there yet. The picture lives in Ferret's page for now.
