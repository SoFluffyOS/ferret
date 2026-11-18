#ifndef FLUTTER_PLUGIN_FERRET_MEDIA_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_MEDIA_PLUGIN_H_

#include <windows.h>

#include <flutter/plugin_registrar_windows.h>

#include <deque>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>

#include "media_sessions.h"
#include "messages.g.h"

namespace ferret_media {

// Media sessions of other apps through the Global System Media Transport
// Controls. WinRT work runs on a background worker; results come back to the
// platform thread through the top-level window's message loop.
class FerretMediaPlugin : public flutter::Plugin, public MediaHostApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit FerretMediaPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~FerretMediaPlugin();

  FerretMediaPlugin(const FerretMediaPlugin&) = delete;
  FerretMediaPlugin& operator=(const FerretMediaPlugin&) = delete;

  ErrorOr<MediaAccess> Access() override;
  void RequestAccess(
      std::function<void(ErrorOr<MediaAccess> reply)> result) override;
  std::optional<FlutterError> OpenAccessSettings() override;
  std::optional<FlutterError> StartWatching() override;
  std::optional<FlutterError> StopWatching() override;
  void Players(
      std::function<void(ErrorOr<flutter::EncodableList> reply)> result) override;
  void Command(const std::string& player_id, const PlayerAction& action,
               int64_t position_ms, double volume,
               std::function<void(ErrorOr<bool> reply)> result) override;

 private:
  // Runs |task| on the platform thread.
  void PostToPlatform(std::function<void()> task);

  std::optional<LRESULT> HandleWindowProc(HWND hwnd, UINT message,
                                          WPARAM wparam, LPARAM lparam);

  void DrainPlatformTasks();

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<MediaFlutterApi> flutter_api_;
  std::unique_ptr<MediaSessions> sessions_;
  int window_proc_id_ = -1;
  UINT dispatch_message_ = 0;

  std::mutex tasks_mutex_;
  std::deque<std::function<void()>> platform_tasks_;
};

}  // namespace ferret_media

#endif  // FLUTTER_PLUGIN_FERRET_MEDIA_PLUGIN_H_
