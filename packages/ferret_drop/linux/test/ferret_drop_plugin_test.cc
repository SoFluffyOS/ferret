#include <flutter_linux/flutter_linux.h>
#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "include/ferret_drop/ferret_drop_plugin.h"
#include "ferret_drop_plugin_private.h"

namespace ferret_drop {
namespace test {

TEST(FerretDropPlugin, HasNoUriForMissingFiles) {
  EXPECT_EQ(ferret_drop_plugin_uri_for_existing_file(
                "/no/such/ferret/file.txt"),
            nullptr);
  EXPECT_EQ(ferret_drop_plugin_uri_for_existing_file(nullptr), nullptr);
}

TEST(FerretDropPlugin, BuildsFileUris) {
  g_autofree gchar* uri = ferret_drop_plugin_uri_for_existing_file("/");
  ASSERT_NE(uri, nullptr);
  EXPECT_THAT(uri, testing::StartsWith("file:///"));
}

}  // namespace test
}  // namespace ferret_drop
