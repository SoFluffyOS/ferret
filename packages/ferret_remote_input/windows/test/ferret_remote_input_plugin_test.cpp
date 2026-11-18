#include <gtest/gtest.h>
#include <windows.h>

#include <string>
#include <vector>

#include "input_builder.h"
#include "messages.g.h"

namespace ferret_remote_input {
namespace test {

namespace {

NativeInputEvent Event(NativeEventKind kind, int64_t x, int64_t y, int64_t code,
                       bool pressed) {
  return NativeInputEvent(kind, x, y, code, pressed, 0);
}

}  // namespace

TEST(InputBuilder, MoveIsRelative) {
  InputBuilder builder;
  std::vector<INPUT> inputs =
      builder.Build(Event(NativeEventKind::kMove, 12, -5, 0, false));

  ASSERT_EQ(inputs.size(), 1u);
  EXPECT_EQ(inputs[0].type, static_cast<DWORD>(INPUT_MOUSE));
  EXPECT_EQ(inputs[0].mi.dwFlags, static_cast<DWORD>(MOUSEEVENTF_MOVE));
  EXPECT_EQ(inputs[0].mi.dx, 12);
  EXPECT_EQ(inputs[0].mi.dy, -5);
}

TEST(InputBuilder, ScrollDownIsANegativeWheel) {
  InputBuilder builder;
  std::vector<INPUT> inputs = builder.Build(
      Event(NativeEventKind::kScroll, 0, kPixelsPerNotch, 0, false));

  ASSERT_EQ(inputs.size(), 1u);
  EXPECT_EQ(inputs[0].mi.dwFlags, static_cast<DWORD>(MOUSEEVENTF_WHEEL));
  EXPECT_EQ(static_cast<LONG>(inputs[0].mi.mouseData), -WHEEL_DELTA);
}

TEST(InputBuilder, ReleaseAllLetsGoOfHeldButtonsAndKeys) {
  InputBuilder builder;
  builder.Build(Event(NativeEventKind::kButton, 0, 0, 0, true));
  builder.Build(Event(NativeEventKind::kKey, 0, 0, VK_LEFT, true));

  std::vector<INPUT> releases = builder.ReleaseAll();

  ASSERT_EQ(releases.size(), 2u);
  EXPECT_EQ(releases[0].mi.dwFlags, static_cast<DWORD>(MOUSEEVENTF_LEFTUP));
  EXPECT_EQ(releases[1].ki.wVk, VK_LEFT);
  EXPECT_NE(releases[1].ki.dwFlags & KEYEVENTF_KEYUP, 0u);
  EXPECT_NE(releases[1].ki.dwFlags & KEYEVENTF_EXTENDEDKEY, 0u);
  EXPECT_TRUE(builder.ReleaseAll().empty());
}

TEST(InputBuilder, TextIsTypedAsUnicode) {
  InputBuilder builder;
  NativeInputEvent event(NativeEventKind::kText, 0, 0, 0, false, 0);
  event.set_text("h\xC3\xA9\n");

  std::vector<INPUT> inputs = builder.Build(event);

  ASSERT_EQ(inputs.size(), 6u);
  EXPECT_EQ(inputs[0].ki.wScan, L'h');
  EXPECT_NE(inputs[0].ki.dwFlags & KEYEVENTF_UNICODE, 0u);
  EXPECT_EQ(inputs[2].ki.wScan, static_cast<WORD>(0x00E9));
  EXPECT_EQ(inputs[4].ki.wVk, VK_RETURN);
}

}  // namespace test
}  // namespace ferret_remote_input
