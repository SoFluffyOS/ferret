#ifndef FLUTTER_PLUGIN_FERRET_CALLS_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_CALLS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "messages.g.h"

namespace ferret_calls {

class FerretCallsPlugin : public flutter::Plugin, public FerretCallsPluginApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FerretCallsPlugin();

  virtual ~FerretCallsPlugin();

  // Disallow copy and assign.
  FerretCallsPlugin(const FerretCallsPlugin&) = delete;
  FerretCallsPlugin& operator=(const FerretCallsPlugin&) = delete;

  ErrorOr<std::string> GetPlatformVersion() override;
};

}  // namespace ferret_calls

#endif  // FLUTTER_PLUGIN_FERRET_CALLS_PLUGIN_H_
