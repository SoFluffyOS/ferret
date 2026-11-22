# Changelog

## [Unreleased]

The first release. Your phone and your computers, working as one: on the Wi-Fi you already have, with no account and no cloud.

Things marked *Beta* work in my tests but haven't met enough real devices yet. Tried one? [Tell me how it went](https://github.com/simonpham/ferret/issues).

### Added

#### 🔑 Pair and stay connected
- **Pairing**: tap **Pair** next to a device near you and check that both screens show the same six digits. Or scan a QR code, from Ferret or the phone's own camera. No account, ever.
- **Pair once, join them all**: a device you pair with one of yours joins all of them, once each asks you. **Forget** removes it everywhere (each one asks too), or only here.
- **Flaky Wi-Fi, handled**: a device that drops says **Reconnecting…** instead of offline, and comes back right after sleep or a network change. A slow link says **weak connection**.
- **Easy on your phone's battery**: once all your devices are connected, Android stops waking Ferret for every announce on the Wi-Fi. It listens again the moment one drops or you open Nearby.
- **Fix connection**: says in plain words why a device won't connect, with the fix. Firewalls on Windows and Linux, café Wi-Fi that keeps devices apart, your phone's hotspot, mobile data.
- **Work laptops**: Fix connection says when a work VPN carries everything, even traffic to your phone, and when the firewall needs an administrator. A [page for your IT team](docs/getting-started/work-computer.md) lists ports, what leaves the device and the Mac permissions.
- **Easy to read for anyone**: plain words, calm colors and short buttons that still fit at 200% text. **Copy details for a helper** puts a short report on the clipboard for whoever helps you.
- **Away from home**: already on Tailscale, ZeroTier or WireGuard? Ferret reaches your devices through your own VPN, and moves back to the Wi-Fi at home. No Ferret server. The page says how much went over it, since that's your mobile data.
- **On the road**: your laptop on your phone's hotspot finds the phone right away, even on a hotspot it never joined before. On café or hotel Wi-Fi that keeps devices apart, the device's page says so and points to the hotspot.
- **New phone?** Pair it and Home asks **Is this your new Pixel 7?** One tap and it takes the old one's name, pin and settings.
- **New computer?** Migration Assistant or a restored backup brings Ferret along, and it starts there as a new device with a list of what to pair again. Two computers never answer as one.
- **Forget means forget**: a removed device loses its "Always allow" answers, and its notifications and clips leave this one.
- **Says who needs an update** instead of staying offline.
- **A calm first two minutes**: right after pairing, Home shows your device and one thing to try. The extras wait until something went through.
- **Your iPhone under Nearby**: with Ferret open, an iPhone shows up on your computer, and your computer on the iPhone. Tap **Pair**, no QR code needed.
- **iPhone asks about the local network when it makes sense**: a short card says why before iOS asks, not at first launch. Said no? Nearby and Fix connection take you to Settings.
- **What a device can use** lists only what does something between the two. No calls or texts rows for an iPhone.

#### 📋 Clipboard
- **Clipboard sync**: copy on one device, paste on another. Text, links and images. Password-manager items stay put.
- **Recent clips**: the last 20 things you copied, on any device. **⌃⌥V** opens them from any app on a Mac.
- Copied with no device around? It goes as soon as the device is back.

#### 📦 Files and folders
- **Drop**: drag files or a whole folder onto a device. Checked with SHA-256, never overwrites, and a transfer cut off by the Wi-Fi goes on by itself when the device is back.
- **Fast**: a folder of small files streams without waiting on each file, and big files go at full speed, encrypted. Sharing a big file from Android starts at once, with no copy and no extra space needed. Files sent to Android land straight in Download.
- **Room first**: a file that doesn't fit is turned down before a byte moves, with how much space it needs.
- **Share menus**: **Share → Ferret** on Mac and iPhone, **Send with Ferret** on Windows and Linux. On Android, your connected devices sit right in the share sheet's top row.
- **Needs you**: files from a device you didn't pair wait for **Accept**. **Allow once** lets a guest's phone send you one file.
- **LocalSend and Quick Share**: send to LocalSend, and receive from both. Android phones send to your computer with nothing installed.

#### 📥 Shelf (Mac)
- **Shelf**: a box at the bottom of the popover to put things down for a moment. Drop files, photos, text or links on it, and drag them back out into any app or onto a device. Mid-drag, rest on the menubar icon or shake the pointer and it comes to you. It never leaves your Mac. See [Shelf](docs/features/shelf.md).
- **Keep copies**: turn it on and what you copy lands on the shelf too, until you quit or for a day or a week.
- **Drag photos and clips out**: a phone photo or a Recent clip drags straight into Mail, Finder or any app.
- **Drop on the icon**: files dropped on the menubar icon go to your last device, with 3 seconds to **Undo**.

#### 🔔 From your Android phone
- **Notifications** on your computer, with **Reply** and **Dismiss** synced both ways. One-time codes stay on the phone as **Code hidden**. A busy group chat can't flood your screen: past 3 popups a minute per app, the rest wait quietly in Ferret, where you can reply too.
- **Messages**: read and reply to your texts, with names, photos and pictures.
- **Search your texts**: names, numbers and words, accents or not ("nguyen" finds "Nguyễn").
- **Copy code**: a text with a sign-in code puts just the digits on your clipboard.
- **One notification per text**, even when Google Messages' own notification is mirrored too. Same for a missed call.
- **Call back** from a missed call: your phone dials. Two SIMs? Replies leave from the SIM the conversation used.
- **Calls**: see who's calling, then answer, decline, silence or hang up. Your music pauses while you talk.
- **Private previews**: texts, callers and copied text hide while the computer is locked or someone else's account is in front.

#### 🪞 Screen, photos and camera
- **Show screen**: your phone's screen on your computer, over Wi-Fi (*Beta*) or a cable with no Ferret on the phone (*Beta*). Click, scroll and type on it, with its sound too (*Beta*). On a Mac it gets its own phone-shaped window.
- **Control over Wi-Fi** (*Beta*): click and type on the phone with no cable. The phone asks first and says who's in control the whole time.
- **iPhone and iPad through AirPlay** (*Beta*).
- **Photos**: browse your phone's recent photos and screenshots from the computer, and save the ones you want. New screenshots can land by themselves.
- **Take a photo**: press **⌃⌘P**, shoot on the phone, and it's on your computer's clipboard. On iPhone, **Scan a document** too.
- **Your phone's camera in a window** (*Beta*): **Use camera** on your Android phone's page shows its camera and microphone on your computer, over Wi-Fi.

#### 🖥️ A second display (*Beta*)
- **Another Mac as a display**: click **Use as display** on your other Mac, **Allow** there, and it's a real extra display. Its mouse and keyboard work on it. See [A second display](docs/features/second-display.md).
- **An Android tablet or phone as a display**: same button. Tap to click, drag, hold to right-click, two fingers to scroll.
- **One keyboard and mouse**: press **⌃⌥→** and your Mac's keyboard and mouse work on the computer next to it. **⌃⌥⎋** brings them back, every time. See [Control](docs/features/remote-input.md).

#### 🔍 Find, wake and control
- **Ring** a lost phone or computer, even on silent.
- **Wake** a sleeping computer with Wake-on-LAN.
- **Your phone as a touchpad and keyboard**, or as a **presentation clicker**.
- **Computer actions**: **Sleep**, **Restart…**, **Shut down…**, **Lock**, the volume, or your own commands, from your phone. The computer asks first, once.
- **Lock when your phone leaves**: walk away with your Android phone and your computer locks itself after a 10-second **Cancel**.
- **Media**: see what plays on your other devices, control it, and **Continue here** at the same second.
- **Continue on…**: send a page to another device, or from the browser extension.
- **Battery**: every device's battery, and one heads-up when it's low.

#### 🤖 Scripting
- **`ferret-cli`**: `send`, `devices`, `ring`, `clipboard`, `open`, `notify`, `wake`, `action` and `camera`, with tab completion for bash, zsh and fish.
- **`ferret-cli watch --json`** streams what happens to your own scripts, and **hooks** in `~/.sofluffy/ferret/hooks` run on each event. See [Scripting](docs/features/scripting.md).
- **Tasker** plugin on Android, **Shortcuts** actions on iPhone.

#### 💻 At home on every platform
- 🍏 **Mac**: a menubar app with a popover and a full window, **⌃⌥Space** from any app, a real menu bar with keys, and start at login.
- 🤖 **Android**: a quiet background service and a Quick Settings tile. **Stay connected** says when Android limits Ferret and how to fix it. Swipe Ferret's notice away and it stays away. Ready for Android 17's local network permission.
- 🍎 **iPhone**: the share sheet, Shortcuts, a tip for the Allow Paste question, and files from LocalSend while Ferret is open. A Windows or Linux computer shows an iPhone's notifications over Bluetooth.
- 🪟 **Windows**: an installer just for you, no admin, a tray icon, and one box for the firewall.
- 🐧 **Linux**: Flatpak, AppImage and `.deb`, a tray icon, and the one line your firewall needs.
- 👪 **A computer the family shares**: one Ferret per account, each under its own name.

#### 💎 Easy to use, for everyone
- **Your devices are the home screen**, with **Send files**, **Send clipboard** and **Ring** on each row. **Activity** says what just happened.
- **Do more, once**: the extras card on Home goes away with its ✕ and stays in **Settings → Do more**. It only comes back when something new is on offer.
- **Short buttons**: the whole sentence is in the tooltip and what screen readers say.
- **Large text**: up to 200%, and pages grow with it.
- **Accessibility**: VoiceOver and TalkBack (headings to jump between sections, one stop per device or row, a device that connects or drops is spoken), a keyboard alone, and readable contrast in light and dark.
- **Ferret in Vietnamese**, and ready for every language, right-to-left included. [Translate Ferret](docs/contributing/translating.md).
- **Beta tags** on what hasn't met enough real devices yet.

#### 🔒 Privacy and security
- **Updates, when you say so**: once a day Ferret asks GitHub whether a new version is out (one switch in About turns it off). **Install** downloads it, checks it against the release's checksums and its signature, and restarts. Mac, Windows, the Linux AppImage and the Android APK.
- **Local network only**: your devices talk directly, end-to-end encrypted with Noise. Nothing goes through a server.
- **Strangers can only ask to pair**, in short messages and a few at a time. Say no and they wait before they can ask again.
- **What a device can use**: a switch per feature on each device. **Turn everything off** keeps it paired.
- **Watched? You know**: the menubar icon keeps a dot while a device sees your screen or controls your Mac.
- **No hiding in file names**: received names lose the marks that flip text direction.
- **Logs stay clean**: never a path, link or text you copied.
- **Quiet on strange Wi-Fi**: your devices announce themselves only where they met each other before, or while you add a device. Elsewhere they just listen, so nobody at the café can tell it's the same laptop as yesterday. **Always visible** in Advanced makes them announce everywhere.
- **Your Mac's key in the keychain**, where other apps can't copy it from a file.
- **Privacy** and **Security** pages: every byte that leaves a device, and what Ferret protects you from.

#### ❤️ Sponsor
- Ferret is free and always will be. **Settings → About → Sponsor Ferret** opens my GitHub Sponsors page on Mac, Windows, Linux and Android. Never a popup, never a reminder.
