#include "apple_gatt_client.h"

#include <shellapi.h>

#include <winrt/Windows.Devices.Enumeration.h>
#include <winrt/Windows.Devices.Radios.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.Streams.h>

#include <flutter/encodable_value.h>

#include <array>
#include <cctype>
#include <set>
#include <utility>

namespace ferret_iphone {

namespace {

using winrt::Windows::Devices::Bluetooth::BluetoothAdapter;
using winrt::Windows::Devices::Bluetooth::BluetoothCacheMode;
using winrt::Windows::Devices::Bluetooth::BluetoothConnectionStatus;
using winrt::Windows::Devices::Bluetooth::BluetoothDevice;
using winrt::Windows::Devices::Bluetooth::BluetoothLEDevice;
using winrt::Windows::Devices::Bluetooth::GenericAttributeProfile::
    GattCharacteristic;
using winrt::Windows::Devices::Bluetooth::GenericAttributeProfile::
    GattClientCharacteristicConfigurationDescriptorValue;
using winrt::Windows::Devices::Bluetooth::GenericAttributeProfile::
    GattCommunicationStatus;
using winrt::Windows::Devices::Bluetooth::GenericAttributeProfile::
    GattDeviceService;
using winrt::Windows::Devices::Bluetooth::GenericAttributeProfile::GattSession;
using winrt::Windows::Devices::Bluetooth::GenericAttributeProfile::
    GattValueChangedEventArgs;
using winrt::Windows::Devices::Bluetooth::GenericAttributeProfile::
    GattWriteOption;
using winrt::Windows::Devices::Enumeration::DeviceInformation;
using winrt::Windows::Devices::Radios::RadioState;
using winrt::Windows::Foundation::IInspectable;
using winrt::Windows::Foundation::IReference;
using winrt::Windows::Storage::Streams::DataReader;
using winrt::Windows::Storage::Streams::DataWriter;
using winrt::Windows::Storage::Streams::IBuffer;

constexpr wchar_t kIsConnectedProperty[] = L"System.Devices.Aep.IsConnected";
constexpr wchar_t kAddressProperty[] = L"System.Devices.Aep.DeviceAddress";

// A device paired over classic Bluetooth has no LE device id; it is named by
// its address instead, which an iPhone shares between the two.
constexpr char kAddressPrefix[] = "address:";

constexpr winrt::guid kAncsService{
    0x7905F431,
    0xB5CE,
    0x4E99,
    {0xA4, 0x0F, 0x4B, 0x1E, 0x12, 0x2D, 0x00, 0xD0}};
constexpr winrt::guid kAmsService{
    0x89D3502B,
    0x0F36,
    0x433A,
    {0x8E, 0xF4, 0xC5, 0x02, 0xAD, 0x55, 0xF8, 0xDC}};

struct NamedCharacteristic {
  const char* name;
  winrt::guid uuid;
};

// The names are the UUIDs in upper case, as Dart sends them.
constexpr NamedCharacteristic kCharacteristics[] = {
    {"9FBF120D-6301-42D9-8C58-25E699A21DBD",
     {0x9FBF120D,
      0x6301,
      0x42D9,
      {0x8C, 0x58, 0x25, 0xE6, 0x99, 0xA2, 0x1D, 0xBD}}},
    {"69D1D8F3-45E1-49A8-9821-9BBDFDAAD9D9",
     {0x69D1D8F3,
      0x45E1,
      0x49A8,
      {0x98, 0x21, 0x9B, 0xBD, 0xFD, 0xAA, 0xD9, 0xD9}}},
    {"22EAC6E9-24D6-4BB5-BE44-B36ACE7C7BFB",
     {0x22EAC6E9,
      0x24D6,
      0x4BB5,
      {0xBE, 0x44, 0xB3, 0x6A, 0xCE, 0x7C, 0x7B, 0xFB}}},
    {"9B3C81D8-57B1-4A8A-B8DF-0E56F7CA51C2",
     {0x9B3C81D8,
      0x57B1,
      0x4A8A,
      {0xB8, 0xDF, 0x0E, 0x56, 0xF7, 0xCA, 0x51, 0xC2}}},
    {"2F7CABCE-808D-411F-9A0C-BB92BA96C102",
     {0x2F7CABCE,
      0x808D,
      0x411F,
      {0x9A, 0x0C, 0xBB, 0x92, 0xBA, 0x96, 0xC1, 0x02}}},
    {"C6B2F38C-23AB-46D8-A6AB-A3A870BBD5D7",
     {0xC6B2F38C,
      0x23AB,
      0x46D8,
      {0xA6, 0xAB, 0xA3, 0xA8, 0x70, 0xBB, 0xD5, 0xD7}}},
};

const std::vector<std::string> kAncsCharacteristics = {
    kCharacteristics[0].name, kCharacteristics[1].name,
    kCharacteristics[2].name};
const std::vector<std::string> kAmsCharacteristics = {
    kCharacteristics[3].name, kCharacteristics[4].name,
    kCharacteristics[5].name};

// ATT errors that mean "this link isn't bonded and encrypted": insufficient
// authentication, authorization, encryption key size and encryption.
constexpr uint8_t kBondingErrors[] = {0x05, 0x08, 0x0C, 0x0F};

FlutterError NotConnected() {
  return FlutterError("not_connected", "There is no link to the iPhone.");
}

FlutterError NotBonded() {
  return FlutterError("not_bonded", "The iPhone refused: the link isn't bonded.");
}

FlutterError Failed() {
  return FlutterError("failed", "The Bluetooth operation failed.");
}

std::optional<std::string> NameOf(const winrt::guid& uuid) {
  for (const auto& known : kCharacteristics) {
    if (known.uuid == uuid) {
      return std::string(known.name);
    }
  }

  return std::nullopt;
}

std::optional<FlutterError> ErrorOf(GattCommunicationStatus status,
                                    const IReference<uint8_t>& protocol_error) {
  switch (status) {
    case GattCommunicationStatus::Success:
      return std::nullopt;
    case GattCommunicationStatus::Unreachable:
      return NotConnected();
    case GattCommunicationStatus::AccessDenied:
      return NotBonded();
    case GattCommunicationStatus::ProtocolError: {
      if (!protocol_error) {
        return Failed();
      }

      const uint8_t code = protocol_error.Value();
      for (const uint8_t bonding_error : kBondingErrors) {
        if (code == bonding_error) {
          return NotBonded();
        }
      }

      return FlutterError("att", "The iPhone answered with an ATT error.",
                          flutter::EncodableValue(static_cast<int32_t>(code)));
    }
  }

  return Failed();
}

std::vector<uint8_t> BytesOf(const IBuffer& buffer) {
  if (!buffer || buffer.Length() == 0) {
    return {};
  }

  std::vector<uint8_t> bytes(buffer.Length());
  DataReader::FromBuffer(buffer).ReadBytes(bytes);
  return bytes;
}

bool FlagOf(const DeviceInformation& info, const wchar_t* property) {
  const IInspectable value = info.Properties().TryLookup(property);
  if (!value) {
    return false;
  }

  return winrt::unbox_value_or<bool>(value, false);
}

// The address as twelve upper-case hex digits, or empty when unknown.
std::string AddressOf(const DeviceInformation& info) {
  const IInspectable value = info.Properties().TryLookup(kAddressProperty);
  if (!value) {
    return {};
  }

  std::string digits;
  for (const char character :
       winrt::to_string(winrt::unbox_value_or<winrt::hstring>(value, L""))) {
    if (std::isxdigit(static_cast<unsigned char>(character))) {
      digits.push_back(
          static_cast<char>(std::toupper(static_cast<unsigned char>(character))));
    }
  }

  if (digits.size() != 12) {
    return {};
  }

  return digits;
}

std::optional<uint64_t> AddressFromId(const std::string& device_id) {
  const std::string prefix(kAddressPrefix);
  if (device_id.compare(0, prefix.size(), prefix) != 0) {
    return std::nullopt;
  }

  try {
    return std::stoull(device_id.substr(prefix.size()), nullptr, 16);
  } catch (const std::exception&) {
    return std::nullopt;
  }
}

}  // namespace

AppleGattClient::AppleGattClient(flutter::BinaryMessenger* messenger)
    : flutter_api_(std::make_unique<AppleGattFlutterApi>(messenger)) {}

AppleGattClient::~AppleGattClient() = default;

void AppleGattClient::Shutdown() {
  shut_down_ = true;
  ClearLink();
}

void AppleGattClient::Status(
    std::function<void(ErrorOr<PlatformBluetoothStatus> reply)> result) {
  StatusAsync(std::move(result));
}

void AppleGattClient::Devices(
    std::function<void(ErrorOr<flutter::EncodableList> reply)> result) {
  DevicesAsync(std::move(result));
}

void AppleGattClient::Connect(
    const std::string& device_id,
    std::function<void(ErrorOr<PlatformAppleServices> reply)> result) {
  ClearLink();
  device_id_ = device_id;
  ConnectAsync(device_id, std::move(result));
}

void AppleGattClient::Disconnect(
    std::function<void(std::optional<FlutterError> reply)> result) {
  ClearLink();
  result(std::nullopt);
}

void AppleGattClient::Write(
    const std::string& characteristic,
    const std::vector<uint8_t>& value,
    std::function<void(std::optional<FlutterError> reply)> result) {
  const auto target = Find(characteristic);
  if (!target) {
    result(Unavailable());
    return;
  }

  WriteAsync(*target, value, std::move(result));
}

void AppleGattClient::Read(
    const std::string& characteristic,
    std::function<void(ErrorOr<std::vector<uint8_t>> reply)> result) {
  const auto target = Find(characteristic);
  if (!target) {
    result(Unavailable());
    return;
  }

  ReadAsync(*target, std::move(result));
}

void AppleGattClient::SetNotify(
    const std::string& characteristic,
    bool enabled,
    std::function<void(std::optional<FlutterError> reply)> result) {
  const auto target = Find(characteristic);
  if (!target) {
    result(Unavailable());
    return;
  }

  // The handler goes on before the iPhone is told to notify, so the first
  // values aren't missed.
  if (enabled && value_tokens_.find(characteristic) == value_tokens_.end()) {
    try {
      value_tokens_[characteristic] = target->ValueChanged(
          [weak = weak_from_this(), generation = generation_,
           uuid = characteristic](const GattCharacteristic&,
                                  const GattValueChangedEventArgs& args) {
            if (auto client = weak.lock()) {
              client->Post(
                  Event{generation, uuid, BytesOf(args.CharacteristicValue())});
            }
          });
    } catch (...) {
      result(Failed());
      return;
    }
  }

  SetNotifyAsync(characteristic, *target, enabled, std::move(result));
}

std::optional<FlutterError> AppleGattClient::OpenBluetoothSettings() {
  const HINSTANCE opened = ShellExecuteW(nullptr, L"open",
                                         L"ms-settings:bluetooth", nullptr,
                                         nullptr, SW_SHOWNORMAL);
  if (reinterpret_cast<INT_PTR>(opened) <= 32) {
    return Failed();
  }

  return std::nullopt;
}

winrt::fire_and_forget AppleGattClient::StatusAsync(
    std::function<void(ErrorOr<PlatformBluetoothStatus> reply)> result) {
  const auto self = shared_from_this();
  PlatformBluetoothStatus status = PlatformBluetoothStatus::kUnsupported;
  try {
    const BluetoothAdapter adapter = co_await BluetoothAdapter::GetDefaultAsync();
    if (adapter && adapter.IsLowEnergySupported() &&
        adapter.IsCentralRoleSupported()) {
      status = PlatformBluetoothStatus::kReady;
      const auto radio = co_await adapter.GetRadioAsync();
      if (radio && radio.State() != RadioState::On) {
        status = PlatformBluetoothStatus::kOff;
      }
    }
  } catch (...) {
    status = PlatformBluetoothStatus::kUnsupported;
  }

  co_await platform_thread_;
  if (shut_down_) {
    co_return;
  }

  result(status);
}

winrt::fire_and_forget AppleGattClient::DevicesAsync(
    std::function<void(ErrorOr<flutter::EncodableList> reply)> result) {
  const auto self = shared_from_this();
  flutter::EncodableList devices;
  bool failed = false;
  try {
    const auto properties = winrt::single_threaded_vector<winrt::hstring>(
        {winrt::hstring(kIsConnectedProperty), winrt::hstring(kAddressProperty)});
    std::set<std::string> listed_addresses;

    const auto low_energy = co_await DeviceInformation::FindAllAsync(
        BluetoothLEDevice::GetDeviceSelectorFromPairingState(true), properties);
    for (const DeviceInformation& info : low_energy) {
      listed_addresses.insert(AddressOf(info));
      devices.push_back(flutter::CustomEncodableValue(PlatformBondedDevice(
          winrt::to_string(info.Id()), winrt::to_string(info.Name()),
          FlagOf(info, kIsConnectedProperty))));
    }

    // An iPhone paired from Windows Settings is often listed as a classic
    // device only. Its LE side has the same address.
    const auto classic = co_await DeviceInformation::FindAllAsync(
        BluetoothDevice::GetDeviceSelectorFromPairingState(true), properties);
    for (const DeviceInformation& info : classic) {
      const std::string address = AddressOf(info);
      if (address.empty() || listed_addresses.count(address) > 0) {
        continue;
      }

      listed_addresses.insert(address);
      devices.push_back(flutter::CustomEncodableValue(PlatformBondedDevice(
          kAddressPrefix + address, winrt::to_string(info.Name()),
          FlagOf(info, kIsConnectedProperty))));
    }
  } catch (...) {
    failed = true;
  }

  co_await platform_thread_;
  if (shut_down_) {
    co_return;
  }

  if (failed) {
    result(Failed());
    co_return;
  }

  result(std::move(devices));
}

winrt::fire_and_forget AppleGattClient::ConnectAsync(
    std::string device_id,
    std::function<void(ErrorOr<PlatformAppleServices> reply)> result) {
  const auto self = shared_from_this();
  const uint64_t generation = generation_;
  BluetoothLEDevice device{nullptr};
  GattSession session{nullptr};
  std::vector<GattDeviceService> services;
  std::map<std::string, GattCharacteristic> characteristics;
  std::optional<FlutterError> error;
  const std::array<winrt::guid, 2> service_uuids{kAncsService, kAmsService};
  try {
    if (const auto address = AddressFromId(device_id)) {
      device = co_await BluetoothLEDevice::FromBluetoothAddressAsync(*address);
    } else {
      device =
          co_await BluetoothLEDevice::FromIdAsync(winrt::to_hstring(device_id));
    }

    if (!device) {
      error = NotConnected();
    } else {
      // Keeps Windows trying to hold the link, and reconnecting after the
      // iPhone comes back in reach.
      session = co_await GattSession::FromDeviceIdAsync(device.BluetoothDeviceId());
      if (session && session.CanMaintainConnection()) {
        session.MaintainConnection(true);
      }

      for (const winrt::guid& service_uuid : service_uuids) {
        const auto found = co_await device.GetGattServicesForUuidAsync(
            service_uuid, BluetoothCacheMode::Uncached);
        if (found.Status() == GattCommunicationStatus::Unreachable) {
          error = NotConnected();
          break;
        }

        if (found.Status() != GattCommunicationStatus::Success) {
          continue;
        }

        for (const GattDeviceService& service : found.Services()) {
          services.push_back(service);
          const auto listed =
              co_await service.GetCharacteristicsAsync(BluetoothCacheMode::Uncached);
          if (listed.Status() != GattCommunicationStatus::Success) {
            continue;
          }

          for (const GattCharacteristic& characteristic :
               listed.Characteristics()) {
            if (const auto name = NameOf(characteristic.Uuid())) {
              characteristics.insert_or_assign(*name, characteristic);
            }
          }
        }
      }
    }
  } catch (...) {
    error = Failed();
  }

  co_await platform_thread_;
  const bool stale = shut_down_ || generation != generation_;
  if (stale && !error) {
    error = NotConnected();
  }

  if (error) {
    try {
      for (const GattDeviceService& service : services) {
        service.Close();
      }

      if (session) {
        session.Close();
      }

      if (device) {
        device.Close();
      }
    } catch (...) {
    }

    if (!shut_down_) {
      result(*error);
    }

    co_return;
  }

  device_ = device;
  session_ = session;
  services_ = std::move(services);
  characteristics_ = std::move(characteristics);
  try {
    status_token_ = device_.ConnectionStatusChanged(
        [weak = weak_from_this(), generation](const BluetoothLEDevice& sender,
                                              const IInspectable&) {
          if (sender.ConnectionStatus() !=
              BluetoothConnectionStatus::Disconnected) {
            return;
          }

          if (auto client = weak.lock()) {
            client->Post(Event{generation, std::string(), {}});
          }
        });
  } catch (...) {
    ClearLink();
    result(Failed());
    co_return;
  }

  result(PlatformAppleServices(HasAll(kAncsCharacteristics),
                               HasAll(kAmsCharacteristics)));
}

winrt::fire_and_forget AppleGattClient::WriteAsync(
    GattCharacteristic characteristic,
    std::vector<uint8_t> value,
    std::function<void(std::optional<FlutterError> reply)> result) {
  const auto self = shared_from_this();
  std::optional<FlutterError> error;
  try {
    DataWriter writer;
    writer.WriteBytes(value);
    const auto outcome = co_await characteristic.WriteValueWithResultAsync(
        writer.DetachBuffer(), GattWriteOption::WriteWithResponse);
    error = ErrorOf(outcome.Status(), outcome.ProtocolError());
  } catch (...) {
    error = Failed();
  }

  co_await platform_thread_;
  if (shut_down_) {
    co_return;
  }

  result(error);
}

winrt::fire_and_forget AppleGattClient::ReadAsync(
    GattCharacteristic characteristic,
    std::function<void(ErrorOr<std::vector<uint8_t>> reply)> result) {
  const auto self = shared_from_this();
  std::optional<FlutterError> error;
  std::vector<uint8_t> bytes;
  try {
    const auto outcome =
        co_await characteristic.ReadValueAsync(BluetoothCacheMode::Uncached);
    error = ErrorOf(outcome.Status(), outcome.ProtocolError());
    if (!error) {
      bytes = BytesOf(outcome.Value());
    }
  } catch (...) {
    error = Failed();
  }

  co_await platform_thread_;
  if (shut_down_) {
    co_return;
  }

  if (error) {
    result(*error);
    co_return;
  }

  result(std::move(bytes));
}

winrt::fire_and_forget AppleGattClient::SetNotifyAsync(
    std::string uuid,
    GattCharacteristic characteristic,
    bool enabled,
    std::function<void(std::optional<FlutterError> reply)> result) {
  const auto self = shared_from_this();
  const uint64_t generation = generation_;
  std::optional<FlutterError> error;
  try {
    const auto descriptor =
        enabled ? GattClientCharacteristicConfigurationDescriptorValue::Notify
                : GattClientCharacteristicConfigurationDescriptorValue::None;
    const auto outcome = co_await characteristic
        .WriteClientCharacteristicConfigurationDescriptorWithResultAsync(
            descriptor);
    error = ErrorOf(outcome.Status(), outcome.ProtocolError());
  } catch (...) {
    error = Failed();
  }

  co_await platform_thread_;
  if (shut_down_) {
    co_return;
  }

  // Off, or on but refused: nothing should be listening any more.
  const bool keep_handler = enabled && !error;
  const auto token = value_tokens_.find(uuid);
  if (!keep_handler && generation == generation_ &&
      token != value_tokens_.end()) {
    try {
      characteristic.ValueChanged(token->second);
    } catch (...) {
    }

    value_tokens_.erase(token);
  }

  result(error);
}

winrt::fire_and_forget AppleGattClient::DrainEvents() {
  const auto self = shared_from_this();
  co_await platform_thread_;
  if (shut_down_) {
    co_return;
  }

  std::deque<Event> pending;
  {
    const std::lock_guard<std::mutex> lock(events_mutex_);
    pending.swap(events_);
  }

  for (const Event& event : pending) {
    if (event.generation != generation_) {
      continue;
    }

    if (event.characteristic.empty()) {
      const std::string dropped = device_id_;
      ClearLink();
      flutter_api_->OnDisconnected(dropped, [] {}, [](const FlutterError&) {});
      continue;
    }

    flutter_api_->OnValue(event.characteristic, event.value, [] {},
                          [](const FlutterError&) {});
  }
}

void AppleGattClient::Post(Event event) {
  {
    const std::lock_guard<std::mutex> lock(events_mutex_);
    events_.push_back(std::move(event));
  }

  DrainEvents();
}

std::optional<AppleGattClient::GattCharacteristic> AppleGattClient::Find(
    const std::string& uuid) const {
  const auto found = characteristics_.find(uuid);
  if (found == characteristics_.end()) {
    return std::nullopt;
  }

  return found->second;
}

FlutterError AppleGattClient::Unavailable() const {
  if (!device_) {
    return NotConnected();
  }

  return FlutterError("missing", "The iPhone doesn't offer that characteristic.");
}

bool AppleGattClient::HasAll(const std::vector<std::string>& uuids) const {
  for (const std::string& uuid : uuids) {
    if (characteristics_.find(uuid) == characteristics_.end()) {
      return false;
    }
  }

  return true;
}

void AppleGattClient::ClearLink() {
  ++generation_;
  try {
    for (const auto& [uuid, token] : value_tokens_) {
      const auto characteristic = characteristics_.find(uuid);
      if (characteristic != characteristics_.end()) {
        characteristic->second.ValueChanged(token);
      }
    }

    if (device_) {
      device_.ConnectionStatusChanged(status_token_);
    }

    for (const GattDeviceService& service : services_) {
      service.Close();
    }

    if (session_) {
      session_.Close();
    }

    if (device_) {
      device_.Close();
    }
  } catch (...) {
    // The objects of a dead link may throw; they are let go either way.
  }

  value_tokens_.clear();
  characteristics_.clear();
  services_.clear();
  session_ = nullptr;
  device_ = nullptr;
  status_token_ = {};
  device_id_.clear();
}

}  // namespace ferret_iphone
