#ifndef FLUTTER_PLUGIN_FERRET_DROP_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_DROP_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "messages.g.h"

namespace ferret_drop {

class FerretDropPlugin : public flutter::Plugin, public FerretDropPluginApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FerretDropPlugin();

  virtual ~FerretDropPlugin();

  // Disallow copy and assign.
  FerretDropPlugin(const FerretDropPlugin&) = delete;
  FerretDropPlugin& operator=(const FerretDropPlugin&) = delete;

  ErrorOr<std::string> GetPlatformVersion() override;
};

}  // namespace ferret_drop

#endif  // FLUTTER_PLUGIN_FERRET_DROP_PLUGIN_H_
