#ifndef FLUTTER_PLUGIN_FERRET_CLIPBOARD_IMAGE_CODEC_H_
#define FLUTTER_PLUGIN_FERRET_CLIPBOARD_IMAGE_CODEC_H_

#include <windows.h>

#include <cstdint>
#include <optional>
#include <vector>

namespace ferret_clipboard {

// Converts a CF_DIB or CF_DIBV5 block (a BITMAPINFO header, an optional
// colour table and the pixels) to PNG bytes.
std::optional<std::vector<uint8_t>> DibToPng(const uint8_t* dib, size_t size);

// Re-encodes any image Windows Imaging Component can decode (PNG, JPEG, GIF,
// BMP, TIFF) as PNG.
std::optional<std::vector<uint8_t>> ImageToPng(const std::vector<uint8_t>& image);

// Decodes an image to a bottom-up 32-bit CF_DIB block, for apps that only
// paste bitmaps.
std::optional<std::vector<uint8_t>> ImageToDib(const std::vector<uint8_t>& image);

}  // namespace ferret_clipboard

#endif  // FLUTTER_PLUGIN_FERRET_CLIPBOARD_IMAGE_CODEC_H_
