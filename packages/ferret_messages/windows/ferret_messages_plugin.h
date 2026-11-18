#ifndef FLUTTER_PLUGIN_FERRET_MESSAGES_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_MESSAGES_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "messages.g.h"

namespace ferret_messages {

class FerretMessagesPlugin : public flutter::Plugin, public FerretMessagesPluginApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FerretMessagesPlugin();

  virtual ~FerretMessagesPlugin();

  // Disallow copy and assign.
  FerretMessagesPlugin(const FerretMessagesPlugin&) = delete;
  FerretMessagesPlugin& operator=(const FerretMessagesPlugin&) = delete;

  ErrorOr<std::string> GetPlatformVersion() override;
};

}  // namespace ferret_messages

#endif  // FLUTTER_PLUGIN_FERRET_MESSAGES_PLUGIN_H_
