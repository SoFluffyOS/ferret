# Take a photo with your phone

> **TL;DR**
>
> 1. On your computer, open your phone and click **Take a photo**. Or press **⌃⌘P** (**Ctrl+Alt+P** on Windows and Linux).
> 2. On your phone, tap **Take photo**, then press the shutter.
> 3. Paste. The photo is already on your computer's clipboard.

You need a picture of a receipt, a whiteboard or a cable in a slide. Your phone has the camera, your computer has the document. Taking the photo, finding it and sending it over is three steps too many.

Ferret asks your phone for one photo and puts it straight on your computer's clipboard.

## 📸 Take a photo

On the computer, pick one:

- Open your phone in Ferret and click **Take a photo** (it may sit behind **More**).
- Press **⌃⌘P** on a Mac, **Ctrl+Alt+P** on Windows and Linux. It asks the phone you have open, or your first connected phone.
- On a Mac, **Device → Take Photo with Pixel 7**. On Windows and Linux, it's in the **•••** menu.

Your phone shows **MacBook Air wants a photo** with **Take photo** and **Not now**. Tap **Take photo** and your phone's own camera opens. Press the shutter, keep the shot, and that's it.

A second later Activity on the computer says **Photo from Pixel 7 · On your clipboard**. Paste it anywhere. The photo is also in your receive folder, so you can drag the Activity line to Finder or press Space to look at it. Lost it from the clipboard? Click **Copy** on that line.

While you wait, Activity says **Waiting for a photo from Pixel 7**. Changed your mind? Click **Cancel** and the request leaves the phone.

## 🔒 Nothing is taken behind your back

- The phone always asks first, and always shows its camera. Nothing is captured until you press the shutter.
- **Not now** says no, and the computer hears it right away.
- Nobody answers within 5 minutes? The request goes away by itself.
- The photo is turned the right way up and saved again without its hidden details (EXIF), so **where it was taken stays on your phone**.
- It travels like any other file in [Drop](drop.md): only to your own computer, encrypted, and checked when it arrives.

## 📄 Scan a document (iPhone)

On an iPhone, click **Scan a document** on its page. The iPhone opens its document scanner: it finds the page edges, straightens them and lets you add more pages.

- One page arrives as a picture and goes on the clipboard.
- Several pages arrive as one PDF in your receive folder.

Android has no document scanner Ferret can use without Google's own libraries, which Ferret doesn't ship. Take a photo instead.

## 🤖 Android

- Ferret opens your usual camera app. It has no camera code of its own.
- The first time, Android may ask whether Ferret can use the camera. Ferret scans pairing codes too, so Android wants that answer before it opens any camera for Ferret. Say no, and the computer shows **No camera access on Pixel 7**.
- If Ferret runs in the background, the request comes as a notification. Tap it, then **Take photo**.

## 🍎 iPhone

- Only while Ferret is open on the iPhone. iOS doesn't let apps open the camera from the background.
- The first time, iOS asks for camera access.

## 🧩 Good to know

- One request per phone at a time. Asking again replaces the first one.
- The phone needs to be connected. If it isn't, Activity says **Pixel 7 isn't connected**, with **Try again**.
- On Linux the photo goes on the clipboard as a PNG, which most apps paste. That needs `wl-clipboard` (Wayland) or `xclip` (X11), like [Clipboard](clipboard.md) pictures.
