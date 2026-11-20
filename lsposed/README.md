# Ferret LSPosed module (experimental)

> ⚠️ **Not a working module.** This folder holds a design and a code skeleton. It is not part of any build, it has never been compiled, and there is nothing to install.

Android apps can describe what you are looking at: the web page, the document, the place in a video. Android gives that description to its own assistant only.

An [LSPosed](https://github.com/LSPosed/LSPosed) module could read it at the source and hand it to Ferret. That would give Ferret handoff for apps that never heard of Ferret.

- [`DESIGN.md`](DESIGN.md): what it would hook, what it would send, and what must be true before it ships.
- [`app/`](app): the skeleton. The hooks are named and wired; the bodies only say what they will do.

The user page is [LSPosed (experimental)](../docs/android-modes/lsposed-experimental.md).
