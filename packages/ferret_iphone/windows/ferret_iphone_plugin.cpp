#include "ferret_iphone_plugin.h"

#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include "apple_gatt_client.h"
#include "messages.g.h"

namespace ferret_iphone {

// static
void FerretIphonePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  registrar->AddPlugin(
      std::make_unique<FerretIphonePlugin>(registrar->messenger()));
}

FerretIphonePlugin::FerretIphonePlugin(flutter::BinaryMessenger* messenger)
    : messenger_(messenger),
      client_(std::make_shared<AppleGattClient>(messenger)) {
  AppleGattHostApi::SetUp(messenger_, client_.get());
}

FerretIphonePlugin::~FerretIphonePlugin() {
  AppleGattHostApi::SetUp(messenger_, nullptr);
  client_->Shutdown();
}

}  // namespace ferret_iphone
