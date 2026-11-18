#include <gtest/gtest.h>
#include <windows.h>

#include <string>

#include "ferret_drop_plugin.h"

namespace ferret_drop {
namespace test {

TEST(FerretDropPlugin, CannotSaveToDownloads) {
  FerretDropPlugin plugin;
  ErrorOr<bool> result = plugin.CanSaveToDownloads();

  EXPECT_FALSE(result.has_error());
  EXPECT_FALSE(result.value());
}

TEST(FerretDropPlugin, ConvertsUtf8Paths) {
  EXPECT_EQ(Utf16FromUtf8("C:\\caf\xC3\xA9.txt"), L"C:\\caf\u00e9.txt");
  EXPECT_TRUE(Utf16FromUtf8("").empty());
}

TEST(FerretDropPlugin, DoesNotOpenMissingFiles) {
  FerretDropPlugin plugin;
  ErrorOr<bool> result = plugin.Open("C:\\no\\such\\ferret\\file.txt", "");

  EXPECT_FALSE(result.has_error());
  EXPECT_FALSE(result.value());
}

}  // namespace test
}  // namespace ferret_drop
