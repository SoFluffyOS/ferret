---
order: 4
---
# iPhone on macOS

On a Mac, your iPhone already does more with macOS than Ferret can: iPhone notifications, calls, messages and handoff are built in. Use those.

Ferret's iPhone link is there on macOS too, in **beta**.

## 🧪 What to expect

macOS decides what a normal app may see of an iPhone over Bluetooth. Ferret can only talk to an iPhone that macOS itself is connected to, and macOS may keep the iPhone's notification service to itself.

So:

- Ferret lists an iPhone only when macOS reports one that offers its notification or media service.
- If the list stays empty, macOS isn't sharing it. There's no setting for that.
- If the iPhone connects but Ferret says it **isn't sharing**, same reason.

We built it, it compiles and runs, and we have not yet confirmed it against a real iPhone. If it works on your Mac, tell us the macOS and iOS versions.

## 🔑 Try it

1. In Ferret, open **Settings → Other apps** and turn on **Connect an iPhone**.
2. macOS asks to let Ferret use Bluetooth. **Allow**.
3. Keep the iPhone unlocked and next to the Mac, Bluetooth on.
4. Tap **Look again**. If the iPhone shows up, tap **Use**.

Said no to Bluetooth by mistake? Open **System Settings → Privacy & Security → Bluetooth** and turn Ferret on.
