# Media

> **TL;DR**
>
> 1. Pair your devices.
> 2. Play something on your phone.
> 3. Control it from your laptop, or tap **Continue here** to pick it up there at the same spot.

You're listening to a podcast on your phone and sit down at your laptop. Finding the episode again and scrubbing to the right minute is a chore.

Ferret shows what plays on your other devices, lets you control it, and moves it to the device in front of you at the same position.

## 🎵 Now playing

When something plays on one of your devices, the home screen (the menubar popover on a Mac) shows a card:

- **Now playing on Pixel**, with the artwork, title, artist and the app.
- A progress line. Tap it to jump to that spot.
- ⏮ ⏯ ⏭ to go back, play or pause, and skip.

Several players at once? Pick one from the row above the card. Ferret follows the last one that started playing, so the card is usually right on its own.

Ferret sends an update only when something changes: a new track, a pause, a seek. The progress line moves on its own in between. No constant traffic, no extra battery drain.

## 🚀 Continue here

Tap **Continue here** on the card. Ferret:

1. Pauses the player on the other device.
2. Opens the same item here, at the same position.

| What plays | What opens here |
|---|---|
| A YouTube video | The video in your browser, at the same second |
| A Spotify track or episode | The Spotify app at the same position, or the Spotify web player |
| Vimeo, SoundCloud, Twitch videos | The page, at the same position |
| Another web page with media | The page, from the start |
| Spotify or YouTube without a link | A search for the title and artist |

Nothing here could open it? Ferret resumes it on the other device and tells you why. Local files and apps that share no link can't move. The **Continue here** button only shows when the item can.

## ⚙️ Settings

In **Settings → Media**:

- **Share my media**: your other devices see what plays here and can control it.
- **Show media from other devices**: the Now playing card and its controls.
- **Pause during calls**: when your phone rings, what plays on this device pauses, and only that plays again once the call ends. On by default.

## 🤖 On Android: allow Notification access

Android only shows other apps' media controls to apps with **Notification access**. It's the same toggle the Notifications feature uses, so you only allow it once.

Turn on **Share my media**, tap **Open settings**, and switch Ferret on. Back in Ferret, the setting shows a ✓ on its own, or tap **Check again**.

Ferret only reads the media controls. Nothing is logged, and it never leaves your own devices.

## 🍎 On a Mac: Music and Spotify

macOS no longer lets apps read the system's Now playing info. So on a Mac, Ferret talks to **Music** and **Spotify** directly, and only while they're open. It never opens them for you.

**Share my media** is off by default on a Mac. Turn it on and macOS asks once whether Ferret may control Music and Spotify. Said no by accident? Allow it in **System Settings → Privacy & Security → Automation**.

Other players on the Mac (browsers, VLC, …) can't be seen. You can still control everything that plays on your other devices from the Mac.

## 🧭 Limits per platform

| Platform | Shares its media | Controls others | Notes |
|---|---|---|---|
| Android | ✅ every app with media controls | ✅ | Needs Notification access |
| macOS | ✅ Music and Spotify | ✅ | Needs Automation, asked once |
| Windows | ✅ every app in the Windows media controls | ✅ | No volume control |
| Linux | ✅ every MPRIS player (most players and browsers) | ✅ | No permission needed |
| iPhone and iPad | ❌ iOS doesn't allow it | ✅ | Sees and controls your other devices |

Artwork travels only from the player's own image. Ferret never downloads cover art from the internet, so some players (Spotify on a Mac or Linux) show a music note instead.

Nothing about what you play is logged, and nothing leaves your network.

## 🛠️ For developers

Messages live in `proto/ferret/media/v1` (feature id `media`):

- `MediaState` (no reply): every player on the sender, sent on change and when a session opens. `sent_at_ms` lets the receiver map `position_at_ms` and `last_active_at_ms` onto its own clock and extrapolate the position. Artwork bytes travel once per session per `artwork_id`. An empty list means nothing plays or sharing is off.
- `MediaStateRequest` (request): answered with the current `MediaState`.
- `MediaCommand` (request): play, pause, toggle, next, previous, seek or volume for one `player_id`, answered with `MediaCommandReply`.
- `MediaContinueRequest` (request): pauses the player when `pause_source` is set and answers `MediaContinueReply` with the item and a fresh position. `paused` tells the receiver to resume the source if it can't open the item.

Receivers only open `https`, `http` and `spotify` links.
