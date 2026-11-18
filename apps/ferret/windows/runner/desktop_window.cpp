#include "desktop_window.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>

#include "resource.h"

namespace {

constexpr char kChannel[] = "io.sofluffy.ferret/desktop";
constexpr wchar_t kKey[] = L"Software\\SoFluffy\\Ferret";
constexpr wchar_t kPlacementValue[] = L"WindowPlacement";
constexpr UINT kTrayMessage = WM_APP + 7;
constexpr UINT kTrayId = 1;

std::wstring Utf16FromUtf8(const std::string& text) {
  if (text.empty()) {
    return std::wstring();
  }
  int length = ::MultiByteToWideChar(CP_UTF8, 0, text.data(),
                                     static_cast<int>(text.size()), nullptr, 0);
  std::wstring wide(static_cast<size_t>(length), L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                        wide.data(), length);
  return wide;
}

const flutter::EncodableValue* Lookup(const flutter::EncodableMap& map,
                                      const char* key) {
  auto found = map.find(flutter::EncodableValue(key));
  if (found == map.end()) {
    return nullptr;
  }
  return &found->second;
}

bool BoolOf(const flutter::EncodableMap& map, const char* key) {
  const flutter::EncodableValue* value = Lookup(map, key);
  if (value == nullptr) {
    return false;
  }
  const bool* flag = std::get_if<bool>(value);
  return flag != nullptr && *flag;
}

std::string StringOf(const flutter::EncodableMap& map, const char* key) {
  const flutter::EncodableValue* value = Lookup(map, key);
  if (value == nullptr) {
    return std::string();
  }
  const std::string* text = std::get_if<std::string>(value);
  if (text == nullptr) {
    return std::string();
  }
  return *text;
}

}  // namespace

DesktopWindow::DesktopWindow(HWND window, flutter::BinaryMessenger* messenger,
                             bool started_hidden)
    : window_(window),
      started_hidden_(started_hidden),
      taskbar_created_(::RegisterWindowMessageW(L"TaskbarCreated")) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, kChannel, &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) { OnCall(call, std::move(result)); });
}

DesktopWindow::~DesktopWindow() {
  channel_->SetMethodCallHandler(nullptr);
  RemoveTray();
}

void DesktopWindow::RestorePlacement() {
  WINDOWPLACEMENT placement = {};
  DWORD size = sizeof(placement);
  LSTATUS status =
      ::RegGetValueW(HKEY_CURRENT_USER, kKey, kPlacementValue, RRF_RT_REG_BINARY,
                     nullptr, &placement, &size);
  if (status != ERROR_SUCCESS || size != sizeof(placement) ||
      placement.length != sizeof(placement)) {
    return;
  }

  // A place on a monitor that is gone would open the window off screen.
  if (::MonitorFromRect(&placement.rcNormalPosition, MONITOR_DEFAULTTONULL) ==
      nullptr) {
    return;
  }

  show_maximized_ = placement.showCmd == SW_SHOWMAXIMIZED;
  placement.showCmd = SW_HIDE;
  placement.flags = 0;
  ::SetWindowPlacement(window_, &placement);
}

void DesktopWindow::ShowAtStart() {
  if (started_hidden_) {
    return;
  }
  ::ShowWindow(window_, show_maximized_ ? SW_SHOWMAXIMIZED : SW_SHOWNORMAL);
}

std::optional<LRESULT> DesktopWindow::HandleMessage(UINT message,
                                                    WPARAM /*wparam*/,
                                                    LPARAM lparam) {
  if (message == WM_CLOSE) {
    SavePlacement();
    if (!hide_on_close_ || !tray_added_) {
      return std::nullopt;
    }
    Hide();
    Invoke("window.closedToTray");
    return 0;
  }

  if (message == taskbar_created_ && tray_added_) {
    // Explorer restarted and forgot the icon.
    tray_added_ = false;
    ShowIcon();
    return 0;
  }

  if (message != kTrayMessage) {
    return std::nullopt;
  }

  switch (LOWORD(lparam)) {
    case WM_LBUTTONUP:
      Invoke("tray.activate");
      return 0;
    case WM_RBUTTONUP:
    case WM_CONTEXTMENU:
      ShowTrayMenu();
      return 0;
  }
  return 0;
}

void DesktopWindow::OnCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  const flutter::EncodableMap empty;
  const flutter::EncodableMap* arguments =
      std::get_if<flutter::EncodableMap>(call.arguments());
  if (arguments == nullptr) {
    arguments = &empty;
  }

  if (method == "window.setHideOnClose") {
    hide_on_close_ = BoolOf(*arguments, "value");
  } else if (method == "window.show") {
    Show();
  } else if (method == "window.hide") {
    Hide();
  } else if (method == "window.toggle") {
    if (::IsWindowVisible(window_) && ::GetForegroundWindow() == window_) {
      Hide();
    } else {
      Show();
    }
  } else if (method == "window.quit") {
    SavePlacement();
    hide_on_close_ = false;
    ::PostMessage(window_, WM_CLOSE, 0, 0);
  } else if (method == "window.startedHidden") {
    result->Success(flutter::EncodableValue(started_hidden_));
    return;
  } else if (method == "tray.set") {
    result->Success(flutter::EncodableValue(SetTray(*arguments)));
    return;
  } else if (method == "tray.remove") {
    RemoveTray();
  } else {
    result->NotImplemented();
    return;
  }

  result->Success();
}

void DesktopWindow::Show() {
  if (::IsIconic(window_)) {
    ::ShowWindow(window_, SW_RESTORE);
  } else {
    ::ShowWindow(window_, SW_SHOW);
  }
  ::SetForegroundWindow(window_);
}

void DesktopWindow::Hide() {
  SavePlacement();
  ::ShowWindow(window_, SW_HIDE);
}

void DesktopWindow::SavePlacement() {
  if (!::IsWindowVisible(window_)) {
    return;
  }

  WINDOWPLACEMENT placement = {};
  placement.length = sizeof(placement);
  if (!::GetWindowPlacement(window_, &placement)) {
    return;
  }
  ::RegSetKeyValueW(HKEY_CURRENT_USER, kKey, kPlacementValue, REG_BINARY,
                    &placement, sizeof(placement));
}

bool DesktopWindow::SetTray(const flutter::EncodableMap& arguments) {
  std::string tooltip = StringOf(arguments, "tooltip");
  if (!tooltip.empty()) {
    tray_tooltip_ = Utf16FromUtf8(tooltip);
  }

  const flutter::EncodableValue* items_value = Lookup(arguments, "items");
  if (items_value != nullptr) {
    const flutter::EncodableList* items =
        std::get_if<flutter::EncodableList>(items_value);
    if (items != nullptr) {
      tray_items_.clear();
      for (const flutter::EncodableValue& value : *items) {
        const flutter::EncodableMap* item =
            std::get_if<flutter::EncodableMap>(&value);
        if (item == nullptr) {
          continue;
        }
        tray_items_.push_back(TrayItem{
            StringOf(*item, "id"), Utf16FromUtf8(StringOf(*item, "title")),
            BoolOf(*item, "enabled"), BoolOf(*item, "separator")});
      }
    }
  }

  return ShowIcon();
}

bool DesktopWindow::ShowIcon() {
  NOTIFYICONDATAW data = {};
  data.cbSize = sizeof(data);
  data.hWnd = window_;
  data.uID = kTrayId;
  data.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  data.uCallbackMessage = kTrayMessage;
  data.hIcon = ::LoadIconW(::GetModuleHandleW(nullptr),
                           MAKEINTRESOURCEW(IDI_APP_ICON));
  wcsncpy_s(data.szTip, tray_tooltip_.c_str(), _TRUNCATE);

  if (tray_added_) {
    return ::Shell_NotifyIconW(NIM_MODIFY, &data) == TRUE;
  }
  tray_added_ = ::Shell_NotifyIconW(NIM_ADD, &data) == TRUE;
  return tray_added_;
}

void DesktopWindow::RemoveTray() {
  if (!tray_added_) {
    return;
  }
  NOTIFYICONDATAW data = {};
  data.cbSize = sizeof(data);
  data.hWnd = window_;
  data.uID = kTrayId;
  ::Shell_NotifyIconW(NIM_DELETE, &data);
  tray_added_ = false;
}

void DesktopWindow::ShowTrayMenu() {
  HMENU menu = ::CreatePopupMenu();
  if (menu == nullptr) {
    return;
  }
  for (size_t index = 0; index < tray_items_.size(); index++) {
    const TrayItem& item = tray_items_[index];
    if (item.separator) {
      ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
      continue;
    }
    UINT flags = MF_STRING;
    if (!item.enabled) {
      flags |= MF_GRAYED;
    }
    ::AppendMenuW(menu, flags, index + 1, item.title.c_str());
  }

  POINT point;
  ::GetCursorPos(&point);
  // Without this the menu stays open after clicking elsewhere.
  ::SetForegroundWindow(window_);
  UINT picked = static_cast<UINT>(::TrackPopupMenu(
      menu, TPM_RETURNCMD | TPM_RIGHTBUTTON | TPM_NONOTIFY, point.x, point.y,
      0, window_, nullptr));
  ::PostMessage(window_, WM_NULL, 0, 0);
  ::DestroyMenu(menu);

  if (picked == 0 || picked > tray_items_.size()) {
    return;
  }
  Invoke("tray.select",
         std::make_unique<flutter::EncodableValue>(flutter::EncodableMap{
             {flutter::EncodableValue("id"),
              flutter::EncodableValue(tray_items_[picked - 1].id)},
         }));
}

void DesktopWindow::Invoke(const std::string& method,
                           std::unique_ptr<flutter::EncodableValue> arguments) {
  channel_->InvokeMethod(method, std::move(arguments));
}
