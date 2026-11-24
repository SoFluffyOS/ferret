# Browser extension

> **TL;DR**
>
> 1. Download the extension and load it in Chrome, Edge, Brave or Firefox.
> 2. Open its settings and click **Pair with Ferret**.
> 3. Check the code matches in Ferret, then click **Allow**.
> 4. Click the Ferret button in the toolbar, pick your phone. The tab opens there.

Copying a link from your browser to your phone is a small chore you do all day. Share sheets don't reach the desktop browser, and Firefox can't even be asked for its current page.

The Ferret extension fixes that. It puts your devices one click away in the browser, and pages your phone sends open right in the browser you're using.

## 📦 Install it

The extension isn't in the stores yet. Download it from GitHub and load it by hand. It takes a minute.

**Chrome, Edge, Brave, Opera, Vivaldi**

1. Download [Ferret-browser-chrome.zip](https://github.com/simonpham/ferret/releases/latest/download/Ferret-browser-chrome.zip) and unzip it. Keep the folder somewhere it can stay: the browser loads the extension from it.
2. Open `chrome://extensions` (or `edge://extensions`).
3. Turn on **Developer mode**.
4. Click **Load unpacked** and pick the unzipped folder.

**Firefox**

1. Download [Ferret-browser-firefox.zip](https://github.com/simonpham/ferret/releases/latest/download/Ferret-browser-firefox.zip). No need to unzip it.
2. Open `about:debugging#/runtime/this-firefox`.
3. Click **Load Temporary Add-on…** and pick the zip.

Firefox forgets temporary add-ons when it quits, so you load it again after each restart. That goes away once the extension is on addons.mozilla.org.

**A new version?** Download the new zip. In Chrome, unzip it over the old folder and click the reload arrow on the extension's card. You stay paired. In Firefox, load the new zip, and pair again if the extension asks.

**Rather build it yourself?** You need Node.js:

```sh
cd extensions/browser
npm install
npm run build
```

Then load `extensions/browser/dist/chromium` or `extensions/browser/dist/firefox/manifest.json` the same way.

## 🔑 Pair it with Ferret

Ferret has to run on the same computer, with **Settings → Other apps → Browser extension** on (it is by default).

1. Open the extension's settings. It opens by itself right after you install it.
2. Click **Pair with Ferret**. The extension shows a 6-digit code.
3. Ferret comes to the front and asks **Allow Firefox to use Ferret?** with a code.
4. Check that both codes match, then click **Allow**.

That's it. The extension remembers it, so you pair once per browser.

Changed your mind? Click **Remove** next to the browser in Ferret's Handoff settings, or **Unpair this browser** in the extension.

## 🚀 Send a tab

- **Toolbar button:** click it, then click a device. A line tells you what happened: "Opened on Pixel".
- **Right-click** a link or a page: **Send link to** or **Send page to**, then a device.
- **Shortcut:** `Alt+Shift+S` sends the tab to the device you used last. Change it in your browser's extension shortcuts.

Watching a video? The other device picks up at the same second. YouTube and Vimeo links carry the time themselves, so it even works in the YouTube app.

## 💡 Pages from your other devices

When your phone sends a page to this computer and the browser is the app you're using, it opens in a new tab there. Otherwise it opens in your default browser, like before.

Pages your phone offers quietly show up as a number on the Ferret button. Click it and pick one under **From your devices**. A notification tells you when one arrives; turn that off in the extension's settings.

## ⚙️ Options

- **Share the current tab:** when you leave the browser, your other devices quietly offer to continue the page you were on. The browser asks for access to your tabs. Private windows are never shared. Needs **Suggest what I'm doing** on in Ferret.
- **Tell me when a page arrives:** a notification for pages your devices offer. On by default.
- **Restore the video time and scroll position:** opens pages at the same spot as on your other device, on any site. The browser asks for access to the pages you open.

## 🔒 Privacy

- The extension only talks to Ferret on this computer, at `127.0.0.1`. Nothing goes to the internet, there's no account and no analytics.
- Ferret only accepts connections from browser extensions. Websites are turned away before they can say anything.
- A browser needs your **Allow** in Ferret, then a secret key that only works for that one extension. Ferret keeps only a fingerprint of it. Too many wrong tries and Ferret stops listening to strangers for a minute.
- The extension reads a page's video time and scroll position only when you send that page.

## 🧰 When it doesn't work

| What you see | What to do |
| --- | --- |
| "Ferret isn't running on this computer" | Open Ferret. Check **Settings → Other apps → Browser extension** is on. |
| Ferret says "Ferret couldn't start the browser connection" | Another copy of Ferret may be running. Quit it, then click **Try again**. |
| "Too many tries" | Wait a minute, then pair again. |
| A device shows **Not connected** | Turn it on and keep it on the same network. See [Pairing](pairing.md). |

Firefox puts idle extensions to sleep. The extension reconnects within a minute, or as soon as you click its button.
