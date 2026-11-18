#include <gtest/gtest.h>
#include <windows.h>

#include <string>

#include "app_names.h"

namespace ferret_media {
namespace test {

TEST(AppNames, StripsExecutableSuffix) {
  EXPECT_EQ(AppNameFor("Spotify.exe"), "Spotify");
}

TEST(AppNames, ReadsPackagedApps) {
  EXPECT_EQ(AppNameFor("Microsoft.ZuneMusic_8wekyb3d8bbwe!Microsoft.ZuneMusic"),
            "Media Player");
}

TEST(AppNames, KeepsUnknownNames) {
  EXPECT_EQ(AppNameFor("Foobar2000.exe"), "Foobar2000");
}

}  // namespace test
}  // namespace ferret_media
