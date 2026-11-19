# Handoff

> **TL;DR**
>
> 1. Pair your devices.
> 2. On your phone, share a link to **Continue on…** and pick your laptop. It opens there.
> 3. On your Mac, open a device in Ferret and pick **Send a link…** (or **Send current page**).
> 4. Walk away from a page and your other device quietly offers **Continue “title” from Pixel**.

You're reading an article on your phone and sit down at your laptop. Finding that page again means scrolling through history, or sending yourself a message.

With Ferret, you send it over in two taps, or your laptop simply offers to continue it.

## 🚀 Send it now

This always works, on every device.

- **Android:** share a link or some text, then pick **Continue on…** in the share sheet. Pick a device in the small list and you're done. A short message says "Sent to MacBook".
- **Any device:** open a device in Ferret, then **Send a link…**. Paste a link or type some text.
- **macOS:** turn on **Read the current browser page** in **Settings → Continue & media**, then use **Send current page** on a device.
- **macOS, by dragging:** drag a link from your browser (its address bar, or a link on the page) onto a device in Ferret's popover or window. It opens there.

What happens on the other side:

- A web page opens in the browser.
- A link that belongs to an app (YouTube, Wikipedia, Maps…) opens in that app when it's installed, and on the web when it isn't.
- A place opens in the maps app (Apple Maps on a Mac, your maps app on Android, OpenStreetMap elsewhere).
- Plain text lands on the clipboard, with a quiet "Copied text from Pixel".

Don't want things to open by themselves? Turn off **Open sent links right away**. They wait in a notification with **Open** and **Dismiss** instead.

## 💡 Quiet suggestions

When **Suggest what I'm doing** is on (it is by default), your devices tell each other what you're on:

- On a Mac with **Read the current browser page** on, leaving Safari or Chrome offers that page to your other devices.
- On Android, calling Ferret as your assistant on any screen offers it too (see below).

The other device shows **Continue “title” from Pixel** in **Activity**, with **Open**, and **✕** to let it go. No notification, no sound.

Suggestions go away after 5 minutes, and a newer one from the same device replaces the older one. When a device says someone is using it right now, suggestions go only there.

## 🤖 Continue from any app on Android

Some apps don't have a share button for what you're looking at. Ferret can read the current screen when you ask, like the system assistant does:

1. In Ferret, open **Settings → Continue & media**, then tap **Open assistant settings**.
2. Pick **Ferret** as the **Digital assistant app**.
3. On the same page, turn on **Use text from screen**.
4. Now long-press Home (or swipe up from a bottom corner) on any screen. Ferret shows your devices. Tap one.

Ferret only reads the screen when you call it. It reads what the app shares: the web address of the page, the app's own link to it, and any extra data the app chose to share. Nothing else.

Good to know: while Ferret is your assistant, the long-press opens Ferret instead of Google Assistant, and "Hey Google" stops working. Switch back any time on the same settings page.

## 🍎 Reading the browser page on macOS

**Send current page** asks Safari or your Chromium browser (Chrome, Brave, Edge, Arc, Vivaldi, Opera) for the page in its front window. macOS asks you once per browser to allow it. If you said no, allow it in **System Settings → Privacy & Security → Automation → Ferret**.

Firefox can't be asked for its page by macOS. Install the [browser extension](../getting-started/browser.md) instead: it sends any tab, in any browser, with one click.

## ⚠️ Limits per platform

- **Android:** apps can't open other apps from the background. When Ferret is in the background, things sent to your phone wait in a notification: tap it and it opens.
- **iOS:** no share sheet or assistant yet. Things sent to an iPhone open when Ferret is open, and wait as a suggestion otherwise.
- **Linux and Windows:** send with **Send a link…**. Links open in your default browser or app.
- **Every platform:** Ferret never opens local files, `content://` links or scripts sent from another device. Only web pages, places, mail, phone links and app links.

## 🧩 For app developers

Ferret's activity follows the same shape as Android's `HandoffActivityData`: the activity itself, plus a web URI to fall back to.

On Android, your app can tell the assistant more through `onProvideAssistContent`:

```kotlin
override fun onProvideAssistContent(outContent: AssistContent) {
    outContent.webUri = Uri.parse("https://example.org/notes/42")
    outContent.structuredData = JSONObject()
        .put("@context", "https://schema.org")
        .put("@type", "CreativeWork")
        .put("name", "Shopping list")
        .put("url", "https://example.org/notes/42")
        .put("ferret", JSONObject()
            .put("deepLink", "notes://open/42")
            .put("apps", JSONObject()
                .put("android", "org.example.notes")
                .put("apple", "org.example.Notes"))
            .put("state", "{\"scroll\":1200}")
            .put("stateType", "org.example.notes.state"))
        .toString()
}
```

How Ferret maps it:

| JSON-LD | Activity field |
|---|---|
| `url` (else `AssistContent.webUri`) | `uri` |
| `name`, else `headline` (else the window title) | `title` |
| `geo.latitude`, `geo.longitude` | `uri` as `geo:lat,lng`, kind place |
| `ferret.deepLink` (else the data URI of `AssistContent.intent`) | `deep_link` |
| `ferret.fallbackUri` (else `webUri`, else `url`) | `fallback_web_uri` |
| `ferret.apps.android`, `.apple`, `.linux`, `.windows` | `apps` |
| `ferret.state`, `ferret.stateType` | `state`, `state_type` |

Without `ferret.state`, the whole JSON-LD travels as `state` with `state_type` `application/ld+json`. State is capped at 64 KB, and Ferret never reads it.

## 📜 Protocol

Feature id `handoff`, messages in `proto/ferret/handoff/v1/handoff.proto`:

- `PublishActivity` (passive, no reply): the receiver keeps one suggestion per sending device, for at most 5 minutes from when it arrived. It counts the lifetime as `expires_at_ms - created_at_ms`, so clocks that disagree don't matter.
- `ContinueActivity` (request): the receiver opens it or keeps it as a suggestion, and answers `ContinueResult` with `OPENED`, `SUGGESTED` or `FAILED`. The same activity id twice gets the first answer again, without opening twice.
- `ClearActivity` (no reply): withdraws one activity, or every activity from the sender when `activity_id` is empty.

Receivers must refuse URIs with local schemes (`file`, `content`, `javascript`, `data`, `intent` and the like).
