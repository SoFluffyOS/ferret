# CLAUDE.md

Guidance for Claude Code and other agents working in this repository. Follow [CONVENTIONS.md](CONVENTIONS.md) for every change.

## Project

**F.E.R.R.E.T.** (Fast Encrypted Relay for Resuming Every Task) lets you continue what you were doing on another of your devices: web pages, media, clipboard, files, notifications, messages and calls, between Android, iOS, macOS, Linux and Windows. It works on the local network, with no account and **no telemetry**. Licensed GPL-3.0; the protocol spec (`docs/public/spec`, `proto/`) is MIT.

## Commands

```bash
scripts/get.sh                 # pub get for the whole workspace
scripts/gen.sh                 # proto/ -> packages/protocol (buf lint + generate + barrels)
scripts/check.sh [path]        # format, analyze, test (one package or all)
cd apps/ferret && fvm flutter test test/screens   # renders every main screen to temp/screens (light/dark, phone/popover) for review
scripts/docs.sh serve|check|reference|build   # docs site; reference regenerates the protocol page from proto/

cd apps/ferret && flutter run -d macos     # or an emulator: never the user's own phone
cd apps/ferret_cli && dart run bin/ferret.dart --help
```

Flutter comes from fvm (`.fvmrc`, stable channel): prefix commands with `fvm` (`fvm flutter test`, `fvm dart analyze`).

## Layout

| Directory | Purpose |
|---|---|
| `apps/ferret/` | The Flutter app for every platform: `main.dart`, wiring, platform folders. Entry point only |
| `apps/ferret_cli/` | `ferret` command line and headless daemon (pure Dart) |
| `apps/ferret_docs/` | Docs site (Jaspr, pinned to its own Flutter in `.fvmrc`). Reads `docs/public` in place, builds the sidebar from its folders; holds layout, components and the docs tools only |
| `modules/<feature>/` | One feature each: its `Feature` (engine side) and its UI. Features never import each other |
| `modules/shell/` | App shell: onboarding, devices, pairing, settings, tier detection; hosts feature UIs |
| `packages/core/` | Injector, logging, settings, secret storage (pure Dart) |
| `packages/protocol/` | Generated from `proto/`. Never edit by hand; run `scripts/gen.sh` |
| `packages/transport/` | Noise XX secure channel, framing, LAN discovery (pure Dart) |
| `packages/engine/` | Identity, trust store, pairing, sessions, the `Feature` API (pure Dart) |
| `packages/feature_kit/` | What a feature module plugs into the app: `FeatureUi`, shared Ferret widgets |
| `packages/ferret_<capability>/` | Flutter plugin packages with the platform code for one capability (Kotlin, Swift, C++, D-Bus), reusable outside Ferret |
| `packages/sofluffy_ui/` | Design system (git submodule). Edit it here when Ferret needs a new component, then commit and push inside the submodule |
| `proto/` | Protobuf source of truth, linted and checked for breaking changes with `buf` |
| `docs/public/` | The docs site, and the only copy of each page. `docs/public/spec/` is the protocol spec |
| `extensions/browser/` | WebExtension (TypeScript) |
| `magisk/`, `lsposed/` | Android root modules |

Dependencies point one way: `apps` → `modules` → `packages`. Packages never import modules or apps.

## Architecture

- **Engine** (`packages/engine`): `FerretEngine` owns the identity, the trust store, discovery, pairing and one `Session` per connected trusted device. Everything a device says arrives as an `Envelope` (`proto/ferret/v1/envelope.proto`) routed by its `feature` id.
- **Features** implement `Feature` (engine side, pure Dart where possible) and `FeatureUi` (Flutter side). Each owns its proto package `proto/ferret/<feature>/v1/` and its settings keys `<feature>.*`. Adding a feature never changes the envelope, the engine or another feature.
- **Capabilities and tiers**: platform abilities sit behind interfaces in each `ferret_<capability>` package. Android has four tiers (standard, Shizuku, root/Magisk, LSPosed); the active tier is detected at runtime and features ask for a capability, never for root.
- **Security**: every connection is Noise XX. A device is trusted only after pairing (QR offer with a one-time secret, or comparing a 6-digit code). Untrusted channels may only pair.

## Rules that matter most here

- **Privacy is the product.** No analytics, crash reporting SDKs, Firebase, Google Play Services or network calls other than to the user's own paired devices (and a self-hosted relay they configured). Never log message contents, clipboard contents, SMS, notification text, keys or secrets.
- **Device testing**: use emulators and simulators, or a QA build with its own application ID (`io.sofluffy.ferret.qa`). Always pass `--no-uninstall` to `flutter test -d <device>`. Never uninstall, clear or overwrite the user's installed app.
- Generated files (`*.pb*.dart`, `lib/<feature>.dart` barrels in `packages/protocol`) come from `scripts/gen.sh` only.

## Checklist before commit

- `scripts/check.sh <package>` passes: format, no analyzer issues, tests green
- New behaviour has tests; protocol changes pass `buf lint` and `buf breaking`
- The rules in CONVENTIONS.md hold (no `!`, no `else`, no ternary, braces on every `if`, barrels, no redundant comments)
- A user-facing feature has its page in `docs/public` and a line in `CHANGELOG.md` under `## [Unreleased]`
- One logical change per commit, Gitmoji message
