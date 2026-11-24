# ferret_updates

Finds a newer Ferret in its GitHub releases, downloads it, checks it and installs it. Part of [Ferret](../../README.md), usable on its own.

```dart
final release = await GithubReleaseSource().newest(includePreReleases: false);
final asset = UpdateTarget.current?.assetIn(release!);
```

| Step | How |
|---|---|
| Find | `GET api.github.com/repos/SoFluffyOS/ferret/releases/latest` with `User-Agent: Ferret`, nothing else |
| Pick | The stable file name for this system: `Ferret-mac.dmg`, `Ferret-windows-<arch>-setup.exe`, `Ferret-linux-<arch>.AppImage`, `Ferret-android.apk` |
| Check | The file's SHA-256 against the release's `SHA256SUMS` |
| macOS | `codesign --verify --deep --strict`, team `66UZUS2MST`, `spctl` says notarized; swap by rename, reopen |
| Windows | `Get-AuthenticodeSignature` valid and the same publisher as the running app; Inno Setup `/VERYSILENT`, reopen |
| Linux | AppImage only: renamed over `$APPIMAGE`, reopen. Flatpak, Snap and .deb are left to the package manager |
| Android | PackageInstaller session; Android checks the signing key and asks the person |

`FERRET_UPDATE_FEED` (an environment variable, or `--dart-define`) points it at a folder or a local web server holding `release.json` and the files, to try an update before one is published.
