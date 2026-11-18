import Cocoa
import CoreBluetooth
import FlutterMacOS
import Security

/// A CoreBluetooth central for one iPhone's ANCS and AMS services.
///
/// Everything runs on the main thread: pigeon calls in from a main-actor
/// task, and the central manager delivers its delegate calls on the main
/// queue.
final class AppleGattCentral: NSObject, AppleGattHostApi, CBCentralManagerDelegate,
  CBPeripheralDelegate
{
  private static let ancsService = CBUUID(string: "7905F431-B5CE-4E99-A40F-4B1E122D00D0")
  private static let amsService = CBUUID(string: "89D3502B-0F36-433A-8EF4-C502AD55F8DC")
  private static let ancsCharacteristics = [
    CBUUID(string: "9FBF120D-6301-42D9-8C58-25E699A21DBD"),
    CBUUID(string: "69D1D8F3-45E1-49A8-9821-9BBDFDAAD9D9"),
    CBUUID(string: "22EAC6E9-24D6-4BB5-BE44-B36ACE7C7BFB"),
  ]
  private static let amsCharacteristics = [
    CBUUID(string: "9B3C81D8-57B1-4A8A-B8DF-0E56F7CA51C2"),
    CBUUID(string: "2F7CABCE-808D-411F-9A0C-BB92BA96C102"),
    CBUUID(string: "C6B2F38C-23AB-46D8-A6AB-A3A870BBD5D7"),
  ]
  private static let stateWait: TimeInterval = 3

  private let valueChannel: FlutterBasicMessageChannel
  private let disconnectChannel: FlutterBasicMessageChannel

  private var central: CBCentralManager?
  private var stateWaiters: [CheckedContinuation<Void, Never>] = []
  private var peripheral: CBPeripheral?
  private var characteristics: [CBUUID: CBCharacteristic] = [:]
  private var pendingServices = 0
  private var connecting: CheckedContinuation<PlatformAppleServices, Error>?
  private var writes: [CBUUID: [CheckedContinuation<Void, Error>]] = [:]
  private var reads: [CBUUID: [CheckedContinuation<FlutterStandardTypedData, Error>]] = [:]
  private var notifies: [CBUUID: [CheckedContinuation<Void, Error>]] = [:]

  init(messenger: FlutterBinaryMessenger) {
    // Values go out on the pigeon channels directly: sending is synchronous,
    // so the packets of a split answer reach Dart in the order they came.
    let prefix = "dev.flutter.pigeon.ferret_iphone.AppleGattFlutterApi."
    valueChannel = FlutterBasicMessageChannel(
      name: prefix + "onValue", binaryMessenger: messenger, codec: AppleGattHostApiSetup.codec)
    disconnectChannel = FlutterBasicMessageChannel(
      name: prefix + "onDisconnected", binaryMessenger: messenger,
      codec: AppleGattHostApiSetup.codec)
    super.init()
  }

  // MARK: - AppleGattHostApi

  @MainActor
  func status() async throws -> PlatformBluetoothStatus {
    guard Self.isConfigured else {
      return .notConfigured
    }

    let central = ensureCentral()
    if central.state == .unknown || central.state == .resetting {
      await waitForState()
    }

    switch central.state {
    case .poweredOn:
      return .ready
    case .unauthorized:
      return .unauthorized
    case .unsupported:
      return .unsupported
    default:
      return .off
    }
  }

  @MainActor
  func devices() async throws -> [PlatformBondedDevice] {
    guard try await status() == .ready, let central = central else {
      return []
    }

    let connected = central.retrieveConnectedPeripherals(withServices: [
      Self.ancsService, Self.amsService,
    ])
    return connected.map { peripheral in
      PlatformBondedDevice(
        id: peripheral.identifier.uuidString, name: peripheral.name ?? "", connected: true)
    }
  }

  @MainActor
  func connect(deviceId: String) async throws -> PlatformAppleServices {
    guard try await status() == .ready, let central = central else {
      throw Self.failure("not_connected")
    }

    dropLink(notify: false)
    guard let identifier = UUID(uuidString: deviceId),
      let found = central.retrievePeripherals(withIdentifiers: [identifier]).first
    else {
      throw Self.failure("not_connected")
    }

    found.delegate = self
    peripheral = found
    return try await withCheckedThrowingContinuation { continuation in
      connecting = continuation
      central.connect(found, options: nil)
    }
  }

  @MainActor
  func disconnect() async throws {
    dropLink(notify: false)
  }

  @MainActor
  func write(characteristic: String, value: FlutterStandardTypedData) async throws {
    let (peripheral, target) = try resolve(characteristic)
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      writes[target.uuid, default: []].append(continuation)
      peripheral.writeValue(value.data, for: target, type: .withResponse)
    }
  }

  @MainActor
  func read(characteristic: String) async throws -> FlutterStandardTypedData {
    let (peripheral, target) = try resolve(characteristic)
    return try await withCheckedThrowingContinuation { continuation in
      reads[target.uuid, default: []].append(continuation)
      peripheral.readValue(for: target)
    }
  }

  @MainActor
  func setNotify(characteristic: String, enabled: Bool) async throws {
    let (peripheral, target) = try resolve(characteristic)
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      notifies[target.uuid, default: []].append(continuation)
      peripheral.setNotifyValue(enabled, for: target)
    }
  }

  func openBluetoothSettings() throws {
    guard let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings"),
      NSWorkspace.shared.open(url)
    else {
      throw Self.failure("failed")
    }
  }

  // MARK: - CBCentralManagerDelegate

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    resumeStateWaiters()
    if central.state != .poweredOn {
      dropLink(notify: true)
    }
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    guard peripheral === self.peripheral else {
      return
    }

    peripheral.discoverServices([Self.ancsService, Self.amsService])
  }

  func centralManager(
    _ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?
  ) {
    guard peripheral === self.peripheral else {
      return
    }

    dropLink(notify: false)
  }

  func centralManager(
    _ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?
  ) {
    guard peripheral === self.peripheral else {
      return
    }

    dropLink(notify: true)
  }

  // MARK: - CBPeripheralDelegate

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard peripheral === self.peripheral else {
      return
    }

    let services = peripheral.services ?? []
    pendingServices = services.count
    if services.isEmpty {
      finishConnecting()
      return
    }

    for service in services {
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?
  ) {
    guard peripheral === self.peripheral else {
      return
    }

    for characteristic in service.characteristics ?? [] {
      characteristics[characteristic.uuid] = characteristic
    }

    pendingServices -= 1
    if pendingServices <= 0 {
      finishConnecting()
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?
  ) {
    guard peripheral === self.peripheral, var waiting = writes[characteristic.uuid],
      !waiting.isEmpty
    else {
      return
    }

    let continuation = waiting.removeFirst()
    writes[characteristic.uuid] = waiting
    Self.finish(continuation, error: error)
  }

  func peripheral(
    _ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    guard peripheral === self.peripheral, var waiting = notifies[characteristic.uuid],
      !waiting.isEmpty
    else {
      return
    }

    let continuation = waiting.removeFirst()
    notifies[characteristic.uuid] = waiting
    Self.finish(continuation, error: error)
  }

  func peripheral(
    _ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?
  ) {
    guard peripheral === self.peripheral else {
      return
    }

    // A read and a notification both land here; a waiting read takes it.
    if var waiting = reads[characteristic.uuid], !waiting.isEmpty {
      let continuation = waiting.removeFirst()
      reads[characteristic.uuid] = waiting
      if let error = error {
        continuation.resume(throwing: Self.failure(for: error))
        return
      }

      continuation.resume(
        returning: FlutterStandardTypedData(bytes: characteristic.value ?? Data()))
      return
    }

    guard error == nil, let value = characteristic.value else {
      return
    }

    valueChannel.sendMessage([
      characteristic.uuid.uuidString, FlutterStandardTypedData(bytes: value),
    ])
  }

  // MARK: - Private

  /// Creating the manager without the usage string makes macOS kill the
  /// app, and without the sandbox entitlement Bluetooth is never allowed.
  private static var isConfigured: Bool {
    guard Bundle.main.object(forInfoDictionaryKey: "NSBluetoothAlwaysUsageDescription") != nil
    else {
      return false
    }

    guard let task = SecTaskCreateFromSelf(nil) else {
      return true
    }

    let sandboxed =
      SecTaskCopyValueForEntitlement(task, "com.apple.security.app-sandbox" as CFString, nil)
      as? Bool ?? false
    if !sandboxed {
      return true
    }

    return SecTaskCopyValueForEntitlement(
      task, "com.apple.security.device.bluetooth" as CFString, nil) as? Bool ?? false
  }

  private func ensureCentral() -> CBCentralManager {
    if let central = central {
      return central
    }

    let created = CBCentralManager(delegate: self, queue: nil)
    central = created
    return created
  }

  private func waitForState() async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      stateWaiters.append(continuation)
      perform(#selector(resumeStateWaiters), with: nil, afterDelay: Self.stateWait)
    }
  }

  @objc private func resumeStateWaiters() {
    let waiting = stateWaiters
    stateWaiters = []
    for continuation in waiting {
      continuation.resume()
    }
  }

  private func resolve(_ characteristic: String) throws -> (CBPeripheral, CBCharacteristic) {
    guard let peripheral = peripheral, peripheral.state == .connected else {
      throw Self.failure("not_connected")
    }

    guard let target = characteristics[CBUUID(string: characteristic)] else {
      throw Self.failure("missing")
    }

    return (peripheral, target)
  }

  private func finishConnecting() {
    guard let continuation = connecting else {
      return
    }

    connecting = nil
    let hasAll: ([CBUUID]) -> Bool = { uuids in
      uuids.allSatisfy { self.characteristics[$0] != nil }
    }
    continuation.resume(
      returning: PlatformAppleServices(
        hasAncs: hasAll(Self.ancsCharacteristics), hasAms: hasAll(Self.amsCharacteristics)))
  }

  /// Forgets the link and fails everything that waits on it. With `notify`,
  /// tells Dart that an established link dropped.
  private func dropLink(notify: Bool) {
    guard let dropped = peripheral else {
      return
    }

    peripheral = nil
    characteristics = [:]
    pendingServices = 0
    dropped.delegate = nil
    central?.cancelPeripheralConnection(dropped)

    let error = Self.failure("not_connected")
    let wasConnecting = connecting != nil
    connecting?.resume(throwing: error)
    connecting = nil
    for continuation in writes.values.joined() {
      continuation.resume(throwing: error)
    }
    for continuation in notifies.values.joined() {
      continuation.resume(throwing: error)
    }
    for continuation in reads.values.joined() {
      continuation.resume(throwing: error)
    }
    writes = [:]
    notifies = [:]
    reads = [:]

    if notify && !wasConnecting {
      disconnectChannel.sendMessage([dropped.identifier.uuidString])
    }
  }

  private static func finish(_ continuation: CheckedContinuation<Void, Error>, error: Error?) {
    if let error = error {
      continuation.resume(throwing: failure(for: error))
      return
    }

    continuation.resume()
  }

  private static func failure(_ code: String, details: Int? = nil) -> PigeonError {
    PigeonError(code: code, message: nil, details: details)
  }

  /// An iPhone answers a link that isn't bonded with an authentication or
  /// encryption error; ANCS and AMS use the 0xA0 range for their own.
  private static func failure(for error: Error) -> PigeonError {
    let native = error as NSError
    guard native.domain == CBATTErrorDomain else {
      return failure("failed")
    }

    switch CBATTError.Code(rawValue: native.code) {
    case .insufficientAuthentication, .insufficientAuthorization, .insufficientEncryption,
      .insufficientEncryptionKeySize:
      return failure("not_bonded")
    default:
      return failure("att", details: native.code)
    }
  }
}
