---
order: 8
---
# Updates

A new Ferret is out. You shouldn't have to find out by visiting GitHub.

Ferret looks once a day and tells you. It installs NOTHING until you click **Install**.

> **TL;DR**
>
> 1. A card on Home says **Ferret 0.2.0 is ready**
> 2. **What's new** shows the release notes
> 3. **Install** downloads it, checks it, installs it and restarts Ferret

That's it.

## 🔄 What the check sends

Once a day (and when you click **Check now**), Ferret asks GitHub for its latest release: `api.github.com/repos/simonpham/ferret/releases/latest`.

- It sends a plain `User-Agent: Ferret` and nothing else. No device id, no name, no settings.
- GitHub sees your IP address, like any website you open.
- It's the only time Ferret talks to the internet on its own.
- While Ferret is **paused**, it doesn't check. **Check now** still works.

Don't want it? Turn off **Settings → About → Check for updates**. One switch.

## 🛡️ How it checks the download

Every release ships a `SHA256SUMS` file. Before installing, Ferret downloads it over HTTPS and compares the file's SHA-256 with it. No match, or no line for the file? Ferret says **Update not installed** and stops.

Then the system's own check:

| Where | What Ferret checks before installing |
|---|---|
| 🍎 Mac | The app is signed by Ferret's Developer ID (team `66UZUS2MST`) and notarized by Apple (`codesign`, `spctl`) |
| 🪟 Windows | The setup has a valid Authenticode signature from the same publisher as the Ferret you run |
| 🐧 Linux | The AppImage's checksum (AppImages carry no signature the system checks) |
| 🤖 Android | Android itself refuses an APK signed with another key |

A refused download is deleted. Ferret never tries it again.

## 📦 How it installs

- **Mac**: Ferret swaps the new app in place of the old one, then reopens. No admin rights for that folder (a standard account, Ferret in Applications)? Ferret opens the checked DMG instead: drag Ferret to Applications, like the first time.
- **Windows**: the setup runs silently, keeps your folder and choices, and starts Ferret again.
- **Linux AppImage** (from `install.sh`): the new AppImage replaces the old one, then Ferret restarts.
- **Linux Flatpak or .deb**: Ferret only tells you. Update it with your package manager or software center.
- **Android** (the APK from GitHub): Android asks once whether Ferret may install apps. Ferret asks right when you tap **Install**, with a line that says why. Then Android shows its own **Update** prompt.
- **iPhone**: the App Store updates Ferret. No check, no card.

## 🧪 Beta versions

Want what's next before everyone else? Turn on **Settings → About → Include beta versions**. Ferret then offers pre-releases too. They may have rough edges.

## 🛠️ Try it before a release

For testing the updater without publishing anything. Lay out a folder like a release:

```
release.json          {"tag_name": "v0.9.0", "body": "## Testing\n- Hello"}
Ferret-mac.dmg        (or Ferret-android.apk, Ferret-windows-x64-setup.exe, Ferret-linux-x86_64.AppImage)
SHA256SUMS            shasum -a 256 Ferret-mac.dmg > SHA256SUMS
```

The version must be higher than the one you run. Then start Ferret with the folder:

```sh
FERRET_UPDATE_FEED=~/ferret-feed /Applications/Ferret.app/Contents/MacOS/ferret
```

On Android, build the APK to test with a higher version (`version:` in `apps/ferret/pubspec.yaml` and `appVersion` in `lib/main.dart`; a test keeps them equal) and the same key as the installed one, copy the folder into Ferret's own storage, and point a debug build at it:

```sh
adb shell run-as io.sofluffy.ferret mkdir -p files/feed
for f in release.json Ferret-android.apk SHA256SUMS; do
  adb shell "run-as io.sofluffy.ferret sh -c 'cat > files/feed/$f'" < "$f"
done
fvm flutter run --dart-define=FERRET_UPDATE_FEED=/data/user/0/io.sofluffy.ferret/files/feed/
```

`FERRET_UPDATE_FEED` also takes an `http://` address of a folder served on your network (`python3 -m http.server`), where the system allows plain HTTP.

The feed turns on the daily check in any build. Click **Settings → About → Check now**, then **Install**. The checks stay the same: on a Mac the DMG must still hold a notarized Ferret, on Windows a setup signed like the running app.

## Happy Coding 🦊
