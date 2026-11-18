#ifndef FLUTTER_PLUGIN_FERRET_REMOTE_INPUT_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_REMOTE_INPUT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "messages.g.h"

namespace ferret_remote_input {

class FerretRemoteInputPlugin : public flutter::Plugin, public FerretRemoteInputPluginApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FerretRemoteInputPlugin();

  virtual ~FerretRemoteInputPlugin();

  // Disallow copy and assign.
  FerretRemoteInputPlugin(const FerretRemoteInputPlugin&) = delete;
  FerretRemoteInputPlugin& operator=(const FerretRemoteInputPlugin&) = delete;

  ErrorOr<std::string> GetPlatformVersion() override;
};

}  // namespace ferret_remote_input

#endif  // FLUTTER_PLUGIN_FERRET_REMOTE_INPUT_PLUGIN_H_
