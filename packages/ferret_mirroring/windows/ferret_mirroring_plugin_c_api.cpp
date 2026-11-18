#include "include/ferret_mirroring/ferret_mirroring_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ferret_mirroring_plugin.h"

void FerretMirroringPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ferret_mirroring::FerretMirroringPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
