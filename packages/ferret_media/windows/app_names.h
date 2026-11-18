#ifndef FLUTTER_PLUGIN_FERRET_MEDIA_APP_NAMES_H_
#define FLUTTER_PLUGIN_FERRET_MEDIA_APP_NAMES_H_

#include <string>

namespace ferret_media {

// A readable name for an app user model id, such as "Spotify" for
// "Spotify.exe" or "Media Player" for the Microsoft.ZuneMusic package.
std::string AppNameFor(const std::string& app_user_model_id);

}  // namespace ferret_media

#endif  // FLUTTER_PLUGIN_FERRET_MEDIA_APP_NAMES_H_
