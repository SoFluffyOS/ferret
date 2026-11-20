---
order: 4
---
# LSPosed (experimental)

> **TL;DR**
>
> 1. This mode is **not built yet**. There is nothing to install.
> 2. The design and a code skeleton are in the repository for people who want to help.
> 3. For everything Ferret does today, [Standard](standard.md), [Shizuku](shizuku.md) or [root](root-magisk.md) is all you need.

Handoff on a Mac and an iPhone knows *where* you are in an app: the page, the document, the spot in the video. Android apps can tell the system that too, but Android gives the answer only to its own assistant.

So Ferret's handoff works with what apps share openly, like links. See [Handoff](../features/handoff.md).

## 🧩 The idea

[LSPosed](https://github.com/LSPosed/LSPosed) lets a module run a small piece of code inside other apps, on a rooted phone.

A Ferret module would listen at the one place where an app describes what you are looking at, and pass that description to Ferret. Then "continue on my laptop" would work for apps that never heard of Ferret.

## ⚠️ Why it is experimental

- It needs root **and** LSPosed. That is a lot to ask.
- Code that runs inside other apps is a serious thing. It has to be tiny, opt-in for each app, and easy to read.
- Android changes these internals between versions.

So it stays a design until it can be done properly. Ferret will never need it for its main features.

## 🛠 Want to help?

The design note and the skeleton are in [`lsposed/`](https://github.com/simonpham/ferret/tree/main/lsposed) in the repository. Start with `DESIGN.md`.
