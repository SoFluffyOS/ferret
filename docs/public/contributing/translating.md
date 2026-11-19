# Translate Ferret

Ferret speaks English and Vietnamese. Every other language is one folder of text files away, and you don't need to write any code to add one.

> TL;DR
> 1. Copy each `modules/<module>/lib/l10n/arb/<module>_en.arb` to `<module>_<language>.arb`.
> 2. Translate the values, keep the keys and everything in `{braces}`.
> 3. Add the native strings (Android `values-<language>`, Apple `.xcstrings`).
> 4. Run the checks and the renders, then open a pull request.

## 🗂️ Where the words live

Every feature keeps its own strings, next to its code:

| What | Where |
|---|---|
| The app | `modules/<module>/lib/l10n/arb/<module>_en.arb`, one per module (13 of them) |
| Android notices, the Quick Settings tile, share targets | `packages/ferret_<capability>/android/src/main/res/values/*.xml` |
| iPhone and Mac share sheets | `apps/ferret/ios/Share/Localizable.xcstrings`, `apps/ferret/macos/Share/Localizable.xcstrings` |
| Permission prompts (camera, local network, Accessibility…) | `apps/ferret/ios/Runner/InfoPlist.xcstrings`, `apps/ferret/macos/Runner/InfoPlist.xcstrings` |
| Which languages the system offers for Ferret | `apps/ferret/android/app/src/main/res/xml/locales_config.xml`, `CFBundleLocalizations` in both `Runner/Info.plist` |

The English file is the source. Its `@key` entries say where a string shows up and what fills each `{placeholder}`. Read them before you translate a short word like **Show** or **Clear**.

`ferret-cli` stays in English: it is a tool for scripts, and its output is meant to be parsed.

## ✍️ Translate a module

Copy `shell_en.arb` to `shell_de.arb` and start it like this:

```json
{
  "@@locale": "de",
  "@@x-translation": "Translated by <your name>",
  "homeYourDevices": "Deine Geräte"
}
```

- Same keys, same order. Leave out the `@key` blocks; they stay in English.
- Keep every `{name}`. Move it where your grammar wants it.
- Counts are ICU plurals. Translate the text inside each branch and keep the words `plural`, `other`, `=1`:

```json
"menubarTipConnected": "Ferret · {count, plural, =1{1 Gerät verbunden} other{{count} Geräte verbunden}}"
```

- Your language needs more forms (`few`, `many`)? Add them. No plural at all? Keep only `other`.
- `{here, select, mac{this Mac} phone{this phone} …}` spells this device inside the sentence. Translate each branch in the form that sentence needs (German: **diesen Mac** here, **diesem Mac** there), and keep the branch names and `other`.
- Names in a row ("Pixel 7, iPad") are joined in code with your language's comma: `、` for Japanese and Chinese, `،` for Arabic, Persian and Urdu, `, ` otherwise. Yours differs? Add it to `ListText` in `packages/feature_kit/lib/services/list_text.dart`.
- Used a machine to help? Say so in `@@x-translation`. The Vietnamese files do.

Then generate the Dart code for each module:

```bash
cd modules/shell && fvm flutter gen-l10n
```

A key you haven't translated yet shows in English. That's fine for a first pull request.

## 📱 Native strings

Android: copy `res/values/strings.xml` (and `ferret_handoff_strings.xml`, `ferret_find_strings.xml`) into `res/values-de/` in the same package, and add `<locale android:name="de" />` to `locales_config.xml`.

Apple: open the `.xcstrings` files in Xcode and add your language, or add a `"de"` entry next to `"vi"` by hand. Add `de` to `CFBundleLocalizations` in both `Runner/Info.plist`.

## ✅ Check it

```bash
cd apps/ferret
fvm flutter test test/l10n                    # same keys, placeholders kept, no English typed into widgets
fvm dart run tool/pseudo_l10n.dart
fvm flutter test test/screens/l10n_screens_test.dart
```

The last one renders the main screens into `temp/screens` three ways:

- `l10n_vi_*`: Vietnamese, the way a real translation looks.
- `l10n_pseudo_*`: every string accented, 40% longer and in `[brackets]`. Text without brackets is still English; a cut-off label won't fit German either.
- `l10n_rtl_*`: the same, right to left, the way Arabic and Hebrew lay out.

`temp/screens/l10n_report.txt` lists what it found.

To see your language in the app, open **Settings → Advanced → Language** and pick it. Ferret shows it right away. Menus, the tray icon and notifications switch the next time Ferret starts.

## 🧑‍💻 For developers

- Every string a person reads goes through `context.<module>L10n`. Outside a widget, use the module's `platform<Module>L10n()`; it follows the language picked in Settings.
- Never glue sentences: `'${l10n.notSent}. ${reason}'` breaks in languages with another word order. Add one string with a `{reason}` placeholder.
- A number of things is a plural, even when English looks fine without one.
- Dates and numbers go through `intl` with the current locale (`DateFormat.jm(locale)`, `NumberFormat`), never by hand.
- Padding, alignment and arrows that point somewhere use the directional forms: `EdgeInsetsDirectional`, `AlignmentDirectional`, `DirectionalIcon` for back and "opens a page" chevrons.
- `test/l10n/strings_lint_test.dart` fails on English typed into a widget. If a literal really isn't a word to translate, add it to its allowlist with a reason.
