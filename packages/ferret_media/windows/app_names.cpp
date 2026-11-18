#include "app_names.h"

#include <algorithm>
#include <cctype>
#include <map>

namespace ferret_media {

namespace {

std::string Lowercase(std::string text) {
  std::transform(text.begin(), text.end(), text.begin(),
                 [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  return text;
}

}  // namespace

std::string AppNameFor(const std::string& app_user_model_id) {
  static const std::map<std::string, std::string> known = {
      {"spotify", "Spotify"},
      {"chrome", "Chrome"},
      {"msedge", "Edge"},
      {"firefox", "Firefox"},
      {"brave", "Brave"},
      {"vlc", "VLC"},
      {"microsoft.zunemusic", "Media Player"},
      {"microsoft.zunevideo", "Movies & TV"},
      {"applemusic", "Apple Music"},
      {"appleinc.applemusicwin", "Apple Music"},
  };

  std::string name = app_user_model_id;
  const auto bang = name.find('!');
  if (bang != std::string::npos) {
    name = name.substr(0, bang);
  }
  const auto underscore = name.find('_');
  if (underscore != std::string::npos) {
    name = name.substr(0, underscore);
  }
  const auto slash = name.find_last_of("\\/");
  if (slash != std::string::npos) {
    name = name.substr(slash + 1);
  }
  const std::string lower = Lowercase(name);
  if (lower.size() > 4 && lower.compare(lower.size() - 4, 4, ".exe") == 0) {
    name = name.substr(0, name.size() - 4);
  }

  const auto found = known.find(Lowercase(name));
  if (found != known.end()) {
    return found->second;
  }
  if (name.empty()) {
    return app_user_model_id;
  }
  return name;
}

}  // namespace ferret_media
