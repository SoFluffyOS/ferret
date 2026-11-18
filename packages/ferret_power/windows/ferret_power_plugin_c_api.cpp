#include "include/ferret_power/ferret_power_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ferret_power_plugin.h"

void FerretPowerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ferret_power::FerretPowerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
