# Keep Ferret running on Android

> **TL;DR**
>
> 1. Open Ferret. The **Stay connected** card lists what is in the way, each with a **Fix** button.
> 2. Set Ferret's battery use to **Unrestricted**.
> 3. On Samsung, Xiaomi, OnePlus, Oppo, Huawei or Vivo, also allow Ferret in the maker's own battery screen (steps below).
> 4. Say **Yes** when the card asks **Start Ferret when Pixel 7 restarts?**

"It worked, then it stopped after a few hours." That is the number one complaint about every app that links a phone to a computer. The app is rarely the one to blame: Android, and even more the phone maker, stops apps that run in the background.

Ferret tells you when that happens, and this page shows how to stop it for good.

## 🩺 What Ferret tells you

The **Stay connected** card on Home shows up only when something is in the way:

- **Android may stop Ferret in the background.** Battery optimization is on for Ferret. Tap **Fix** and allow it.
- **Battery use for Ferret is set to Restricted.** Android stops Ferret each time you leave the app. Tap **Fix**, open **App battery usage** and choose **Unrestricted**.
- **Your Samsung phone has its own battery saver too.** Tap **Open settings** and follow the steps written under it. They are the same as below.
- **Android stopped Ferret 3 times today.** Something is still killing it. Check the steps for your phone again.

Nothing listed? The card is gone and you're good to go!

## 🔋 Every Android phone

**Settings → Apps → Ferret → App battery usage → Unrestricted.**

That is the only setting a Pixel, a Motorola or a Nokia needs.

Three states exist, and they are very different:

| Battery use | What happens to Ferret |
|---|---|
| **Unrestricted** | Runs all the time. |
| **Optimized** (the default) | Runs while its notification is up. Android may still stop it when memory is short. |
| **Restricted** | Stops about a minute after you leave the app. Nothing arrives until you open Ferret again. |

Came back from **Restricted**? Open Ferret once. It starts its background service again the moment it is on screen.

## 📱 Steps for your phone maker

Menus move between versions. When yours looks different, search Settings for the word in bold, or look your phone up on [dontkillmyapp.com](https://dontkillmyapp.com).

### Samsung (One UI)

1. Settings → Battery → Background usage limits → **Never sleeping apps** → add Ferret.
2. Settings → Apps → Ferret → Battery → **Unrestricted**.
3. Still stopped? In the same Background usage limits screen, turn off **Put unused apps to sleep**.

### Xiaomi, Redmi, POCO (MIUI, HyperOS)

1. Settings → Apps → Manage apps → Ferret → turn on **Autostart**.
2. On the same screen, **Battery saver** → **No restrictions**.
3. Open the recent apps view, long-press Ferret's card and tap the **lock**.

### OnePlus (OxygenOS)

1. Settings → Apps → Ferret → Battery usage → turn on **Allow background activity**.
2. Settings → Battery → Battery optimization → ⋮ → **Advanced optimization** → turn off **Sleep standby optimization**.
3. Lock Ferret in the recent apps view.

### Oppo, realme (ColorOS, realme UI)

1. Settings → Apps → Ferret → Battery usage → turn on **Allow background activity** and **Allow auto launch**.
2. Lock Ferret in the recent apps view.

### Huawei, Honor (EMUI, MagicOS)

1. Settings → Battery → **App launch** → Ferret → turn off **Manage automatically**.
2. Keep all three switches on: **Auto-launch**, **Secondary launch**, **Run in background**.

### Vivo, iQOO (Funtouch OS, OriginOS)

1. Settings → Battery → **Background power consumption management** → Ferret → allow.
2. Turn on **Autostart** for Ferret (Settings → Apps → Autostart, or in i Manager).

## 🚀 After a restart or an update

- **Restart:** Ferret starts again once you unlock the phone, **if you said yes**. The **Stay connected** card asks once: **Start Ferret when Pixel 7 restarts?** Tap **Yes** and it does. Tap **Not now** and Ferret reconnects only when you open it. It's your phone, so it's your call, and Ferret never asks twice.
- **Changed your mind?** **Settings → Background → Start when the phone starts**.
- **Had Ferret before this question existed?** Nothing changes for you. It keeps starting with the phone, unless you had turned that off.
- **Update:** Ferret starts again by itself right after it is updated.
- **Swiped away:** closing Ferret in the recent apps view doesn't stop it on stock Android. Some makers stop it there, which is why you lock its card.
- **Force stop:** Android keeps a force-stopped app off until you open it yourself. Nothing can start it, not even a restart.
- **Restricted battery use:** Android doesn't tell a restricted app that the phone restarted. Ferret stays off until you open it.

## 😴 While the phone sleeps

A phone that lies still with its screen off goes into Doze, Android's deep sleep. Ferret's background service keeps its place on the network there, so your computer still reaches the phone.

- A device that went away is called again for a few minutes, then every 15 minutes when Android lets apps work. No extra wake-ups, so it stays light on battery.
- Android cut Ferret off the network and lets it back on? Ferret reconnects at once.
- Screen on, Wi-Fi back, app opened: Ferret reconnects in about a second.

## 🧩 Other settings that get in the way

- **Notifications off (Android 13+):** Ferret still runs. You just don't see its notification.
- **Data Saver:** it only limits mobile data and Wi-Fi marked as metered. On your home Wi-Fi it changes nothing.
- **Battery Saver:** Ferret keeps running.
- **Pause:** you paused Ferret from its notification. Tap **Resume**.

🦊
