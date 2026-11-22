#ifndef RUNNER_DESKTOP_WINDOW_H_
#define RUNNER_DESKTOP_WINDOW_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>
#include <optional>
#include <string>
#include <vector>

// The window's side of the io.sofluffy.ferret/desktop channel: the tray
// icon and its menu, hiding to the tray on close while the icon exists,
// show and hide on request, and the window's size and place kept in
// HKCU\Software\SoFluffy\Ferret between runs.
class DesktopWindow {
 public:
  DesktopWindow(HWND window, flutter::BinaryMessenger* messenger,
                bool started_hidden);
  ~DesktopWindow();

  // Puts the window where it was last time, before it is first shown.
  void RestorePlacement();

  // Shows the window at start, unless autostart asked for --hidden.
  void ShowAtStart();

  // Handles the close button and the tray icon's messages.
  std::optional<LRESULT> HandleMessage(UINT message, WPARAM wparam,
                                       LPARAM lparam);

 private:
  struct TrayItem {
    std::string id;
    std::wstring title;
    bool enabled;
    bool separator;
  };

  void OnCall(const flutter::MethodCall<flutter::EncodableValue>& call,
              std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                  result);
  void Show();
  void Hide();
  void SavePlacement();
  bool SetTray(const flutter::EncodableMap& arguments);
  bool ShowIcon();
  void RemoveTray();
  void ShowTrayMenu(int x, int y);
  void Invoke(const std::string& method,
              std::unique_ptr<flutter::EncodableValue> arguments = nullptr);

  HWND window_;
  bool started_hidden_;
  bool hide_on_close_ = false;
  bool show_maximized_ = false;
  bool tray_added_ = false;
  DWORD last_activate_ = 0;
  std::wstring tray_tooltip_;
  std::vector<TrayItem> tray_items_;
  UINT taskbar_created_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_DESKTOP_WINDOW_H_
