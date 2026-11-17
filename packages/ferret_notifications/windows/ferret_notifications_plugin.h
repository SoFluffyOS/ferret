#ifndef FLUTTER_PLUGIN_FERRET_NOTIFICATIONS_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_NOTIFICATIONS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "messages.g.h"

namespace ferret_notifications {

class FerretNotificationsPlugin : public flutter::Plugin, public FerretNotificationsPluginApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FerretNotificationsPlugin();

  virtual ~FerretNotificationsPlugin();

  // Disallow copy and assign.
  FerretNotificationsPlugin(const FerretNotificationsPlugin&) = delete;
  FerretNotificationsPlugin& operator=(const FerretNotificationsPlugin&) = delete;

  ErrorOr<std::string> GetPlatformVersion() override;
};

}  // namespace ferret_notifications

#endif  // FLUTTER_PLUGIN_FERRET_NOTIFICATIONS_PLUGIN_H_
