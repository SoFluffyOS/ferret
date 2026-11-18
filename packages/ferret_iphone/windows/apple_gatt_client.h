#ifndef FLUTTER_PLUGIN_FERRET_IPHONE_APPLE_GATT_CLIENT_H_
#define FLUTTER_PLUGIN_FERRET_IPHONE_APPLE_GATT_CLIENT_H_

// This must be included before many other Windows headers.
#include <windows.h>

#include <winrt/Windows.Devices.Bluetooth.GenericAttributeProfile.h>
#include <winrt/Windows.Devices.Bluetooth.h>
#include <winrt/Windows.Foundation.h>

#include <flutter/binary_messenger.h>

#include <cstdint>
#include <deque>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

#include "messages.g.h"

namespace ferret_iphone {

// A Bluetooth LE GATT client for one iPhone's ANCS and AMS services, on the
// Windows Runtime.
//
// Pigeon calls arrive on Flutter's platform thread, and every reply and every
// touch of the link state happens there too. The Windows Runtime finishes its
// work and raises its events on other threads; coroutines hop back with
// `co_await platform_thread_`, and events go through a queue that the
// platform thread drains, so values reach Dart in the order they came.
//
// The plugin holds it in a shared_ptr and coroutines keep it alive while
// they run, so none of them can outlive the object they touch.
class AppleGattClient : public AppleGattHostApi,
                        public std::enable_shared_from_this<AppleGattClient> {
 public:
  explicit AppleGattClient(flutter::BinaryMessenger* messenger);
  ~AppleGattClient() override;

  AppleGattClient(const AppleGattClient&) = delete;
  AppleGattClient& operator=(const AppleGattClient&) = delete;

  // Closes the link and stops talking to Flutter. Called on the platform
  // thread when the engine goes away.
  void Shutdown();

  void Status(
      std::function<void(ErrorOr<PlatformBluetoothStatus> reply)> result)
      override;
  void Devices(std::function<void(ErrorOr<flutter::EncodableList> reply)>
                   result) override;
  void Connect(const std::string& device_id,
               std::function<void(ErrorOr<PlatformAppleServices> reply)> result)
      override;
  void Disconnect(
      std::function<void(std::optional<FlutterError> reply)> result) override;
  void Write(const std::string& characteristic,
             const std::vector<uint8_t>& value,
             std::function<void(std::optional<FlutterError> reply)> result)
      override;
  void Read(const std::string& characteristic,
            std::function<void(ErrorOr<std::vector<uint8_t>> reply)> result)
      override;
  void SetNotify(const std::string& characteristic,
                 bool enabled,
                 std::function<void(std::optional<FlutterError> reply)> result)
      override;
  std::optional<FlutterError> OpenBluetoothSettings() override;

 private:
  using GattCharacteristic = winrt::Windows::Devices::Bluetooth::
      GenericAttributeProfile::GattCharacteristic;
  using GattDeviceService = winrt::Windows::Devices::Bluetooth::
      GenericAttributeProfile::GattDeviceService;
  using GattSession =
      winrt::Windows::Devices::Bluetooth::GenericAttributeProfile::GattSession;
  using BluetoothLEDevice = winrt::Windows::Devices::Bluetooth::BluetoothLEDevice;

  // Something the Windows Runtime reported on one of its own threads.
  struct Event {
    // The link this event belongs to; events of an older link are dropped.
    uint64_t generation = 0;
    // Empty for "the link dropped".
    std::string characteristic;
    std::vector<uint8_t> value;
  };

  winrt::fire_and_forget StatusAsync(
      std::function<void(ErrorOr<PlatformBluetoothStatus> reply)> result);
  winrt::fire_and_forget DevicesAsync(
      std::function<void(ErrorOr<flutter::EncodableList> reply)> result);
  winrt::fire_and_forget ConnectAsync(
      std::string device_id,
      std::function<void(ErrorOr<PlatformAppleServices> reply)> result);
  winrt::fire_and_forget WriteAsync(
      GattCharacteristic characteristic,
      std::vector<uint8_t> value,
      std::function<void(std::optional<FlutterError> reply)> result);
  winrt::fire_and_forget ReadAsync(
      GattCharacteristic characteristic,
      std::function<void(ErrorOr<std::vector<uint8_t>> reply)> result);
  winrt::fire_and_forget SetNotifyAsync(
      std::string uuid,
      GattCharacteristic characteristic,
      bool enabled,
      std::function<void(std::optional<FlutterError> reply)> result);
  winrt::fire_and_forget DrainEvents();

  // Queues an event from any thread and wakes the platform thread.
  void Post(Event event);
  // The characteristic named by an upper-case UUID, if the link has it.
  std::optional<GattCharacteristic> Find(const std::string& uuid) const;
  // The error for an operation on a characteristic the link doesn't have.
  FlutterError Unavailable() const;
  bool HasAll(const std::vector<std::string>& uuids) const;
  // Forgets the link and frees what Windows holds for it.
  void ClearLink();

  winrt::apartment_context platform_thread_;
  std::unique_ptr<AppleGattFlutterApi> flutter_api_;
  bool shut_down_ = false;

  // Counts links, so work started for an older one can tell it is stale.
  uint64_t generation_ = 0;
  std::string device_id_;
  BluetoothLEDevice device_{nullptr};
  GattSession session_{nullptr};
  std::vector<GattDeviceService> services_;
  std::map<std::string, GattCharacteristic> characteristics_;
  std::map<std::string, winrt::event_token> value_tokens_;
  winrt::event_token status_token_{};

  std::mutex events_mutex_;
  std::deque<Event> events_;
};

}  // namespace ferret_iphone

#endif  // FLUTTER_PLUGIN_FERRET_IPHONE_APPLE_GATT_CLIENT_H_
