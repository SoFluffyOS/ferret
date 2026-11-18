#include "media_sessions.h"

#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Media.Control.h>
#include <winrt/Windows.Storage.Streams.h>

#include <algorithm>
#include <chrono>
#include <utility>

#include "app_names.h"

namespace ferret_media {

namespace {

using winrt::Windows::Foundation::DateTime;
using winrt::Windows::Foundation::TimeSpan;
using winrt::Windows::Graphics::Imaging::BitmapAlphaMode;
using winrt::Windows::Graphics::Imaging::BitmapDecoder;
using winrt::Windows::Graphics::Imaging::BitmapEncoder;
using winrt::Windows::Graphics::Imaging::BitmapInterpolationMode;
using winrt::Windows::Graphics::Imaging::BitmapPixelFormat;
using winrt::Windows::Graphics::Imaging::BitmapPropertySet;
using winrt::Windows::Graphics::Imaging::BitmapTypedValue;
using winrt::Windows::Media::Control::
    GlobalSystemMediaTransportControlsSessionPlaybackStatus;
using winrt::Windows::Storage::Streams::Buffer;
using winrt::Windows::Storage::Streams::InMemoryRandomAccessStream;
using winrt::Windows::Storage::Streams::InputStreamOptions;
using winrt::Windows::Storage::Streams::IRandomAccessStreamReference;

constexpr uint32_t kMaxArtworkBytes = 64 * 1024;
constexpr auto kEmitDelay = std::chrono::milliseconds(250);

int64_t NowMs() {
  return std::chrono::duration_cast<std::chrono::milliseconds>(
             std::chrono::system_clock::now().time_since_epoch())
      .count();
}

int64_t ToUnixMs(DateTime time) {
  return std::chrono::duration_cast<std::chrono::milliseconds>(
             winrt::clock::to_sys(time).time_since_epoch())
      .count();
}

int64_t ToMs(TimeSpan span) {
  return std::chrono::duration_cast<std::chrono::milliseconds>(span).count();
}

std::string ToUtf8(const winrt::hstring& text) { return winrt::to_string(text); }

PlayerStatus StatusOf(GlobalSystemMediaTransportControlsSessionPlaybackStatus status) {
  switch (status) {
    case GlobalSystemMediaTransportControlsSessionPlaybackStatus::Playing:
      return PlayerStatus::kPlaying;
    case GlobalSystemMediaTransportControlsSessionPlaybackStatus::Paused:
      return PlayerStatus::kPaused;
    case GlobalSystemMediaTransportControlsSessionPlaybackStatus::Changing:
    case GlobalSystemMediaTransportControlsSessionPlaybackStatus::Opened:
      return PlayerStatus::kBuffering;
    default:
      return PlayerStatus::kStopped;
  }
}

// Scales the thumbnail down and encodes it as a JPEG that fits one message.
std::optional<std::vector<uint8_t>> EncodeArtwork(
    const IRandomAccessStreamReference& thumbnail) {
  if (!thumbnail) {
    return std::nullopt;
  }

  try {
    auto source = thumbnail.OpenReadAsync().get();
    auto decoder = BitmapDecoder::CreateAsync(source).get();
    const uint32_t longest =
        (std::max)(decoder.PixelWidth(), decoder.PixelHeight());
    if (longest == 0) {
      return std::nullopt;
    }

    const std::pair<uint32_t, float> steps[] = {
        {256, 0.8f}, {192, 0.7f}, {128, 0.6f}};
    for (const auto& [side, quality] : steps) {
      const double scale = (std::min)(1.0, static_cast<double>(side) / longest);
      const uint32_t width = (std::max)(
          1u, static_cast<uint32_t>(decoder.PixelWidth() * scale + 0.5));
      const uint32_t height = (std::max)(
          1u, static_cast<uint32_t>(decoder.PixelHeight() * scale + 0.5));

      auto bitmap = decoder
                        .GetSoftwareBitmapAsync(BitmapPixelFormat::Bgra8,
                                                BitmapAlphaMode::Ignore)
                        .get();

      InMemoryRandomAccessStream output;
      BitmapPropertySet options;
      options.Insert(L"ImageQuality",
                     BitmapTypedValue(winrt::box_value(quality),
                                      winrt::Windows::Foundation::PropertyType::Single));
      auto encoder = BitmapEncoder::CreateAsync(BitmapEncoder::JpegEncoderId(),
                                                output, options)
                         .get();
      encoder.SetSoftwareBitmap(bitmap);
      encoder.BitmapTransform().ScaledWidth(width);
      encoder.BitmapTransform().ScaledHeight(height);
      encoder.BitmapTransform().InterpolationMode(
          BitmapInterpolationMode::Fant);
      encoder.FlushAsync().get();

      const auto size = static_cast<uint32_t>(output.Size());
      if (size > kMaxArtworkBytes) {
        continue;
      }

      output.Seek(0);
      Buffer buffer(size);
      auto read = output.ReadAsync(buffer, size, InputStreamOptions::None).get();
      return std::vector<uint8_t>(read.data(), read.data() + read.Length());
    }
  } catch (const winrt::hresult_error&) {
    return std::nullopt;
  }

  return std::nullopt;
}

}  // namespace

MediaSessions::MediaSessions(PlayersCallback on_change)
    : on_change_(std::move(on_change)) {
  worker_ = std::thread([this] { Run(); });
}

MediaSessions::~MediaSessions() {
  Post([this] { Detach(); });
  {
    std::lock_guard<std::mutex> lock(mutex_);
    quitting_ = true;
  }
  wake_.notify_one();
  if (worker_.joinable()) {
    worker_.join();
  }
}

void MediaSessions::Start() {
  Post([this] {
    if (watching_) {
      return;
    }
    watching_ = true;
    Attach();
  });
}

void MediaSessions::Stop() {
  Post([this] {
    watching_ = false;
    Detach();
  });
}

void MediaSessions::ReadPlayers(PlayersCallback reply) {
  Post([this, reply = std::move(reply)] {
    if (!manager_) {
      Attach();
    }
    reply(Snapshot());
  });
}

void MediaSessions::Command(const std::string& player_id, PlayerAction action,
                            int64_t position_ms, double volume,
                            std::function<void(bool)> reply) {
  Post([this, player_id, action, position_ms, reply = std::move(reply)] {
    reply(RunCommand(player_id, action, position_ms));
  });
}

void MediaSessions::Post(std::function<void()> task) {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    tasks_.push_back(std::move(task));
  }
  wake_.notify_one();
}

void MediaSessions::Run() {
  winrt::init_apartment(winrt::apartment_type::multi_threaded);

  while (true) {
    std::function<void()> task;
    {
      std::unique_lock<std::mutex> lock(mutex_);
      wake_.wait(lock, [this] { return quitting_ || !tasks_.empty(); });
      if (tasks_.empty()) {
        break;
      }
      task = std::move(tasks_.front());
      tasks_.pop_front();
    }

    try {
      task();
    } catch (const winrt::hresult_error&) {
      // A session closed mid-call; the next change event resyncs.
    }
  }

  winrt::uninit_apartment();
}

void MediaSessions::Attach() {
  if (manager_) {
    SyncSessions();
    return;
  }

  try {
    manager_ = SessionManager::RequestAsync().get();
  } catch (const winrt::hresult_error&) {
    manager_ = nullptr;
    return;
  }

  sessions_token_ = manager_.SessionsChanged([this](auto&&, auto&&) {
    Post([this] { SyncSessions(); });
  });
  SyncSessions();
}

void MediaSessions::Detach() {
  for (auto& [id, tracked] : tracked_) {
    tracked.session.MediaPropertiesChanged(tracked.media_token);
    tracked.session.PlaybackInfoChanged(tracked.playback_token);
    tracked.session.TimelinePropertiesChanged(tracked.timeline_token);
  }
  tracked_.clear();

  if (manager_) {
    manager_.SessionsChanged(sessions_token_);
    manager_ = nullptr;
  }
}

void MediaSessions::SyncSessions() {
  if (!manager_) {
    return;
  }

  std::map<std::string, Session> current;
  for (const auto& session : manager_.GetSessions()) {
    std::string id = ToUtf8(session.SourceAppUserModelId());
    std::string unique = id;
    for (int index = 2; current.count(unique) > 0; ++index) {
      unique = id + "#" + std::to_string(index);
    }
    current.emplace(unique, session);
  }

  for (auto it = tracked_.begin(); it != tracked_.end();) {
    if (current.count(it->first) > 0) {
      ++it;
      continue;
    }
    it->second.session.MediaPropertiesChanged(it->second.media_token);
    it->second.session.PlaybackInfoChanged(it->second.playback_token);
    it->second.session.TimelinePropertiesChanged(it->second.timeline_token);
    it = tracked_.erase(it);
  }

  for (auto& [id, session] : current) {
    if (tracked_.count(id) > 0) {
      continue;
    }

    Tracked tracked;
    tracked.session = session;
    auto on_change = [this](auto&&, auto&&) {
      Post([this] { ScheduleEmit(); });
    };
    tracked.media_token = session.MediaPropertiesChanged(on_change);
    tracked.playback_token = session.PlaybackInfoChanged(on_change);
    tracked.timeline_token = session.TimelinePropertiesChanged(on_change);
    tracked_.emplace(id, std::move(tracked));
  }

  ScheduleEmit();
}

void MediaSessions::ScheduleEmit() {
  if (!watching_ || emit_pending_) {
    return;
  }

  emit_pending_ = true;
  // Players fire media, playback and timeline events in bursts; wait a beat
  // so one update covers the burst.
  std::this_thread::sleep_for(kEmitDelay);
  Post([this] {
    emit_pending_ = false;
    if (watching_) {
      on_change_(Snapshot());
    }
  });
}

std::vector<PlayerInfo> MediaSessions::Snapshot() {
  std::vector<PlayerInfo> players;
  for (auto& [id, tracked] : tracked_) {
    try {
      if (auto player = SnapshotOf(id, tracked)) {
        players.push_back(std::move(*player));
      }
    } catch (const winrt::hresult_error&) {
      continue;
    }
  }
  return players;
}

std::optional<PlayerInfo> MediaSessions::SnapshotOf(const std::string& id,
                                                    Tracked& tracked) {
  auto properties = tracked.session.TryGetMediaPropertiesAsync().get();
  if (!properties || properties.Title().empty()) {
    return std::nullopt;
  }

  auto playback = tracked.session.GetPlaybackInfo();
  auto timeline = tracked.session.GetTimelineProperties();
  auto controls = playback.Controls();
  const int64_t now = NowMs();
  const PlayerStatus status = StatusOf(playback.PlaybackStatus());
  const std::wstring title(properties.Title());

  if (tracked.title != title ||
      (status == PlayerStatus::kPlaying && tracked.status != PlayerStatus::kPlaying)) {
    tracked.last_active_at_ms = now;
  }
  tracked.title = title;
  tracked.status = status;

  const std::wstring artwork_key = title + L"\n" + std::wstring(properties.Artist());
  if (tracked.artwork_key != artwork_key) {
    tracked.artwork_key = artwork_key;
    tracked.artwork = EncodeArtwork(properties.Thumbnail());
  }

  flutter::EncodableList actions;
  if (controls.IsPlayEnabled()) {
    actions.push_back(flutter::CustomEncodableValue(PlayerAction::kPlay));
  }
  if (controls.IsPauseEnabled()) {
    actions.push_back(flutter::CustomEncodableValue(PlayerAction::kPause));
  }
  if (controls.IsPlayPauseToggleEnabled() || controls.IsPlayEnabled() ||
      controls.IsPauseEnabled()) {
    actions.push_back(flutter::CustomEncodableValue(PlayerAction::kToggle));
  }
  if (controls.IsNextEnabled()) {
    actions.push_back(flutter::CustomEncodableValue(PlayerAction::kNext));
  }
  if (controls.IsPreviousEnabled()) {
    actions.push_back(flutter::CustomEncodableValue(PlayerAction::kPrevious));
  }
  if (controls.IsPlaybackPositionEnabled()) {
    actions.push_back(flutter::CustomEncodableValue(PlayerAction::kSeek));
  }

  const int64_t start_ms = ToMs(timeline.StartTime());
  const int64_t duration_ms = (std::max)(int64_t{0}, ToMs(timeline.EndTime()) - start_ms);
  const int64_t position_ms = (std::max)(int64_t{0}, ToMs(timeline.Position()) - start_ms);
  const int64_t updated_ms = ToUnixMs(timeline.LastUpdatedTime());
  const int64_t position_at_ms = updated_ms > 0 ? updated_ms : now;

  double rate = 1.0;
  if (auto playback_rate = playback.PlaybackRate()) {
    rate = playback_rate.Value();
  }

  const std::string app_id = ToUtf8(tracked.session.SourceAppUserModelId());
  const std::vector<uint8_t>* artwork =
      tracked.artwork ? &*tracked.artwork : nullptr;

  return PlayerInfo(id, app_id, AppNameFor(app_id), ToUtf8(properties.Title()),
                    ToUtf8(properties.Artist()), ToUtf8(properties.AlbumTitle()),
                    artwork, duration_ms, position_ms, position_at_ms, status,
                    rate, nullptr, tracked.last_active_at_ms, actions, -1.0);
}

bool MediaSessions::RunCommand(const std::string& player_id,
                               PlayerAction action, int64_t position_ms) {
  if (!manager_) {
    Attach();
  }

  auto found = tracked_.find(player_id);
  if (found == tracked_.end()) {
    return false;
  }

  auto& session = found->second.session;
  try {
    switch (action) {
      case PlayerAction::kPlay:
        return session.TryPlayAsync().get();
      case PlayerAction::kPause:
        return session.TryPauseAsync().get();
      case PlayerAction::kToggle:
        return session.TryTogglePlayPauseAsync().get();
      case PlayerAction::kNext:
        return session.TrySkipNextAsync().get();
      case PlayerAction::kPrevious:
        return session.TrySkipPreviousAsync().get();
      case PlayerAction::kSeek: {
        const int64_t start_ms = ToMs(session.GetTimelineProperties().StartTime());
        const int64_t ticks = (start_ms + position_ms) * 10000;
        return session.TryChangePlaybackPositionAsync(ticks).get();
      }
      case PlayerAction::kSetVolume:
        // The system media controls have no per-player volume.
        return false;
    }
  } catch (const winrt::hresult_error&) {
    return false;
  }

  return false;
}

}  // namespace ferret_media
