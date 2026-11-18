#ifndef FLUTTER_PLUGIN_FERRET_FIND_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_FIND_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "messages.g.h"

namespace ferret_find {

class FerretFindPlugin : public flutter::Plugin, public FerretFindPluginApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FerretFindPlugin();

  virtual ~FerretFindPlugin();

  // Disallow copy and assign.
  FerretFindPlugin(const FerretFindPlugin&) = delete;
  FerretFindPlugin& operator=(const FerretFindPlugin&) = delete;

  ErrorOr<std::string> GetPlatformVersion() override;
};

}  // namespace ferret_find

#endif  // FLUTTER_PLUGIN_FERRET_FIND_PLUGIN_H_
