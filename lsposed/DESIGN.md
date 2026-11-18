# Design: app state for handoff through LSPosed

Status: **design only**. Nothing here is implemented or tested.

## The problem

Ferret's handoff sends what apps share openly: a link from the share sheet, the page a desktop browser shows. It can't answer "what is the user looking at in this app right now?" on Android, because Android answers that question to one caller only: the assistant.

Two framework callbacks carry the answer:

| Callback | Since | What an app puts in |
|---|---|---|
| `Activity.onProvideAssistContent(AssistContent)` | API 23 | `webUri`, `intent`, schema.org `structuredData`, `clipData` |
| `Activity.onHandoffActivityDataRequested(HandoffActivityDataRequestInfo)` | API 37 | `HandoffActivityData`: a component, extras, a fallback URI |

(The second one is sometimes written `onHandoffActivityRequested`. In the API 37 SDK the method is `onHandoffActivityDataRequested`. Check the name against the SDK you build with.)

Browsers, YouTube, Maps, readers and many others fill in the first. The second is new and made for exactly this job, but only the system may ask.

## The idea

An LSPosed module runs inside the apps the user picks. It does not wait for the system to call these callbacks. On a request from Ferret, it calls them itself on the activity in front and returns the result.

```
Ferret (app)                         LSPosed module, inside the scoped app
────────────                         ─────────────────────────────────────
user taps "Continue on…"
  │  explicit broadcast, signature permission
  ├────────────────────────────────▶ finds the resumed Activity
  │                                  runs on its main thread:
  │                                    onHandoffActivityDataRequested(…)   (API 37+)
  │                                    onProvideAssistContent(content)
  │                                  keeps: web URI, fallback URI, component
  │  result (ordered broadcast result or a bound Messenger)
  ◀────────────────────────────────┤
sends a normal handoff item to the paired device
```

### What is hooked

1. `Activity.onResume` / `onPause` (after): keep a weak reference to the activity in front. No data is read here.
2. Nothing else. The two callbacks are *called*, not hooked. Hooking them would only see calls the system makes, and the system rarely makes them.

### What leaves the app

Only these, and only on a request the user started:

- `AssistContent.webUri`
- `HandoffActivityData.fallbackUri` and its component name
- the activity's label, for the "Continue … from Pixel" line

Not `structuredData`, not `clipData`, not `AssistStructure` (the view tree), not extras. Those can hold anything on screen. Version 1 is for links.

### How the two sides talk

- Ferret declares a `signature` permission. The module's receiver requires it, and Ferret's result receiver requires the module's. Nothing else on the phone can ask or listen.
- The request is an explicit broadcast to the package in front, which Ferret knows from the usage it already has. No global broadcast.
- The answer goes back as the ordered broadcast's result. Nothing is stored.

### What Ferret does with it

The handoff feature gets one more source, behind a capability in `ferret_power` (`PowerTier.lsposed`, a `currentAppLink()` call). It makes the same handoff item as a shared link. The other device needs no change.

## Rules it must keep

1. **Opt-in per app.** LSPosed's scope list is the switch: the module does nothing in an app the user didn't tick. The recommended scope is a short list of browsers and readers, never "all apps", never system apps.
2. **Only on request.** No hook reads app state in the background. No request, no call.
3. **Links only**, as listed above.
4. **Fail closed.** Any exception inside the hooked app is caught and swallowed. A module that crashes someone's banking app is worse than no module.
5. **Small enough to read.** One file of hooks. No reflection beyond what the two callbacks need. No network, no storage, no logging of what it reads.
6. **Never required.** Every Ferret feature keeps working without it.

## Open questions

- **Calling `onHandoffActivityDataRequested` from outside the system.** The request-info object may have no public constructor. It may need reflection, and apps may check where the call comes from. To verify on API 37.
- **Threading.** Both callbacks expect the main thread. The module posts to it and waits with a short timeout (250 ms), then gives up.
- **Apps that build `AssistContent` lazily or not at all.** Then there is no answer, and Ferret says "This app doesn't share where you are" instead of guessing.
- **Modern Xposed API (libxposed) or the legacy one.** The skeleton uses the legacy `IXposedHookLoadPackage` because it is the most widely documented. Moving to libxposed's service API would also give a clean channel back to Ferret. To decide before any implementation.
- **Detection.** Some apps refuse to run with Xposed around. That is the user's trade to make; the docs must say so.

## Before this ships

- [ ] Implemented and tested on at least two Android versions, one of them API 37.
- [ ] A security review of the request and result channel.
- [ ] A scope list of apps it was tried with.
- [ ] `PowerTier.lsposed` in `ferret_power`, with detection (the module answers a ping) and a rung on the ladder.
- [ ] The docs page rewritten from "not built yet" to real steps.

## Why not something lighter

- **Accessibility service:** sees the screen, not the link, and reads far more than needed. Google Play forbids this use.
- **Being the assistant app:** Ferret would get `AssistContent` the official way, but the user loses their assistant, and it only fires on the assist gesture.
- **Shizuku or root alone:** the shell user can't make an app run its callback, and the result goes to the assistant anyway.
