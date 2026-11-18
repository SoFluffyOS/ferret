#ifndef FLUTTER_PLUGIN_FERRET_CLIPBOARD_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_CLIPBOARD_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>
#include <windows.h>

#include <memory>
#include <optional>

#include "messages.g.h"

namespace ferret_clipboard {

// Reads and writes the Windows clipboard, and reports changes with
// AddClipboardFormatListener on the app's top-level window.
class FerretClipboardPlugin : public flutter::Plugin, public ClipboardHostApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit FerretClipboardPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~FerretClipboardPlugin();

  FerretClipboardPlugin(const FerretClipboardPlugin&) = delete;
  FerretClipboardPlugin& operator=(const FerretClipboardPlugin&) = delete;

  ErrorOr<std::optional<PlatformClip>> Read() override;
  std::optional<FlutterError> Write(const PlatformClip& clip) override;
  std::optional<FlutterError> StartWatching() override;
  std::optional<FlutterError> StopWatching() override;

 private:
  std::optional<LRESULT> HandleWindowProc(HWND hwnd, UINT message,
                                          WPARAM wparam, LPARAM lparam);
  HWND TopLevelWindow() const;

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<ClipboardFlutterApi> flutter_api_;
  int window_proc_id_ = -1;
  HWND listening_window_ = nullptr;
  // The sequence number of the clipboard after this plugin's own last write,
  // so that write is not reported back as a change.
  DWORD own_write_sequence_ = 0;
};

}  // namespace ferret_clipboard

#endif  // FLUTTER_PLUGIN_FERRET_CLIPBOARD_PLUGIN_H_
