#include "include/ferret_drop/ferret_drop_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ferret_drop_plugin.h"

void FerretDropPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ferret_drop::FerretDropPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
