#ifndef FLUTTER_PLUGIN_FERRET_REMOTE_INPUT_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_REMOTE_INPUT_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <optional>

#include "input_builder.h"
#include "messages.g.h"

namespace ferret_remote_input {

// Injects pointer and keyboard input for a remote controller with
// SendInput. Windows needs no permission, but blocks input into apps
// running as administrator unless Ferret runs elevated too.
class FerretRemoteInputPlugin : public flutter::Plugin, public RemoteInputHostApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  FerretRemoteInputPlugin();

  virtual ~FerretRemoteInputPlugin();

  FerretRemoteInputPlugin(const FerretRemoteInputPlugin&) = delete;
  FerretRemoteInputPlugin& operator=(const FerretRemoteInputPlugin&) = delete;

  ErrorOr<NativeAccess> Access() override;
  ErrorOr<bool> RequestAccess() override;
  std::optional<FlutterError> OpenAccessSettings() override;
  std::optional<FlutterError> Inject(const ::flutter::EncodableList& events) override;
  std::optional<FlutterError> ReleaseAll() override;

 private:
  std::optional<FlutterError> Send(std::vector<INPUT>& inputs);

  InputBuilder builder_;
};

}  // namespace ferret_remote_input

#endif  // FLUTTER_PLUGIN_FERRET_REMOTE_INPUT_PLUGIN_H_
