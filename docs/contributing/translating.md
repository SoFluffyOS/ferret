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
| The app | `modules/<module>/lib/l10n/arb/<module>_en.arb`, one per module (20 of them) |
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
cd modules/shell && flutter gen-l10n
```

A key you haven't translated yet shows in English. That's fine for a first pull request.

## 🇻🇳 Vietnamese word list

Write it the way you'd explain it to your parents: everyday words, short sentences, "bạn" for the reader. Translate what the English means, not word by word. When the English changes, check that the Vietnamese still says the same thing.

Spell tones the way iPhone and Android do: **hủy, xóa, khóa, hòa, khỏe** (not huỷ, xoá).

| English | Tiếng Việt |
|---|---|
| device · computer · phone | thiết bị · máy tính · điện thoại |
| this Mac · this PC · this computer | máy Mac này · máy tính này · máy tính này |
| pair · paired | ghép đôi · đã ghép đôi (never "ghép nối") |
| Add a device | Thêm thiết bị |
| Nearby (Ferret's list) | Lân cận |
| Nearby devices (Android permission) | Thiết bị ở gần (Android's own name) |
| clipboard · Recent clips | bảng nhớ tạm · Mục đã chép gần đây |
| Send automatically | Tự động gửi |
| shelf · Keep copies | kệ tạm · Giữ bản sao |
| Activity · Needs you | Hoạt động · Cần bạn xử lý |
| notice, notification | thông báo |
| Show screen (on the computer) | Xem màn hình |
| second display | màn hình phụ |
| receive folder | thư mục nhận |
| Fix connection | Sửa kết nối |
| Stay connected · Reach away from home | Giữ kết nối · Kết nối khi ở xa |
| Pause · Paused | Tạm dừng · Đã tạm dừng |
| Actions · Wake · Ring | Thao tác · Đánh thức · Đổ chuông |
| Quick Settings · tile | Cài đặt nhanh · ô |
| Settings · System Settings | Cài đặt · Cài đặt hệ thống |
| Accessibility on a Mac · on Android | Trợ năng · Hỗ trợ tiếp cận (each system's own name) |
| Check for updates · Install · What's new | Kiểm tra cập nhật · Cài đặt · Có gì mới |
| tap (phone) · click (computer) | nhấn · nhấp |
| Cancel · Done · Not now · Try again · Don't allow | Hủy · Xong · Để sau · Thử lại · Từ chối |
| Remove · Delete · Dismiss | Gỡ · Xóa · Đóng |
| Show · Show in Finder | Hiện · Hiện trong Finder |
| camera · photo | camera · ảnh |

Keep names as they are: Ferret, Mac, iPhone, Wi-Fi, Bluetooth, AirPlay, Quick Share, LocalSend, Shizuku, Beta. Buttons stay short (two or three words); the detail goes in the line under it or in the tooltip.

## 📱 Native strings

Android: copy `res/values/strings.xml` (and `ferret_handoff_strings.xml`, `ferret_find_strings.xml`; `ferret_phone_control` names the Accessibility service Android lists in its settings) into `res/values-de/` in the same package, and add `<locale android:name="de" />` to `locales_config.xml`.

Apple: open the `.xcstrings` files in Xcode and add your language, or add a `"de"` entry next to `"vi"` by hand. Add `de` to `CFBundleLocalizations` in both `Runner/Info.plist`.

## ✅ Check it

```bash
cd apps/ferret
flutter test test/l10n                        # same keys, placeholders kept, no English typed into widgets
dart run tool/pseudo_l10n.dart
flutter test test/screens/l10n_screens_test.dart
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
