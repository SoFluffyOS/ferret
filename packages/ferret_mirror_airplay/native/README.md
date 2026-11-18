# native

C code compiled by `hook/build.dart` (Dart build hooks, `native_toolchain_c`) into one dynamic library, `ferret_playfair`, that ships with the app as a native asset.

## playfair/

The **playfair** library: the reverse-engineered FairPlay step of AirPlay (`fp-setup`), which turns the 72-byte key an iPhone sends into the 16-byte AES key of the session.

- **Licence:** GPL-3.0, see [playfair/LICENSE.md](playfair/LICENSE.md). Ferret is GPL-3.0 too.
- **Where it comes from:** [EstebanKubata's playfair](https://github.com/EstebanKubata/playfair), carried since by [RPiPlay](https://github.com/FD-/RPiPlay) and [UxPlay](https://github.com/FDH2/UxPlay). These files were copied from UxPlay's `lib/playfair` at commit `48f5ce47c9ef694afccfac907c9e8828329657fe`.
- **Unmodified.** Every file is byte for byte what UxPlay ships. Don't edit them; to update, copy the folder again and note the new commit here.

`CMakeLists.txt` from upstream is left out: the build hook lists the sources itself.

## ferret_playfair.c

Ours. Ten lines that export `ferret_playfair_decrypt` (Windows needs `__declspec(dllexport)`), so playfair itself stays untouched.

## One thing to know

playfair trusts its input. Byte 12 of the 164-byte FairPlay message picks one of four tables, and a value of 4 or more reads past them. That message comes from the network, so the Dart side (`playfairDecrypt`, `FairPlaySession`) refuses such a message before the C code ever sees it. With that check, 200,000 random inputs ran clean under AddressSanitizer.
