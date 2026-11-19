# Windows packaging

Everything that turns the Flutter release bundle into something people install.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\package_windows.ps1          # Inno Setup installer
powershell -ExecutionPolicy Bypass -File scripts\package_windows.ps1 msix     # or: all
```

It runs on Windows only. Output lands in `build\windows-packages`.

| File | What it is |
|---|---|
| `ferret.iss` | Inno Setup 6 script: the installer we ship |
| `wizard-*.bmp` | The installer's pictures, rendered from `branding/` by `scripts/generate_icons.sh` |
| `msix/AppxManifest.xml`, `msix/Assets/` | MSIX manifest and tile images (rendered by `scripts/generate_icons.sh`), for the Microsoft Store or a signed sideload |
| `winget/` | winget manifest templates (version, installer, en-US locale) |

## Why Inno Setup first

Ferret ships from GitHub releases and winget. For that, a classic per-user installer is the robust choice:

- **No signing certificate needed to install.** An unsigned `.exe` gets a SmartScreen warning, but it installs. An unsigned `.msix` doesn't install at all outside developer mode, and a trusted code-signing certificate costs money every year.
- **winget takes it as is.** `InstallerType: inno`, `Scope: user`, silent switches built in.
- **No admin by default.** It installs to `%LOCALAPPDATA%\Programs\Ferret`. "Install for all users" is still there and asks for admin.
- **The firewall task can elevate on its own.** MSIX can declare firewall rules, but it can't run anything elevated, and its rules can't be checked by name from the app.
- **Start at login stays one Run value**, the same as a portable build. No registry virtualization to work around.

MSIX stays as a second path for the Microsoft Store, where Microsoft signs the package. The manifest is ready, and the script packs and signs it when you give it a certificate.

## What the installer does

- Installs `ferret.exe`, the Flutter bundle, `ferret-cli.exe` and the MSVC runtime DLLs (app-local, so no VC++ redistributable).
- **Start menu** shortcut, with the AppUserModelID `io.sofluffy.ferret` that notifications use.
- **Send to → Ferret** (task, on by default): a shortcut to `ferret.exe send` in the user's Send to folder. See [Share menu](../../docs/public/features/share-menu.md).
- **Allow Ferret through Windows Firewall** (task, on by default): one UAC prompt, then four inbound rules on **Private** networks only.

| Rule name | Port | Why |
|---|---|---|
| `Ferret (47640/tcp)` | 47640/tcp | Connections between your devices |
| `Ferret other accounts (47642-47649/tcp)` | 47642–47649/tcp | Ferret in a second account on the same PC |
| `Ferret discovery (47641/udp)` | 47641/udp | Finding your devices |
| `Ferret mDNS (5353/udp)` | 5353/udp | Finding devices with mDNS |

Say No to the prompt and the installer finishes anyway. Ferret's **Fix connection** notices the rules are missing and offers **Allow through firewall**, which adds the exact same rules (`WindowsFirewallRules` in `packages/ferret_system`). A test there checks that `ferret.iss` and the app stay in step.

The rules are scoped to Private on purpose. A café or a Wi-Fi Windows marked Public stays closed, and Fix connection tells you to switch your home network to Private.

### Uninstall

The uninstaller removes the program, the shortcuts, the firewall rules (whoever added them; one UAC prompt, only when they exist), the Start at login Run value, the window's saved place and the notification registration.

It keeps `%USERPROFILE%\.sofluffy\ferret`: your keys, paired devices and settings. Reinstall and your devices are still paired.

### winget

`winget install` runs the installer silently with `/TASKS="sendto"`, so no UAC prompt pops up in the middle of it. Fix connection offers the firewall rules on first need. To get them at install time:

```powershell
winget install SoFluffy.Ferret --override '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /TASKS="sendto,firewall"'
```

To publish a version: build, take the SHA256 the script prints, fill `{{VERSION}}`, `{{RELEASE_DATE}}` and `{{SHA256_X64}}` in `winget/`, and open a PR to `microsoft/winget-pkgs` under `manifests/s/SoFluffy/Ferret/<version>/` (or run `wingetcreate update SoFluffy.Ferret`).

## MSIX notes

- `Publisher` must match the signing certificate's subject. Set `FERRET_MSIX_PUBLISHER`, `FERRET_MSIX_CERT` (a `.pfx`) and `FERRET_MSIX_CERT_PASSWORD`. For the Store, use the publisher Partner Center gives you and let the Store sign it.
- **Capabilities:** `internetClient`, `privateNetworkClientServer`, `runFullTrust`, and `unvirtualizedResources` with `RegistryWriteVirtualization` off, so the Run key and the window's saved place land in the real registry. The Store asks for a reason for `unvirtualizedResources`: "Start at login writes the user's Run key".
- **Start at login:** the install folder is versioned and moves on every update, so the app writes the `ferret.exe` app execution alias (`%LOCALAPPDATA%\Microsoft\WindowsApps\ferret.exe`) into the Run key instead of its own path. That's why there's no `StartupTask` in the manifest: one switch, one mechanism, the same as the Inno install.
- **Firewall:** declared with `windows.firewallRules` (the same three ports, Private only). Windows names those rules itself, so Fix connection can't find them by name and may still offer **Allow through firewall**. Pressing it adds the named rules too; harmless, but worth fixing if MSIX becomes the main path.
- **Aliases:** `ferret.exe` and `ferret-cli.exe` are on the `PATH` through app execution aliases.

## Not verified yet

Nothing here was built or run on Windows: the script, the `.iss` and the manifest were written and reviewed on a Mac (the manifest is checked for well-formed XML only). First run on a Windows machine:

1. `scripts\package_windows.ps1 all` builds both, and `ISCC` compiles `ferret.iss` without warnings.
2. Install per user, no UAC until the firewall task, then `netsh advfirewall firewall show rule name=all | findstr Ferret` lists three rules with Profile `Private`.
3. Say No to the UAC prompt: the installer says so and finishes; Fix connection offers **Allow through firewall** and it works.
4. **Send to → Ferret** sends a file; Start at login survives an upgrade.
5. Uninstall removes the rules, the Run value and the shortcuts, and keeps `~\.sofluffy\ferret`.
6. `makeappx` accepts the manifest; the signed `.msix` installs, its aliases work, and Start at login survives a version bump.
