#ifndef FLUTTER_PLUGIN_FERRET_POWER_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_POWER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "messages.g.h"

namespace ferret_power {

class FerretPowerPlugin : public flutter::Plugin, public FerretPowerPluginApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FerretPowerPlugin();

  virtual ~FerretPowerPlugin();

  // Disallow copy and assign.
  FerretPowerPlugin(const FerretPowerPlugin&) = delete;
  FerretPowerPlugin& operator=(const FerretPowerPlugin&) = delete;

  ErrorOr<std::string> GetPlatformVersion() override;
};

}  // namespace ferret_power

#endif  // FLUTTER_PLUGIN_FERRET_POWER_PLUGIN_H_
