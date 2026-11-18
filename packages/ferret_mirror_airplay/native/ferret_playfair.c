// Exports the one FairPlay entry point Dart calls, so the vendored playfair
// sources stay byte for byte as upstream ships them.
#include "playfair/playfair.h"

#if defined(_WIN32)
#define FERRET_EXPORT __declspec(dllexport)
#else
#define FERRET_EXPORT __attribute__((visibility("default")))
#endif

FERRET_EXPORT void ferret_playfair_decrypt(unsigned char* message3,
                                           unsigned char* cipher_text,
                                           unsigned char* key_out) {
  playfair_decrypt(message3, cipher_text, key_out);
}
