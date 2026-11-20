# Your Android phone as a webcam

> **TL;DR**
>
> 1. Plug the phone into your computer with a USB cable.
> 2. On the phone, tap the USB notification and choose **Webcam**.
> 3. Pick the phone as the camera in your video app. That's it.

Your laptop's camera is grainy, and the phone in your pocket has a great one.

Many Android phones with Android 14 or later can be a USB webcam all by themselves. No app on the phone, no driver on the computer. It works on macOS, Windows and Linux, because the phone shows up as a standard USB camera.

## 📷 How to turn it on

1. Plug the phone into your computer with a USB cable.
2. On the phone, pull down from the top and tap the USB notification (**Charging this device via USB**).
3. Choose **Webcam**.
4. In Zoom, Meet, FaceTime, OBS or any video app, pick the phone as the camera.

In Ferret, open the phone on your computer: **Use Pixel 7 as a webcam** shows these steps right there.

## 📶 Over Wi-Fi with Ferret

> 🧪 **Beta.** It works in my tests, but it hasn't met enough real devices yet. Something off? [Open an issue](https://github.com/simonpham/ferret/issues).

No cable, or no **Webcam** in your phone's USB list? Ferret sends the camera over Wi-Fi.

1. On your computer, open the phone in Ferret and click **Use camera** (behind **More** it reads **Use Pixel 7's camera**).
2. On the phone, tap **Once** or **Always**. The first time, Android asks for the camera and the microphone.
3. A window opens with the camera's picture and the microphone's sound.

Click **Switch camera** for the front or the back one. Your phone says **Camera on for MacBook Air** with **Stop** the whole time, and nothing starts until you answer. Changed your mind about **Always**? **Settings → To your computer → Ask every time**.

The picture lives in a Ferret window for now. Video apps can't pick it as a camera yet, but OBS and window sharing in a call can show it. Easy, right?

## 🧭 Limits

- 📱 Not every phone has it. Pixel phones from the Pixel 6 on do. No **Webcam** in the USB list? Your phone doesn't have it yet.
- 🔌 The USB webcam needs the cable. Over Wi-Fi, the camera shows in a Ferret window, not in your video app yet.
- 🤖 Over Wi-Fi it takes an Android phone with Ferret.
- 🍎 iPhone: Continuity Camera does this between an iPhone and a Mac, outside Ferret.
