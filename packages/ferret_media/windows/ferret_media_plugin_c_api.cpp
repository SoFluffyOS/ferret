#include "include/ferret_media/ferret_media_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ferret_media_plugin.h"

void FerretMediaPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ferret_media::FerretMediaPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
