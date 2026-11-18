#ifndef FLUTTER_PLUGIN_FERRET_IPHONE_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_IPHONE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "messages.g.h"

namespace ferret_iphone {

class FerretIphonePlugin : public flutter::Plugin, public FerretIphonePluginApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FerretIphonePlugin();

  virtual ~FerretIphonePlugin();

  // Disallow copy and assign.
  FerretIphonePlugin(const FerretIphonePlugin&) = delete;
  FerretIphonePlugin& operator=(const FerretIphonePlugin&) = delete;

  ErrorOr<std::string> GetPlatformVersion() override;
};

}  // namespace ferret_iphone

#endif  // FLUTTER_PLUGIN_FERRET_IPHONE_PLUGIN_H_
