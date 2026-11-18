#ifndef FLUTTER_PLUGIN_FERRET_REMOTE_INPUT_INPUT_BUILDER_H_
#define FLUTTER_PLUGIN_FERRET_REMOTE_INPUT_INPUT_BUILDER_H_

// This must be included before many other Windows headers.
#include <windows.h>

#include <set>
#include <string>
#include <vector>

#include "messages.g.h"

namespace ferret_remote_input {

// Pixels of scrolling per wheel notch (WHEEL_DELTA).
constexpr int kPixelsPerNotch = 40;

// Turns Ferret's native events into SendInput records, and remembers what
// it holds down so ReleaseAll can let go of it. Builds records only, so
// tests can check them without moving the real pointer.
class InputBuilder {
 public:
  std::vector<INPUT> Build(const NativeInputEvent& event);

  // Releases for every button and key still held, then forgets them.
  std::vector<INPUT> ReleaseAll();

 private:
  std::vector<INPUT> Move(int64_t dx, int64_t dy);
  std::vector<INPUT> Button(int64_t button, bool pressed);
  std::vector<INPUT> Scroll(int64_t dx, int64_t dy);
  std::vector<INPUT> Key(WORD virtual_key, bool pressed);
  std::vector<INPUT> Text(const std::string& utf8);

  std::set<int64_t> held_buttons_;
  std::set<WORD> held_keys_;
};

// Keys that need KEYEVENTF_EXTENDEDKEY, or Windows reads them as their
// numeric keypad twins.
bool IsExtendedKey(WORD virtual_key);

std::wstring Utf8ToWide(const std::string& utf8);

}  // namespace ferret_remote_input

#endif  // FLUTTER_PLUGIN_FERRET_REMOTE_INPUT_INPUT_BUILDER_H_
