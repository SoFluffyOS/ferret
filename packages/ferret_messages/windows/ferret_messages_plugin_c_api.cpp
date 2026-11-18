#include "include/ferret_messages/ferret_messages_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ferret_messages_plugin.h"

void FerretMessagesPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ferret_messages::FerretMessagesPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
