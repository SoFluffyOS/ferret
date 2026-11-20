# Photos

> **TL;DR**
>
> 1. On your phone, open your computer and turn on **Let MacBook see your photos**.
> 2. On the computer, open the phone and click **Photos**.
> 3. Click a photo, then **Save**. Or **Select** a few and **Save 3 photos**.

You took a screenshot on your phone. Now you need it on your computer. Emailing it to yourself is annoying.

Ferret shows your phone's recent photos and screenshots on the computer, newest first. Save the ones you want. They land in your receive folder.

## 🔑 Turn it on (on the phone)

Photos never leave your phone until you say so, one computer at a time.

1. Open Ferret on the phone and tap your computer.
2. Under **What MacBook can use**, turn on **Let MacBook see your photos**.
3. Android or iOS asks for photo access the first time. Allow it.

That's it. Turn it off and the computer sees nothing again, right away.

Nothing on the computer can delete or change a photo on your phone. It can only look and save.

## 🖼️ Browse and save (on the computer)

Open the phone in Ferret and click **Photos**.

- The grid shows the newest first, and loads more as you scroll.
- Thumbnails come from the phone only when a tile shows up on screen. Nothing travels while you aren't looking.
- Click a photo to see it bigger, then **Save**. Once it's here, **Open** shows it in its app (that's how a video plays) and **Show in folder** finds the file.
- Click **Select**, pick a few, then **Save 3 photos**.

Saved photos go through the same transfer as [Drop](drop.md): checked end to end, and they pick up where they stopped if the Wi-Fi drops. Activity says **Saved 3 photos from Pixel 7**. Drag that line to Finder, or press Space to look at it.

Thumbnails stay in `~/.sofluffy/ferret/cache/photos` on the computer, so the grid opens fast next time. Ferret keeps at most 64 MB there and drops the oldest first. Unpair the phone and its thumbnails are gone.

## 📸 New screenshots arrive by themselves

Turn on **New screenshots arrive by themselves** at the top of the phone's **Photos**.

Take a screenshot on the phone and it shows up on the computer a second later. Activity says **Screenshot from Pixel 7**.

- Off by default, and only for the phone you turn it on for.
- Only screenshots, never your other photos.
- Only new ones while both run Ferret. Nothing old is sent when the phone reconnects.
- It needs **Let MacBook see your photos** on the phone too.

## 🙋 "Ask on Pixel 7"

Opened **Photos** and the phone doesn't share with this computer yet? Click **Ask on Pixel 7**.

The phone shows **MacBook wants to see your photos**. Tap it, and you get the switch for that computer. Nothing changes until you flip it.

## 🤖 Android

- Android 13 and newer asks for **Photos and videos**. Older Android asks for **Files and media**.
- On Android 14 you can pick **Select photos**. The computer then sees only those, and says **Pixel 7 shares only the photos you picked**. **Allow more photos** asks the phone again, so you can pick more.
- Screenshots are found by their folder (**Pictures/Screenshots** or **DCIM/Screenshots**), which covers Pixel, Samsung and most other phones.
- New screenshots come while Ferret's service runs. If Android stopped Ferret, they come once it runs again (only new ones from then on).

## 🍎 iPhone

- iOS lets Ferret read photos only while Ferret is open on screen. Otherwise the computer says **Open Ferret on iPhone to see photos**.
- **Limited access** works: the computer sees only the photos you picked. **Allow more photos** opens the picker on the iPhone.
- New screenshots arrive only while Ferret is open.

## 🙈 On a computer the family shares

Photos follow [private previews](../getting-started/shared-computer.md). While the screen is locked, another account is in front, or **Show previews on this computer** is off for that phone, the grid says **Photos from Pixel 7 are hidden on this computer right now** and asks for nothing.

## 📱 Limits

| | |
|---|---|
| Computers | Browse and save from a phone. A computer has no photos to share |
| Android | Shares photos, videos and screenshots while Ferret runs |
| iPhone | Shares only while Ferret is open |
| Not in this version | Deleting from the computer (on purpose), dragging a tile out of the grid, albums |

Want a full photo backup? That's a job for Syncthing or Immich. Ferret shows and fetches, it doesn't sync.

## Happy Coding 🦊
