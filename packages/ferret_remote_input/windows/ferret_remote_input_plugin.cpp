#include "ferret_remote_input_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <sstream>

#include "messages.g.h"

namespace ferret_remote_input {

// static
void FerretRemoteInputPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<FerretRemoteInputPlugin>();
  FerretRemoteInputPluginApi::SetUp(registrar->messenger(), plugin.get());
  registrar->AddPlugin(std::move(plugin));
}

FerretRemoteInputPlugin::FerretRemoteInputPlugin() {}

FerretRemoteInputPlugin::~FerretRemoteInputPlugin() {}

ErrorOr<std::string> FerretRemoteInputPlugin::GetPlatformVersion() {
  std::ostringstream version_stream;
  version_stream << "Windows ";
  if (IsWindows10OrGreater()) {
    version_stream << "10+";
  } else if (IsWindows8OrGreater()) {
    version_stream << "8";
  }
  return version_stream.str();
}

}  // namespace ferret_remote_input
