# Scripting

> **TL;DR**
>
> 1. Run `ferret-cli watch` on a computer to see what happens with your devices, live.
> 2. Add `--json` and pipe it into your own script, or drop an executable in `~/.sofluffy/ferret/hooks/`.
> 3. On Android, add a Ferret action in Tasker. On iPhone, use Ferret's actions in Shortcuts. That's it.

Your phone connects when you get home. A file lands. The battery drops under 20%. A call rings.

You want something to happen. Pause the music, move the file, turn on the lamp. Ferret tells your scripts, and your scripts can ask Ferret to act.

Everything stays on this computer and your own devices. Nothing listens on the network for scripts.

## 🖥️ The commands

`ferret-cli` talks to the Ferret app running on the same computer:

```sh
ferret-cli watch                         # what happens, live
ferret-cli open "Pixel 7" https://example.com
ferret-cli notify "Pixel 7" "Build done" "All tests green"
ferret-cli ring "Pixel 7"
ferret-cli clipboard get                 # the last text that arrived
ferret-cli clipboard send "hello"        # to every connected device
ferret-cli action "Family PC" sleep
ferret-cli wake "Family PC"
ferret-cli send report.pdf
```

A device name can be its full name, the start of it, or its id: `pix` works when only one device starts with it. Add `--json` to any of them for an answer your script can read.

Exit codes: `0` done, `1` failed, `64` wrong usage, `66` a file or a clip is missing, `69` the Ferret app isn't running, `75` the device isn't connected.

## 👀 Watch

```sh
$ ferret-cli watch
Watching. Press Ctrl-C to stop.
09:30:12  Pixel 7 connected
09:30:13  Pixel 7 battery 64%
09:41:02  Pixel 7 sent 2 files (4.1 MB): /Users/you/Downloads/Ferret/IMG_0042.jpg, /Users/you/Downloads/Ferret/IMG_0043.jpg
09:52:30  Pixel 7 call from Anna
```

`--json` prints one JSON object per line:

```json
{"v":1,"type":"device.connected","at":"2026-11-19T09:30:12.000Z","device":{"id":"3f2a…","name":"Pixel 7"}}
{"v":1,"type":"battery","at":"2026-11-19T09:30:13.000Z","device":{"id":"3f2a…","name":"Pixel 7"},"percent":64}
```

Only some events? `--type device,battery`. A name matches the events under it: `device` gets `device.connected`, `device.disconnected` and `device.reconnecting`.

Want the copied text and the notification text too? Add `--include-content`. It's left out by default on purpose.

### Bash

```sh
#!/bin/sh
# Pause the music when a call rings on the phone.
ferret-cli watch --json --type call.ringing | while read -r line; do
  osascript -e 'tell application "Music" to pause'
done
```

### Python

```python
#!/usr/bin/env python3
"""Move every file the phone sends into ~/Inbox."""
import json, shutil, subprocess
from pathlib import Path

inbox = Path.home() / "Inbox"
inbox.mkdir(exist_ok=True)

watch = subprocess.Popen(
    ["ferret-cli", "watch", "--json", "--type", "file.received"],
    stdout=subprocess.PIPE, text=True,
)
for line in watch.stdout:
    event = json.loads(line)
    for path in event.get("paths", []):
        shutil.move(path, inbox / Path(path).name)
```

## 📜 The events

Every line has:

| Field | What it is |
|---|---|
| `v` | The schema version, `1` today |
| `type` | One of the types below |
| `at` | When, in UTC (ISO 8601) |
| `device` | `{"id", "name"}` of the device it's about, when there is one |

| `type` | Other fields |
|---|---|
| `ready` | `devices`: every paired device with `id`, `name`, `connected` (and `reconnecting`, `battery` when known). Always the first line |
| `device.connected` | |
| `device.disconnected` | |
| `device.reconnecting` | The connection dropped and Ferret is dialing it again |
| `battery` | `percent` (0-100). Phones report it in 5% steps, every percent under 20% |
| `clipboard.received` | `kind` (`text` or `image`), `sensitive` when the phone marked it private. `text` with `--include-content` |
| `file.received` | `files`, `bytes`, and `paths` |
| `notification.received` | `app`, and `title`. `text` with `--include-content` |
| `call.ringing` | `caller`: the contact's name, or the number |
| `call.ended` | `missed`: true when nobody answered |
| `transfer.progress` | `id`, `direction` (`incoming` or `outgoing`), `bytes`, `total`. About once a second |
| `transfer.done` | `id`, `direction`, `result` (`done`, `failed` or `cancelled`), `files`, `bytes` |
| `action.run` | A device ran one of this computer's actions: `action`, `result`, `exit_code` |

Version 1 stays version 1. New fields and new types may show up, so ignore what you don't know. A field never changes meaning or disappears without a new `v`.

🙈 **Private stays private.** When **Show previews on this computer** is off for a phone, its events keep the facts (`app`, `files`, `bytes`) and drop the names (`title`, `caller`, `paths`). Text from a clip the phone marked private, and a one-time code a notification hid, never show up, not even with `--include-content`.

## 🪝 Hooks

No script running all day? Let Ferret run one for you.

Put an executable named after the event in the hooks folder:

```sh
mkdir -p ~/.sofluffy/ferret/hooks
cat > ~/.sofluffy/ferret/hooks/device.connected <<'EOF'
#!/bin/sh
# Say hi when a device connects.
say "$FERRET_DEVICE_NAME is here"
EOF
chmod +x ~/.sofluffy/ferret/hooks/device.connected
```

Easy, right? Ferret runs it each time, with:

- The event's JSON on stdin, exactly like `watch --json` prints it.
- `FERRET_EVENT`, `FERRET_EVENT_VERSION`, `FERRET_DEVICE_ID` and `FERRET_DEVICE_NAME` in the environment.

A hook in Python reads its event like this:

```python
#!/usr/bin/env python3
import json, sys

event = json.load(sys.stdin)
if event["type"] == "battery" and event["percent"] <= 15:
    print(f"{event['device']['name']} needs a charger")
```

The rules:

- 🛑 **Off unless you add one.** No file, nothing runs. It must be executable, and only you may change it: Ferret skips a hook other users can write to.
- ⏱️ **10 seconds each.** A hook that runs longer is stopped.
- 🚶 **One at a time.** Runs of the same hook wait for each other. More than 4 waiting? Ferret skips the newest, so a burst can't pile up.
- 🙈 **No content, ever.** Hooks never get copied text or notification text, and get no names while previews from that device are off.
- 👤 **They run as you**, in the hooks folder, like anything else you start.

On Windows, name it `device.connected.cmd`, `.bat` or `.exe`. The folder is `%USERPROFILE%\.sofluffy\ferret\hooks`.

**Settings → Other apps → Scripts** shows the folder and which hooks Ferret found.

## 🔔 Notices from your scripts

`ferret-cli notify` puts a notice on another device:

```sh
make test && ferret-cli notify "Pixel 7" "Tests passed" || ferret-cli notify "Pixel 7" "Tests failed"
```

A script shouldn't be able to put words on your phone's screen without you saying so. So it's **off** until you turn it on, per computer: on the phone, open the computer in Ferret and turn on **Let scripts on MacBook show notices here**.

The notice says where it came from: **Tests passed · MacBook**. At most 6 a minute get through from one computer. Titles stop at 120 characters, the body at 500.

## 🤖 Tasker (Android)

Ferret is a Tasker plugin.

1. In a Tasker task, tap **+** → **Plugin** → **Ferret**.
2. Pick what to do: **Send text to your devices**, **Ring a device**, **Open a link on a device**, **Run a computer action** or **Show a notice on a device**.
3. Type the device's name, and the text, link or action. Tasker variables work: `%CLIP` sends what you copied.
4. Tap **Save**. That's it.

Ferret starts if it isn't running. If something doesn't work, such as the computer being away, a notice says why.

Only actions you made in Ferret's own Tasker screen run. Each one carries a secret this install made, so another app can't fire Ferret's plugin to make it act.

Want Tasker to react to Ferret, such as when your computer connects? Run `ferret-cli watch` or a hook on the computer for now.

## 🍎 Shortcuts (iPhone)

Open the **Shortcuts** app and search for Ferret:

- **Send Clipboard**: to one device, or every connected one.
- **Ring Device**
- **Send File**: works with files from the share sheet or other actions.
- **Open Link on Device**

Siri knows **"Send clipboard with Ferret"** and **"Ring my device with Ferret"**.

iOS only lets Ferret reach your devices while it's open, so each action opens Ferret for a moment. The device list in Shortcuts is the one Ferret last saw, so open Ferret once after pairing a new device.

## 🔒 How it stays yours

- The running app listens on **loopback only** (127.0.0.1), on a random port.
- It writes the port and a one-time secret to `~/.sofluffy/ferret/app_control.json`, readable only by you. A request without that secret gets nothing.
- Nothing listens on your network for scripts. Your devices still talk to each other only after pairing, end-to-end encrypted.
- Hooks and `ferret-cli` run as you, with your rights. Nothing more.

## 📱 Limits

| | |
|---|---|
| macOS, Windows, Linux | `ferret-cli watch`, hooks, `open`, `notify`, all of it. The Ferret app must be running |
| `ferret-cli daemon` | Doesn't stream events yet: use the app |
| Android | Tasker actions. No `ferret-cli` on the phone |
| iPhone | Shortcuts actions, which open Ferret. No background events |

## Happy Coding 🦊
