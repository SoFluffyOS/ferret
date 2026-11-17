#ifndef FLUTTER_PLUGIN_FERRET_HANDOFF_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_HANDOFF_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "messages.g.h"

namespace ferret_handoff {

class FerretHandoffPlugin : public flutter::Plugin, public FerretHandoffPluginApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FerretHandoffPlugin();

  virtual ~FerretHandoffPlugin();

  // Disallow copy and assign.
  FerretHandoffPlugin(const FerretHandoffPlugin&) = delete;
  FerretHandoffPlugin& operator=(const FerretHandoffPlugin&) = delete;

  ErrorOr<std::string> GetPlatformVersion() override;
};

}  // namespace ferret_handoff

#endif  // FLUTTER_PLUGIN_FERRET_HANDOFF_PLUGIN_H_
