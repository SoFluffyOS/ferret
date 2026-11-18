#include "ferret_media_plugin.h"

#include <windows.h>

#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <utility>

#include "messages.g.h"

namespace ferret_media {

namespace {

flutter::EncodableList ToEncodable(const std::vector<PlayerInfo>& players) {
  flutter::EncodableList list;
  list.reserve(players.size());
  for (const auto& player : players) {
    list.push_back(flutter::CustomEncodableValue(player));
  }
  return list;
}

}  // namespace

// static
void FerretMediaPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<FerretMediaPlugin>(registrar);
  MediaHostApi::SetUp(registrar->messenger(), plugin.get());
  registrar->AddPlugin(std::move(plugin));
}

FerretMediaPlugin::FerretMediaPlugin(flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar),
      flutter_api_(std::make_unique<MediaFlutterApi>(registrar->messenger())) {
  dispatch_message_ = RegisterWindowMessageW(L"FerretMediaDispatch");
  window_proc_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
        return HandleWindowProc(hwnd, message, wparam, lparam);
      });

  sessions_ = std::make_unique<MediaSessions>(
      [this](std::vector<PlayerInfo> players) {
        PostToPlatform([this, players = std::move(players)]() {
          flutter_api_->OnPlayersChanged(
              ToEncodable(players), [] {}, [](const FlutterError&) {});
        });
      });
}

FerretMediaPlugin::~FerretMediaPlugin() {
  sessions_.reset();
  registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_id_);
}

ErrorOr<MediaAccess> FerretMediaPlugin::Access() {
  return MediaAccess::kGranted;
}

void FerretMediaPlugin::RequestAccess(
    std::function<void(ErrorOr<MediaAccess> reply)> result) {
  result(MediaAccess::kGranted);
}

std::optional<FlutterError> FerretMediaPlugin::OpenAccessSettings() {
  return std::nullopt;
}

std::optional<FlutterError> FerretMediaPlugin::StartWatching() {
  sessions_->Start();
  return std::nullopt;
}

std::optional<FlutterError> FerretMediaPlugin::StopWatching() {
  sessions_->Stop();
  return std::nullopt;
}

void FerretMediaPlugin::Players(
    std::function<void(ErrorOr<flutter::EncodableList> reply)> result) {
  sessions_->ReadPlayers(
      [this, result = std::move(result)](std::vector<PlayerInfo> players) {
        PostToPlatform([result, players = std::move(players)]() {
          result(ToEncodable(players));
        });
      });
}

void FerretMediaPlugin::Command(
    const std::string& player_id, const PlayerAction& action,
    int64_t position_ms, double volume,
    std::function<void(ErrorOr<bool> reply)> result) {
  sessions_->Command(player_id, action, position_ms, volume,
                     [this, result = std::move(result)](bool ok) {
                       PostToPlatform([result, ok]() { result(ok); });
                     });
}

void FerretMediaPlugin::PostToPlatform(std::function<void()> task) {
  {
    std::lock_guard<std::mutex> lock(tasks_mutex_);
    platform_tasks_.push_back(std::move(task));
  }

  HWND window = registrar_->GetView() ? registrar_->GetView()->GetNativeWindow()
                                      : nullptr;
  if (window) {
    HWND root = GetAncestor(window, GA_ROOT);
    PostMessageW(root ? root : window, dispatch_message_, 0, 0);
  }
}

std::optional<LRESULT> FerretMediaPlugin::HandleWindowProc(HWND hwnd,
                                                           UINT message,
                                                           WPARAM wparam,
                                                           LPARAM lparam) {
  if (message != dispatch_message_) {
    return std::nullopt;
  }

  DrainPlatformTasks();
  return 0;
}

void FerretMediaPlugin::DrainPlatformTasks() {
  std::deque<std::function<void()>> tasks;
  {
    std::lock_guard<std::mutex> lock(tasks_mutex_);
    tasks.swap(platform_tasks_);
  }

  for (auto& task : tasks) {
    task();
  }
}

}  // namespace ferret_media
