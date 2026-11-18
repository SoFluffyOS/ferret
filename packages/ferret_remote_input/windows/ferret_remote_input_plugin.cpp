#include "ferret_remote_input_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/plugin_registrar_windows.h>

#include <any>
#include <memory>
#include <vector>

namespace ferret_remote_input {

// static
void FerretRemoteInputPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<FerretRemoteInputPlugin>();
  RemoteInputHostApi::SetUp(registrar->messenger(), plugin.get());
  registrar->AddPlugin(std::move(plugin));
}

FerretRemoteInputPlugin::FerretRemoteInputPlugin() {}

FerretRemoteInputPlugin::~FerretRemoteInputPlugin() {
  std::vector<INPUT> releases = builder_.ReleaseAll();
  Send(releases);
}

ErrorOr<NativeAccess> FerretRemoteInputPlugin::Access() {
  return NativeAccess(true, false);
}

ErrorOr<bool> FerretRemoteInputPlugin::RequestAccess() { return true; }

std::optional<FlutterError> FerretRemoteInputPlugin::OpenAccessSettings() {
  return std::nullopt;
}

std::optional<FlutterError> FerretRemoteInputPlugin::Inject(
    const ::flutter::EncodableList& events) {
  std::vector<INPUT> inputs;
  for (const ::flutter::EncodableValue& value : events) {
    const auto* custom = std::get_if<::flutter::CustomEncodableValue>(&value);
    if (custom == nullptr) {
      continue;
    }
    const auto* event = std::any_cast<NativeInputEvent>(&custom->value());
    if (event == nullptr) {
      continue;
    }
    std::vector<INPUT> built = builder_.Build(*event);
    inputs.insert(inputs.end(), built.begin(), built.end());
  }
  return Send(inputs);
}

std::optional<FlutterError> FerretRemoteInputPlugin::ReleaseAll() {
  std::vector<INPUT> releases = builder_.ReleaseAll();
  return Send(releases);
}

std::optional<FlutterError> FerretRemoteInputPlugin::Send(
    std::vector<INPUT>& inputs) {
  if (inputs.empty()) {
    return std::nullopt;
  }
  const UINT sent = SendInput(static_cast<UINT>(inputs.size()), inputs.data(),
                              sizeof(INPUT));
  if (sent != inputs.size()) {
    // UIPI drops input aimed at a window with higher integrity, such as an
    // app running as administrator, or the secure desktop.
    return FlutterError("blocked", "Windows blocked the input");
  }
  return std::nullopt;
}

}  // namespace ferret_remote_input
