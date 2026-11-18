#ifndef FLUTTER_PLUGIN_FERRET_MIRRORING_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_MIRRORING_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "messages.g.h"

namespace ferret_mirroring {

class FerretMirroringPlugin : public flutter::Plugin, public FerretMirroringPluginApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FerretMirroringPlugin();

  virtual ~FerretMirroringPlugin();

  // Disallow copy and assign.
  FerretMirroringPlugin(const FerretMirroringPlugin&) = delete;
  FerretMirroringPlugin& operator=(const FerretMirroringPlugin&) = delete;

  ErrorOr<std::string> GetPlatformVersion() override;
};

}  // namespace ferret_mirroring

#endif  // FLUTTER_PLUGIN_FERRET_MIRRORING_PLUGIN_H_
