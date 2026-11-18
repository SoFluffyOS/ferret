#ifndef FLUTTER_PLUGIN_FERRET_IPHONE_PLUGIN_H_
#define FLUTTER_PLUGIN_FERRET_IPHONE_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace ferret_iphone {

class AppleGattClient;

// Registers the iPhone GATT client (apple_gatt_client.h) with Flutter.
class FerretIphonePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit FerretIphonePlugin(flutter::BinaryMessenger* messenger);

  virtual ~FerretIphonePlugin();

  FerretIphonePlugin(const FerretIphonePlugin&) = delete;
  FerretIphonePlugin& operator=(const FerretIphonePlugin&) = delete;

 private:
  flutter::BinaryMessenger* messenger_;
  std::shared_ptr<AppleGattClient> client_;
};

}  // namespace ferret_iphone

#endif  // FLUTTER_PLUGIN_FERRET_IPHONE_PLUGIN_H_
