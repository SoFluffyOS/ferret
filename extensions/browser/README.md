# Ferret for your browser

Send the tab you're on to your phone, and open the pages your phone sends in the browser you're using. Chrome, Edge, Brave, Opera, Vivaldi and Firefox, from one codebase.

The extension only talks to the Ferret app on the same computer, over `ws://127.0.0.1`. How that works and why it's safe: [PROTOCOL.md](PROTOCOL.md). How people use it: [the user guide](../../docs/public/getting-started/browser.md).

## 📦 Build

```sh
npm install
npm run check   # types, tests, then the build
```

`npm run build` writes `dist/chromium` and `dist/firefox`. Same code, two manifests (`manifest.mjs`): a service worker for Chromium, background scripts and an add-on id for Firefox.

No remote code, no analytics, no network calls other than 127.0.0.1. Dependencies are dev-only and pinned.

## 🧪 Try it

- **Chromium:** open `chrome://extensions`, turn on **Developer mode**, click **Load unpacked** and pick `dist/chromium`.
- **Firefox:** open `about:debugging#/runtime/this-firefox`, click **Load Temporary Add-on…** and pick `dist/firefox/manifest.json`.

Then run Ferret on the same computer and pair from the extension's settings page.

## 🗂️ Layout

| Path | What |
| --- | --- |
| `src/protocol.ts` | Message types and the parser for what Ferret sends |
| `src/bridge_client.ts` | Finds Ferret on its ports, says hello, matches replies |
| `src/background.ts` | Wires it to the browser: menus, shortcut, badge, notifications, focus |
| `src/read_position.ts` | Runs in the page, only when asked: video time and scroll |
| `src/popup/`, `src/options/` | The toolbar popup and the settings page |
| `test/` | Vitest unit tests |
