# Computer actions

> **TL;DR**
>
> 1. On your phone, open your computer in Ferret.
> 2. Under **Power and sound**, tap **Sleep**, **Restart…**, **Shut down…** or a volume button. Your own actions are under **Your actions**.
> 3. The first time, click **Always allow** or **Allow once** on the computer. That's it.

You're in bed. The computer in the other room is still on, playing music to nobody.

With Ferret, your phone puts it to sleep, turns the volume down, or runs that backup script you always forget. Another computer of yours can ask too. Over your own Wi-Fi, nothing else.

## 💻 What a computer offers

Open a computer in Ferret on another device. Under **Power and sound**:

- 🌙 **Sleep**
- 🔄 **Restart…**
- ⏻ **Shut down…**
- 🔊 **Volume**: mute or unmute, down, up.

Locking is one tap away too: **Lock MacBook Air**, under **More** at the top. See [Control](remote-input.md). Or let it lock by itself when your phone leaves: see **Lock when your phone leaves** below.

**Restart…** and **Shut down…** ask "are you sure" on your phone first. Fair warning: once it's off, Ferret can't reach it until someone turns it on. Then the computer counts down **10 seconds** with a **Cancel** button, as a notice and on top of Ferret. Anyone sitting there can stop it.

How it went shows up in **Activity**: "MacBook Air is going to sleep", "MacBook Air said no", "Nobody answered on MacBook Air".

## 🛠️ Your own actions

A script, a shortcut, a command you run every evening. Give it a name, and it's one tap away.

On the computer, open **Settings → Control → Your actions** and click **Add action**:

- **Name**: what your devices show, such as "Good night".
- **Command, script or shortcut**: what runs.

```sh
shortcuts run "Good night"          # a Shortcut on a Mac
~/bin/backup-photos.sh              # a script
C:\Scripts\good-night.ps1           # PowerShell on Windows
/usr/bin/systemctl --user start backup.service
```

Easy, right? It now sits under **Your actions** on every device of yours.

A few rules keep this safe and boring:

- It runs **as you**, **without a shell**. No pipes, no `&&`, no `$VARIABLES`. Need those? Put them in a script and give its path.
- Quotes keep words together, and `~` is your home folder.
- `.sh`, `.scpt`, `.app`, `.ps1`, `.bat` and `.lnk` files open with the right program.
- It gets **30 seconds**. After that Ferret stops it and says so.
- What it printed stays on the computer: its last line is in **Activity** there. Your phone only learns whether it worked.

## 🔒 Lock when your phone leaves

You walk off for a coffee. Your Mac stays open on the desk, for anyone passing by.

Ferret already knows when your phone drops off the Wi-Fi. So it can lock the computer for you.

On the computer, open **Settings → Control → Lock when your phone leaves** and turn on **Lock this Mac when Pixel 7 leaves**. The same switch sits on the phone's page in Ferret. Pick how long it waits under **Lock after**: 1 to 10 minutes, 2 by default.

What happens then:

1. Pixel 7 drops off the Wi-Fi and stays gone for those minutes.
2. Ferret checks that nobody has touched the keyboard or mouse for at least a minute. Someone typing? It waits.
3. **Locking this Mac in 10 seconds · Pixel 7 left**, with **Cancel**, on top of Ferret and as a notice.
4. Locked. **Activity** says **Locked this Mac: Pixel 7 left**.

That's it. It **NEVER** unlocks: you type your password like always.

What doesn't count as leaving:

- 📶 **Reconnecting…**: the Wi-Fi hopped and the phone is back within the wait.
- ⏸️ **Pausing or quitting Ferret** on the phone: it says goodbye first.
- 😴 **The phone's screen off, or Doze**: Ferret's background service keeps it connected.
- 🪫 **A dead battery while you're at the desk**: you're using the keyboard, so it doesn't lock. Step away for a minute and it will, after the countdown.
- **Cancel** keeps it unlocked until the phone comes back and leaves again.

Be honest with yourself about what this is: it means "left the Wi-Fi", not "left the room". Your phone in the next room on the same Wi-Fi is still here.

- 🤖 **Android only.** iOS stops Ferret in the background, so an iPhone would look gone all the time.
- 🍎 **macOS** locks like **Lock Screen** in the Apple menu. 🪟 **Windows** like **Win+L**. 🐧 **Linux** through logind, then your desktop's screen saver. Idle time comes from `xprintidle` on X11, or logind on Wayland (that one only says idle after your desktop's own idle delay). When the system won't say, it still counts down, so you can cancel.

## 🔐 You stay in charge

Your phone never sends a command. It sends the **id** of an action that already exists on the computer, and the computer decides. A stolen phone can't make up a new one.

- **The first time** a device asks for an action, the computer asks you: "Let Pixel 7 restart this Mac?" with **Always allow**, **Allow once** and **Don't allow**. As a notice, on top of Ferret, and on the home card.
- **For your own actions**, the question shows **exactly what will run**, word for word.
- **Always allow** is per device and per action. Sleep doesn't unlock Shut down. The three volume buttons count as one.
- **Change the command** of an action and every device asks again. They were allowed to run the old one.
- **Afterwards**, **Activity** has a line for it, and **Settings → Control → History** keeps the last 20.
- Changed your mind? On the computer, open the phone in Ferret: **Restart this Mac without asking** and its friends are switches there. Turn one on to skip the question, off to bring it back.
- Don't want one device near any of it? **What Pixel 7 can use → Computer actions**, off.
- Don't want it at all? Turn off **Let your devices run actions on this Mac** in **Settings → Control**.

Only devices you paired can even ask.

## ⌨️ From the command line

On a computer, `ferret-cli` asks through the Ferret app running there:

```sh
ferret-cli action "Family PC"            # lists what it offers
ferret-cli action "Family PC" sleep
ferret-cli action "Family PC" "good night"   # one of its owner's own, by name or id
```

The built-in ids are `sleep`, `restart`, `shut_down`, `mute`, `volume_up` and `volume_down`. The other computer still asks its owner the first time. `--json` prints the answer for scripts, with the exit code of your own command in `exit_code`.

## 🧩 Per platform

- 🍎 **macOS**: sleep is `pmset sleepnow`. Restart and shut down go through System Events, so apps get to save first, like from the Apple menu. macOS asks **once** whether Ferret may control System Events: click **OK**. Said no by mistake? **System Settings → Privacy & Security → Automation → Ferret**.
- 🪟 **Windows**: the same sleep, restart and shut down as the Start menu. Apps that hang are closed. Volume uses the volume keys.
- 🐧 **Linux**: logind (`Suspend`, `Reboot`, `PowerOff`), then `systemctl`. Volume through `wpctl`, then `pactl`, then `amixer`. If your desktop asks for a password to shut down, Ferret can't type it.
- 📱 **Android and iPhone**: they ask, they don't offer. An iPhone can ask while Ferret is open.

## 😴 It went to sleep. Now what?

A sleeping computer isn't on the network. Wake it with [Wake-on-LAN](wake-on-lan.md) if you turned that on, or with its power button.
