#include "include/ferret_iphone/ferret_iphone_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ferret_iphone_plugin.h"

void FerretIphonePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ferret_iphone::FerretIphonePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
