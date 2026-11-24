# macOS packaging

Everything that turns the Flutter release build into the DMG people download.

```sh
scripts/package_macos.sh             # build, check signatures, DMG, sign it
scripts/package_macos.sh notarize    # notarize, staple and zip the DMG built last
```

It runs on macOS only. Output lands in `build/macos-packages`.

| File | What it is |
|---|---|
| `ferret-cli.entitlements` | The one entitlement `ferret-cli` needs under the hardened runtime |
| `homebrew/ferret.rb` | Homebrew cask template |

## How Ferret ships

Straight from GitHub releases and Homebrew, not the Mac App Store: the App Store sandbox can't start `adb`. So the app is:

- **Signed** with `Developer ID Application: Cuong Pham (66UZUS2MST)`. The Release configuration in `apps/ferret/macos` already does that for the app, its frameworks and the Share extension: hardened runtime, secure timestamp, no `get-task-allow`.
- **Notarized** by Apple and **stapled**, so Gatekeeper opens it without a warning, even offline.

## What the script does

1. `fvm flutter build macos --release` (a universal app, arm64 and x86_64). `FERRET_SKIP_BUILD=1` reuses the last build.
2. Copies `ferret.app` to `build/macos-packages/stage/Ferret.app`. The folder name isn't part of the signature, so people see **Ferret** in Applications.
3. Builds `ferret-cli` with `dart compile exe`, puts it in `Ferret.app/Contents/Helpers`, signs it (identifier `io.sofluffy.ferret.cli`) and re-signs the app around it with the same entitlements.
4. Checks every signature: `codesign --verify --deep --strict`, then the app, the Share extension, `ferret-cli` and each framework one by one: team `66UZUS2MST`, Developer ID, secure timestamp, no `get-task-allow`, and the hardened runtime on everything that runs (frameworks are libraries and don't need it).
5. Makes `Ferret-<version>.dmg`: the app on the left, an **Applications** shortcut on the right, 128-point icons, Ferret's icon on the volume. Compressed with LZFSE.
6. Signs the DMG and checks the app inside it again.
7. Notarizes only when `FERRET_NOTARY_PROFILE` is set. Otherwise it prints the commands and stops.

`notarize` then submits the DMG, staples the DMG and the app, checks both with `spctl`, and zips the stapled app as `Ferret-<version>-mac.zip`. It prints the SHA-256 of both.

### The DMG window

Finder lays out the window, through AppleScript. The first time, macOS asks whether your terminal may control Finder: say **OK**. Say no and the DMG still works, with Finder's default layout.

### ferret-cli

`ferret-cli` lives inside the app, at `Ferret.app/Contents/Helpers/ferret-cli`.

- It's **Apple silicon only**. Dart can't cross-compile a macOS executable, and the build machine is arm64. The app itself stays universal.
- It needs `com.apple.security.cs.allow-unsigned-executable-memory`: a Dart executable maps its own AOT snapshot as code, and the hardened runtime kills it without that (exit 137).
- Homebrew links it onto the `PATH`. With the DMG, link it yourself:

```sh
ln -s /Applications/Ferret.app/Contents/Helpers/ferret-cli /usr/local/bin/ferret-cli
```

## 🔑 Notarization, once

Notarizing uploads the DMG to Apple. It needs an app-specific password, kept in your keychain, never in the repo.

1. Make an app-specific password at [account.apple.com](https://account.apple.com) → **Sign-In and Security** → **App-Specific Passwords**.
2. Store it as a notarytool profile:

```sh
xcrun notarytool store-credentials ferret-notary \
  --apple-id <your Apple ID email> \
  --team-id 66UZUS2MST
```

It asks for the password and saves it in the login keychain under `ferret-notary`. An App Store Connect API key works too: `--key AuthKey_XXXX.p8 --key-id <id> --issuer <issuer id>`.

3. Then, for every release:

```sh
scripts/package_macos.sh
FERRET_NOTARY_PROFILE=ferret-notary scripts/package_macos.sh notarize
```

Or both in one go: `FERRET_NOTARY_PROFILE=ferret-notary scripts/package_macos.sh`.

Notarization takes a few minutes. Rejected? `xcrun notarytool log <submission id> --keychain-profile ferret-notary` says why.

## 🍺 Homebrew

`homebrew/ferret.rb` is a cask for the DMG. To publish a version:

1. Upload `Ferret-<version>.dmg` to the GitHub release `v<version>`.
2. Fill `{{VERSION}}` and `{{SHA256_DMG}}` with the version and the SHA-256 the script printed.
3. Put it in a tap (`brew tap SoFluffyOS/ferret`, file `Casks/ferret.rb`), or open a PR to `Homebrew/homebrew-cask` once Ferret is known enough for it.

`brew install --cask ferret` installs `Ferret.app` and links `ferret-cli` on Apple silicon. `brew uninstall --zap` also removes `~/.sofluffy/ferret` and the Share extension's data.

The zip is there for a direct download and for Sparkle-style updates later. The cask uses the DMG.

## Verified

On an Apple silicon Mac, macOS 27.2, Xcode 27.2:

- The script builds, signs `ferret-cli`, passes every signature check and makes a signed DMG.
- The DMG mounts, the app inside passes `codesign --verify --deep --strict`, and `ferret-cli --help` runs from it.
- `spctl -a -vv -t install` says `Unnotarized Developer ID`, as expected before notarization.

## Not verified yet

- Notarization itself, stapling and the `spctl` checks after it: they need the owner's notary profile.
- The cask: `brew install --cask ./ferret.rb` after the first notarized release.
- The DMG on an Intel Mac.
