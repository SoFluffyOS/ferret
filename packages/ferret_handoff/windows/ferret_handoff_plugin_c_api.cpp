#include "include/ferret_handoff/ferret_handoff_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ferret_handoff_plugin.h"

void FerretHandoffPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ferret_handoff::FerretHandoffPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
