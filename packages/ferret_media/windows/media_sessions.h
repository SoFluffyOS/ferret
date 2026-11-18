#ifndef FLUTTER_PLUGIN_FERRET_MEDIA_SESSIONS_H_
#define FLUTTER_PLUGIN_FERRET_MEDIA_SESSIONS_H_

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.Control.h>

#include <condition_variable>
#include <cstdint>
#include <deque>
#include <functional>
#include <map>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <vector>

#include "messages.g.h"

namespace ferret_media {

// Reads and controls the system's media sessions on its own MTA thread, so
// blocking WinRT calls never run on the platform thread. Callbacks run on
// that thread too; the plugin hands their results to the platform thread.
class MediaSessions {
 public:
  using PlayersCallback = std::function<void(std::vector<PlayerInfo>)>;

  explicit MediaSessions(PlayersCallback on_change);
  ~MediaSessions();

  MediaSessions(const MediaSessions&) = delete;
  MediaSessions& operator=(const MediaSessions&) = delete;

  void Start();
  void Stop();
  void ReadPlayers(PlayersCallback reply);
  void Command(const std::string& player_id, PlayerAction action,
               int64_t position_ms, double volume,
               std::function<void(bool)> reply);

 private:
  using Session = winrt::Windows::Media::Control::
      GlobalSystemMediaTransportControlsSession;
  using SessionManager = winrt::Windows::Media::Control::
      GlobalSystemMediaTransportControlsSessionManager;

  struct Tracked {
    Session session{nullptr};
    winrt::event_token media_token;
    winrt::event_token playback_token;
    winrt::event_token timeline_token;
    std::wstring title;
    PlayerStatus status = PlayerStatus::kStopped;
    int64_t last_active_at_ms = 0;
    std::wstring artwork_key;
    std::optional<std::vector<uint8_t>> artwork;
  };

  void Post(std::function<void()> task);
  void Run();

  // Worker thread only.
  void Attach();
  void Detach();
  void SyncSessions();
  void ScheduleEmit();
  std::vector<PlayerInfo> Snapshot();
  std::optional<PlayerInfo> SnapshotOf(const std::string& id, Tracked& tracked);
  bool RunCommand(const std::string& player_id, PlayerAction action,
                  int64_t position_ms);

  PlayersCallback on_change_;
  std::thread worker_;
  std::mutex mutex_;
  std::condition_variable wake_;
  std::deque<std::function<void()>> tasks_;
  bool quitting_ = false;

  SessionManager manager_{nullptr};
  winrt::event_token sessions_token_;
  std::map<std::string, Tracked> tracked_;
  bool watching_ = false;
  bool emit_pending_ = false;
};

}  // namespace ferret_media

#endif  // FLUTTER_PLUGIN_FERRET_MEDIA_SESSIONS_H_
