#ifndef FLUTTER_PLUGIN_FERRET_MEDIA_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_MEDIA_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "messages.g.h"

namespace ferret_media {

class FerretMediaPlugin : public flutter::Plugin, public FerretMediaPluginApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FerretMediaPlugin();

  virtual ~FerretMediaPlugin();

  // Disallow copy and assign.
  FerretMediaPlugin(const FerretMediaPlugin&) = delete;
  FerretMediaPlugin& operator=(const FerretMediaPlugin&) = delete;

  ErrorOr<std::string> GetPlatformVersion() override;
};

}  // namespace ferret_media

#endif  // FLUTTER_PLUGIN_FERRET_MEDIA_PLUGIN_H_
