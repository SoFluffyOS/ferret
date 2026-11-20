# Contributing to Ferret

Thanks for helping 👋 Ferret is a small project, so every bug report, translation and pull request counts.

> TL;DR
> 1. Found a bug? Open an issue with the steps and, for a connection problem, Ferret's **Copy diagnostics** report.
> 2. Want your language? Follow [Translate Ferret](docs/contributing/translating.md).
> 3. Code? Read [CONVENTIONS.md](CONVENTIONS.md), run `scripts/check.sh`, open a pull request.

## 🐛 Report a bug

Open an issue and tell me:

- What you did, what you expected, and what happened instead.
- Which devices: platform, version, and Ferret's version (**Settings → About**).
- A screenshot or a short video, if it shows something.

Devices won't connect? Open **Fix connection** on the device and tap **Copy diagnostics** at the bottom. It puts a short report on your clipboard, with no names, no addresses and no content, so it's safe to paste into the issue. See [Fix connection](docs/features/connection-doctor.md).

Found a security problem? Please don't open an issue. See [SECURITY.md](SECURITY.md).

## 🌐 Translate

Ferret speaks English and Vietnamese. Adding a language needs no code at all. See [Translate Ferret](docs/contributing/translating.md).

## 💻 Write code

Set up once:

```bash
git clone --recurse-submodules https://github.com/simonpham/ferret.git
cd ferret
scripts/get.sh            # pub get for the whole workspace (Flutter comes from fvm)
```

Then, for each change:

```bash
scripts/check.sh modules/<feature>   # format, analyze, test: one package, or all without a path
cd apps/ferret && fvm flutter test test/screens   # renders every main screen to temp/screens
```

A few things matter a lot here:

- **Privacy is the product.** No analytics, no crash reporting SDKs, no network calls other than to your own paired devices. Never log clipboard text, notifications, messages, file names or keys.
- **Follow [CONVENTIONS.md](CONVENTIONS.md):** no `!`, no `else`, no ternaries, braces on every `if`, barrels, small files, every string through l10n.
- **One feature, one module.** Features never import each other. [CLAUDE.md](CLAUDE.md) has the map of the repository.
- **The protocol lives in `proto/`.** Change it there and run `scripts/gen.sh`. Never renumber or reuse a field.
- **A user-facing change** gets its page in `docs` and one line in [CHANGELOG.md](CHANGELOG.md).
- **Gitmoji commits**, one logical change each: `✨ Add clipboard sync`, `🐛 Fix reconnect after sleep`.

Test on emulators and simulators, or a QA build with its own app ID. Never wipe your own installed Ferret.

## 📜 License

By contributing, you agree that your code is released under [GPL-3.0](LICENSE), and changes to the protocol (`proto/`, `docs/spec/`) under [MIT](proto/LICENSE).

Please also follow the [Code of Conduct](CODE_OF_CONDUCT.md).
