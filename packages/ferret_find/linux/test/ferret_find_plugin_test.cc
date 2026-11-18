#include <flutter_linux/flutter_linux.h>
#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "include/ferret_find/ferret_find_plugin.h"
#include "ferret_find_plugin_private.h"

// This demonstrates a simple unit test of the C portion of this plugin's
// implementation.
//
// Once you have built the plugin's example app, you can run these tests
// from the command line. For instance, for an x64 debug build, run
// $ build/linux/x64/debug/plugins/ferret_find/ferret_find_test

namespace ferret_find {
namespace test {

TEST(FerretFindPlugin, GetPlatformVersion) {
  g_autofree gchar* result = ferret_find_plugin_get_platform_version();
  ASSERT_NE(result, nullptr);
  // The full string varies, so just validate that it has the right format.
  EXPECT_THAT(result, testing::StartsWith("Linux "));
}

}  // namespace test
}  // namespace ferret_find
