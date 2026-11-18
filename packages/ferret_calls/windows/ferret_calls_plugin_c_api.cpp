#include "include/ferret_calls/ferret_calls_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ferret_calls_plugin.h"

void FerretCallsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ferret_calls::FerretCallsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
