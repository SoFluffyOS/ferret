# Conventions

## Dart

- **Dart 3.14+**: dot shorthands (`.center`, `.new()`, `.broadcast()`), primary constructors where they fit, records, patterns, sealed types, class modifiers.
- **Imports**: always `package:` imports, never relative. Import a folder's **barrel**, not its files. Order: `dart:`, then packages, sorted.
- **Barrels**: every folder with several files has a barrel named after the folder (`services/services.dart`), and each package has one at `lib/<package>.dart`.
- **Null safety**: never use `!`. Use patterns (`if (x case final value?)`) or promotion with an early return.
- **No `else`, no ternary**: guard clauses and early returns keep the main path flat; use a `switch` expression instead of `? :`.
- **Braces on every `if`**, even a one-line `return`.
- **Function bodies in steps**: guard clauses, then preparing values, then the work, then the result, separated by one blank line. Lines that belong together stay together.
- **Descriptive names**, including pattern variables (`stagedCount`, not `s`).
- **Comments**: the code explains itself. Comment only the non-obvious *why*. Public API gets `///` docs that say more than the name. No TODOs for obvious work.
- **Async**: wrap intentionally unawaited futures in `unawaited(...)`. Dispose every controller, subscription and timer.
- **Logging**: `printLog`, `printDebug`, `printWarning`, `printError` from `core`. Never `print`, never log user content or secrets.
- **Small files**: one class or widget per file, split by responsibility.

## Flutter

- **Design system**: build with `package:sofluffy_ui` (`Button`, `Tappable`, `ImageView`, dialogs, `FluffyTheme`). Missing a component? Add it to `packages/sofluffy_ui` (the submodule) rather than writing a one-off.
- **Tokens**: `Spacing.dX` for every dimension (padding, gaps, radii, icon sizes) and theme colours only. No magic numbers, no hardcoded colours.
- **Strings**: every user-facing string through `context.l10n` (`packages/l10n`). Never hardcode English in widgets.
- **State**: `ChangeNotifier` view models with Provider. Business logic lives in view models and services, not widgets.
- **UI types**: `ui/frames/` (smart, read view models with `context.select`, never `context.watch`), `ui/pages/`, `ui/widgets/` (dumb), `ui/dialogs/`. Use `ChangeNotifierProvider.value` + `context.select` instead of `ListenableBuilder`.
- **Imports**: `flutter/widgets.dart`; `material.dart` only where a Material widget is truly needed.
- **Rows ending in actions**: exactly one `Expanded`, holding all the text that may shrink.

## Features

- A feature module has `lib/<feature>.dart` (barrel), `lib/feature/` (the engine `Feature`), `lib/services/`, `lib/models/`, `lib/view_models/`, `lib/ui/`.
- Its messages live in `proto/ferret/<feature>/v1/`, package `ferret.<feature>.v1`. Never reuse or renumber a field; reserve removed ones.
- Settings keys are snake_case under the feature id (`clipboard.sync_images`); enum values are stored by name.
- Platform code goes in a `packages/ferret_<capability>` plugin package with a Dart interface, so other apps can reuse it.
- Features never import each other. Share through `engine`, `feature_kit` or a capability package.

## Docs

- Write to one reader, in plain words: the problem, then how Ferret solves it and how to use it. Short sentences. No marketing words (seamless, revolutionary, game-changer, supercharge, unlock, effortless, blazing).
- Links between pages are relative `.md` links so they work on GitHub too.
- `CHANGELOG.md`: one or two lines per entry, a bold name and what it does for the user. Never list a fix to something that hasn't been released yet.

## Git

- **Gitmoji** messages, short and imperative: `✨ Add clipboard sync`, `🐛 Fix reconnect after sleep`, `📝 Add pairing docs`, `♻️ Split session router`, `✅ Add discovery tests`, `🔧 Update buf config`.
- One logical change per commit; keep unrelated edits out.
