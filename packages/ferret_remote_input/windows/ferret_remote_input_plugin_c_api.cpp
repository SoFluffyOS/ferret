#include "include/ferret_remote_input/ferret_remote_input_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ferret_remote_input_plugin.h"

void FerretRemoteInputPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ferret_remote_input::FerretRemoteInputPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
