import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// Compiles the vendored playfair sources (FairPlay key decryption) into a
/// dynamic library that ships with the app as a native asset.
void main(List<String> arguments) async {
  await build(arguments, (input, output) async {
    final builder = CBuilder.library(
      name: 'ferret_playfair',
      assetName: 'src/fairplay/playfair_bindings.dart',
      sources: const [
        'native/ferret_playfair.c',
        'native/playfair/hand_garble.c',
        'native/playfair/modified_md5.c',
        'native/playfair/omg_hax.c',
        'native/playfair/playfair.c',
        'native/playfair/sap_hash.c',
      ],
    );

    await builder.run(input: input, output: output);
  });
}
