#include "include/ferret_notifications/ferret_notifications_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ferret_notifications_plugin.h"

void FerretNotificationsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ferret_notifications::FerretNotificationsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
