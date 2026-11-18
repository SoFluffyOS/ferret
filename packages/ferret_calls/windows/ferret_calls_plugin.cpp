#include "ferret_calls_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <sstream>

#include "messages.g.h"

namespace ferret_calls {

// static
void FerretCallsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<FerretCallsPlugin>();
  FerretCallsPluginApi::SetUp(registrar->messenger(), plugin.get());
  registrar->AddPlugin(std::move(plugin));
}

FerretCallsPlugin::FerretCallsPlugin() {}

FerretCallsPlugin::~FerretCallsPlugin() {}

ErrorOr<std::string> FerretCallsPlugin::GetPlatformVersion() {
  std::ostringstream version_stream;
  version_stream << "Windows ";
  if (IsWindows10OrGreater()) {
    version_stream << "10+";
  } else if (IsWindows8OrGreater()) {
    version_stream << "8";
  }
  return version_stream.str();
}

}  // namespace ferret_calls
