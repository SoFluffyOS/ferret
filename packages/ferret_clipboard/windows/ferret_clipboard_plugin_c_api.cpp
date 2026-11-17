#include "include/ferret_clipboard/ferret_clipboard_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ferret_clipboard_plugin.h"

void FerretClipboardPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ferret_clipboard::FerretClipboardPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
