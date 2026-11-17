#ifndef FLUTTER_PLUGIN_FERRET_CLIPBOARD_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_CLIPBOARD_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "messages.g.h"

namespace ferret_clipboard {

class FerretClipboardPlugin : public flutter::Plugin, public FerretClipboardPluginApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FerretClipboardPlugin();

  virtual ~FerretClipboardPlugin();

  // Disallow copy and assign.
  FerretClipboardPlugin(const FerretClipboardPlugin&) = delete;
  FerretClipboardPlugin& operator=(const FerretClipboardPlugin&) = delete;

  ErrorOr<std::string> GetPlatformVersion() override;
};

}  // namespace ferret_clipboard

#endif  // FLUTTER_PLUGIN_FERRET_CLIPBOARD_PLUGIN_H_
