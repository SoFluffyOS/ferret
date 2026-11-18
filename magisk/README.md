# Ferret Magisk module

> **TL;DR**
>
> 1. Build a release APK: `cd apps/ferret && fvm flutter build apk --release`
> 2. Pack the module: `magisk/build.sh apps/ferret/build/app/outputs/flutter-apk/app-release.apk`
> 3. Flash `magisk/dist/ferret-magisk-v<version>.zip` in Magisk, then restart.

> ⚠️ **Untested on real devices.** The build script runs and the zip has the right layout. Nobody has flashed it yet. A broken system app can stop a phone from booting, so flash it only on a phone you can recover.

Some Android permissions are only for apps that live on the system partition. This module puts Ferret there, as a privileged app, without touching the partition itself.

You don't need it for anything Ferret does today. Clipboard in the background works with [Shizuku](../docs/public/android-modes/shizuku.md) or plain [root](../docs/public/android-modes/root-magisk.md). The module is groundwork for later features.

## 📦 What is inside

```
template/
├── module.prop                      name and version (filled in by build.sh)
├── customize.sh                     runs at install: checks, unpacks native libraries
├── META-INF/…                       Magisk's standard installer stub
└── system/
    ├── priv-app/Ferret/Ferret.apk   your APK (copied in by build.sh)
    └── etc/permissions/
        └── privapp-permissions-io.sofluffy.ferret.xml
```

## 🔑 The permissions file

Android grants a privileged permission only when the app asks for it in its manifest **and** the system lists it for that app. This file is the list:

| Permission | For | Today |
|---|---|---|
| `CAPTURE_AUDIO_OUTPUT` | Streaming what the phone plays to another device | Planned. Ferret doesn't request it yet |
| `MODIFY_AUDIO_ROUTING` | Moving playback between devices | Planned. Ferret doesn't request it yet |
| `READ_CLIPBOARD_IN_BACKGROUND` | Clipboard without Shizuku or `su` | Signature-only on stock Android, so listing it grants nothing there |

Ferret's manifest requests none of them yet. So right now the module changes one thing: Ferret becomes a privileged app.

Adding a privileged permission to Ferret later? Add it here in the same change. On phones that enforce the list, a privileged app asking for an unlisted permission stops the boot.

## 🚀 Build it

```sh
magisk/build.sh path/to/app-release.apk
```

Options:

- `--version 0.1.0` and `--version-code 1`: read from the APK with `aapt2` when it is installed.
- `--out file.zip`: where to write the module. Default: `magisk/dist/`.

The script checks that the file is an APK with native libraries, and with `aapt2` that it really is `io.sofluffy.ferret`.

Use an APK that includes your phone's CPU type. The universal APK from `flutter build apk --release` does.

## 📲 Install it

1. Copy the zip to your phone.
2. Magisk → **Modules** → **Install from storage** → pick the zip.
3. Restart.

KernelSU and APatch install Magisk-style modules too. That path is just as untested.

Ferret already installed as a normal app? The APK in the module must be signed with the **same key**. Android ignores a system copy with another signature. If you are not sure, uninstall Ferret first. You will have to pair your devices again.

## 🧹 Remove it

Magisk → **Modules** → remove **Ferret (privileged install)** → restart. Ferret goes back to being a normal app, or is gone if it was only installed by the module.

Phone doesn't boot? Start it in safe mode. Magisk turns all modules off there.

## 🧪 What was checked

| Check | Result |
|---|---|
| `build.sh` packs a zip from a debug APK | ✅ run on macOS |
| `build.sh` refuses a file that is not an APK | ✅ |
| `customize.sh` and `update-binary` parse (`sh -n`) | ✅ |
| Installing on a device, booting, permissions granted | ❌ not tested |
| Native libraries load from `priv-app/Ferret/lib/<arch>` | ❌ not tested |
| KernelSU and APatch | ❌ not tested |
