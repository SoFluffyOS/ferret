#include "input_builder.h"

namespace ferret_remote_input {

namespace {

INPUT MouseInput(DWORD flags, LONG dx = 0, LONG dy = 0, DWORD data = 0) {
  INPUT input = {};
  input.type = INPUT_MOUSE;
  input.mi.dx = dx;
  input.mi.dy = dy;
  input.mi.mouseData = data;
  input.mi.dwFlags = flags;
  return input;
}

INPUT KeyInput(WORD virtual_key, bool pressed) {
  INPUT input = {};
  input.type = INPUT_KEYBOARD;
  input.ki.wVk = virtual_key;
  input.ki.wScan = static_cast<WORD>(MapVirtualKeyW(virtual_key, MAPVK_VK_TO_VSC));
  input.ki.dwFlags = 0;
  if (IsExtendedKey(virtual_key)) {
    input.ki.dwFlags |= KEYEVENTF_EXTENDEDKEY;
  }
  if (!pressed) {
    input.ki.dwFlags |= KEYEVENTF_KEYUP;
  }
  return input;
}

INPUT UnicodeInput(wchar_t unit, bool pressed) {
  INPUT input = {};
  input.type = INPUT_KEYBOARD;
  input.ki.wVk = 0;
  input.ki.wScan = static_cast<WORD>(unit);
  input.ki.dwFlags = KEYEVENTF_UNICODE;
  if (!pressed) {
    input.ki.dwFlags |= KEYEVENTF_KEYUP;
  }
  return input;
}

LONG Clamp(int64_t value) {
  constexpr int64_t kLimit = 1 << 20;
  if (value > kLimit) {
    return static_cast<LONG>(kLimit);
  }
  if (value < -kLimit) {
    return static_cast<LONG>(-kLimit);
  }
  return static_cast<LONG>(value);
}

}  // namespace

bool IsExtendedKey(WORD virtual_key) {
  switch (virtual_key) {
    case VK_LEFT:
    case VK_RIGHT:
    case VK_UP:
    case VK_DOWN:
    case VK_HOME:
    case VK_END:
    case VK_PRIOR:
    case VK_NEXT:
    case VK_INSERT:
    case VK_DELETE:
    case VK_LWIN:
    case VK_RWIN:
    case VK_RCONTROL:
    case VK_RMENU:
    case VK_MEDIA_PLAY_PAUSE:
    case VK_MEDIA_NEXT_TRACK:
    case VK_MEDIA_PREV_TRACK:
    case VK_VOLUME_MUTE:
    case VK_VOLUME_DOWN:
    case VK_VOLUME_UP:
      return true;
    default:
      return false;
  }
}

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) {
    return std::wstring();
  }
  const int length = MultiByteToWideChar(CP_UTF8, 0, utf8.data(),
                                         static_cast<int>(utf8.size()), nullptr, 0);
  if (length <= 0) {
    return std::wstring();
  }
  std::wstring wide(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                      wide.data(), length);
  return wide;
}

std::vector<INPUT> InputBuilder::Build(const NativeInputEvent& event) {
  switch (event.kind()) {
    case NativeEventKind::kMove:
      return Move(event.x(), event.y());
    case NativeEventKind::kButton:
      return Button(event.code(), event.pressed());
    case NativeEventKind::kScroll:
      return Scroll(event.x(), event.y());
    case NativeEventKind::kKey:
      return Key(static_cast<WORD>(event.code()), event.pressed());
    case NativeEventKind::kText:
      if (event.text() == nullptr) {
        return {};
      }
      return Text(*event.text());
    case NativeEventKind::kMediaKey:
      return {};
  }
  return {};
}

std::vector<INPUT> InputBuilder::ReleaseAll() {
  std::vector<INPUT> inputs;
  const std::set<int64_t> buttons = held_buttons_;
  for (int64_t button : buttons) {
    std::vector<INPUT> release = Button(button, false);
    inputs.insert(inputs.end(), release.begin(), release.end());
  }
  const std::set<WORD> keys = held_keys_;
  for (WORD key : keys) {
    std::vector<INPUT> release = Key(key, false);
    inputs.insert(inputs.end(), release.begin(), release.end());
  }
  held_buttons_.clear();
  held_keys_.clear();
  return inputs;
}

std::vector<INPUT> InputBuilder::Move(int64_t dx, int64_t dy) {
  if (dx == 0 && dy == 0) {
    return {};
  }
  return {MouseInput(MOUSEEVENTF_MOVE, Clamp(dx), Clamp(dy))};
}

std::vector<INPUT> InputBuilder::Button(int64_t button, bool pressed) {
  DWORD flags = 0;
  switch (button) {
    case 1:
      flags = pressed ? MOUSEEVENTF_RIGHTDOWN : MOUSEEVENTF_RIGHTUP;
      break;
    case 2:
      flags = pressed ? MOUSEEVENTF_MIDDLEDOWN : MOUSEEVENTF_MIDDLEUP;
      break;
    default:
      button = 0;
      flags = pressed ? MOUSEEVENTF_LEFTDOWN : MOUSEEVENTF_LEFTUP;
      break;
  }
  if (pressed) {
    held_buttons_.insert(button);
  } else {
    held_buttons_.erase(button);
  }
  return {MouseInput(flags)};
}

std::vector<INPUT> InputBuilder::Scroll(int64_t dx, int64_t dy) {
  std::vector<INPUT> inputs;
  // A wheel turned away from the person (positive) scrolls up, so a
  // scroll down is negative. Windows takes fractions of a notch.
  const int64_t vertical = -dy * WHEEL_DELTA / kPixelsPerNotch;
  const int64_t horizontal = dx * WHEEL_DELTA / kPixelsPerNotch;
  if (vertical != 0) {
    inputs.push_back(MouseInput(MOUSEEVENTF_WHEEL, 0, 0,
                                static_cast<DWORD>(Clamp(vertical))));
  }
  if (horizontal != 0) {
    inputs.push_back(MouseInput(MOUSEEVENTF_HWHEEL, 0, 0,
                                static_cast<DWORD>(Clamp(horizontal))));
  }
  return inputs;
}

std::vector<INPUT> InputBuilder::Key(WORD virtual_key, bool pressed) {
  if (virtual_key == 0) {
    return {};
  }
  if (pressed) {
    held_keys_.insert(virtual_key);
  } else {
    held_keys_.erase(virtual_key);
  }
  return {KeyInput(virtual_key, pressed)};
}

std::vector<INPUT> InputBuilder::Text(const std::string& utf8) {
  std::vector<INPUT> inputs;
  for (wchar_t unit : Utf8ToWide(utf8)) {
    if (unit == L'\r') {
      continue;
    }
    if (unit == L'\n' || unit == L'\t') {
      const WORD key = static_cast<WORD>(unit == L'\n' ? VK_RETURN : VK_TAB);
      inputs.push_back(KeyInput(key, true));
      inputs.push_back(KeyInput(key, false));
      continue;
    }
    inputs.push_back(UnicodeInput(unit, true));
    inputs.push_back(UnicodeInput(unit, false));
  }
  return inputs;
}

}  // namespace ferret_remote_input
