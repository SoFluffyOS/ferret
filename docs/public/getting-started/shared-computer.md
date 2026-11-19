# A computer the family shares

One PC or Mac, a login for each person, and everyone's phone nearby. Ferret works per account: each person runs their own Ferret, with their own devices, files and notifications.

> TL;DR
> 1. Each person installs nothing extra: Ferret runs in every account that opens it.
> 2. Pair your phone from YOUR account. It shows up as **Family PC (Anna)**, not a second **Family PC**.
> 3. Your phone's notifications and texts hide while the screen is locked or someone else's account is in front.

## 👪 One Ferret per account

Ferret keeps everything in your account's home folder: who you paired, your settings, your received files. Ben's Ferret never sees Anna's phone, and the other way round.

When Ferret hears another account's Ferret on the same computer, it adds the account to its name: **Family PC (Anna)** and **Family PC (Ben)**. Your phone knows which one is yours. Gave it a name yourself? Ferret keeps yours.

**Settings → This device** says so, and which port this Ferret listens on.

## 🔌 Ports

The first Ferret takes port `47640`. The next accounts move to `47642`–`47649` and tell your devices where they are. The Windows installer and the Linux firewall profiles open that range too. Already installed? **Fix connection → Allow through firewall** adds the missing rule.

## 🙈 Previews of private things

Your phone's notifications, texts, callers and copied text are yours. Ferret covers them with **New text on Pixel 7** and **Open Ferret to see it** when:

- the screen is **locked**, or another account is **in front** (fast user switching), on every computer, always
- you turned off **Show previews on this computer** for that phone

That switch sits at the bottom of **What Pixel 7 can use** on the phone's page. On a computer where other accounts run Ferret, it starts OFF. Turn it on and your previews show again while you're at the screen.

Covered lines stay in Activity, so you still see that something arrived. Open Ferret to read it.

Your phone knows too. While your account is locked or switched away, the computer's row on your phone says **Connected · locked**: what you send there waits for you, and **Continue** suggestions go to a device you're at instead.

This is not a lock. Anyone who opens Ferret in your account can read your texts, like any app there. Give each person their own login and lock the screen when you walk away.

## 🎟️ A guest sends one file

A friend wants to send you a photo, and doesn't have Ferret. On Home, under **Do more**, tap **Allow once** next to **Receive a file from a guest**.

Your computer shows up in their phone's **Quick Share** (Android) or the **LocalSend** app (any phone) for 10 minutes. The first file that arrives closes it again. Each file still asks first, and nothing gets paired.

Need longer, or several people? Open **Let other phones send you files** in Drop's card and use **Show 10 min** or **Allow 10 min**.

## 📱 A shared tablet

Ferret on a tablet is one Ferret, whoever holds it. Pair only the devices the whole family may see from it, and use **What … can use** to turn off notifications or messages for a phone.

## 🧭 Limits

- Fast user switching is noticed on macOS, Windows and Linux (logind, GNOME and KDE). Other lock screens on Linux may not say when they lock.
- A Ferret left running in a switched-away account stays connected to its own devices. Its notices wait in that account and show covered when it comes back.
- Discovery shares one port between accounts. If a phone takes a while to find the second account, give it a few seconds or use **Connect by address**.
