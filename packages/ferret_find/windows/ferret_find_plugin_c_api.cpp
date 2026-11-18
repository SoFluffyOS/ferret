#include "include/ferret_find/ferret_find_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ferret_find_plugin.h"

void FerretFindPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ferret_find::FerretFindPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
