#include <gtest/gtest.h>
#include <windows.h>

#include <cstring>
#include <vector>

#include "image_codec.h"

namespace ferret_clipboard {
namespace test {

namespace {

// A 2x2 bottom-up 32-bit DIB, the shape Windows puts on the clipboard.
std::vector<uint8_t> TinyDib() {
  BITMAPINFOHEADER header = {};
  header.biSize = sizeof(header);
  header.biWidth = 2;
  header.biHeight = 2;
  header.biPlanes = 1;
  header.biBitCount = 32;
  header.biCompression = BI_RGB;

  std::vector<uint8_t> dib(sizeof(header) + 2 * 2 * 4, 0x7f);
  std::memcpy(dib.data(), &header, sizeof(header));
  return dib;
}

class ImageCodecTest : public ::testing::Test {
 protected:
  void SetUp() override { CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED); }
  void TearDown() override { CoUninitialize(); }
};

}  // namespace

TEST_F(ImageCodecTest, DibBecomesPng) {
  std::vector<uint8_t> dib = TinyDib();

  std::optional<std::vector<uint8_t>> png = DibToPng(dib.data(), dib.size());

  ASSERT_TRUE(png.has_value());
  ASSERT_GT(png->size(), 8u);
  EXPECT_EQ((*png)[1], 'P');
  EXPECT_EQ((*png)[2], 'N');
  EXPECT_EQ((*png)[3], 'G');
}

TEST_F(ImageCodecTest, PngBecomesDibWithTheSameSize) {
  std::vector<uint8_t> dib = TinyDib();
  std::optional<std::vector<uint8_t>> png = DibToPng(dib.data(), dib.size());
  ASSERT_TRUE(png.has_value());

  std::optional<std::vector<uint8_t>> back = ImageToDib(*png);

  ASSERT_TRUE(back.has_value());
  BITMAPINFOHEADER header;
  std::memcpy(&header, back->data(), sizeof(header));
  EXPECT_EQ(header.biWidth, 2);
  EXPECT_EQ(header.biHeight, 2);
  EXPECT_EQ(header.biBitCount, 32);
}

TEST_F(ImageCodecTest, GarbageIsRefused) {
  std::vector<uint8_t> garbage = {1, 2, 3};

  EXPECT_FALSE(ImageToPng(garbage).has_value());
  EXPECT_FALSE(DibToPng(garbage.data(), garbage.size()).has_value());
}

}  // namespace test
}  // namespace ferret_clipboard
