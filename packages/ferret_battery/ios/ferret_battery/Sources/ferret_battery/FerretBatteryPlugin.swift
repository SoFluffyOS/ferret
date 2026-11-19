import Flutter
import UIKit

/// Reads the battery through UIDevice. Monitoring is on only while Dart
/// listens, or for the moment a single read takes.
public class FerretBatteryPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var observers: [NSObjectProtocol] = []

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretBatteryPlugin()
    let methods = FlutterMethodChannel(
      name: "io.sofluffy.ferret_battery", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methods)
    let events = FlutterEventChannel(
      name: "io.sofluffy.ferret_battery/changes", binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "read" else {
      result(FlutterMethodNotImplemented)
      return
    }

    let device = UIDevice.current
    let wasMonitoring = device.isBatteryMonitoringEnabled
    device.isBatteryMonitoringEnabled = true
    result(level())
    device.isBatteryMonitoringEnabled = wasMonitoring || sink != nil
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    UIDevice.current.isBatteryMonitoringEnabled = true
    let center = NotificationCenter.default
    for name in [
      UIDevice.batteryLevelDidChangeNotification, UIDevice.batteryStateDidChangeNotification,
    ] {
      observers.append(
        center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
          self?.sink?(self?.level())
        })
    }
    events(level())
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    for observer in observers {
      NotificationCenter.default.removeObserver(observer)
    }
    observers.removeAll()
    sink = nil
    UIDevice.current.isBatteryMonitoringEnabled = false
    return nil
  }

  private func level() -> [String: Any]? {
    let device = UIDevice.current
    guard device.batteryLevel >= 0, device.batteryState != .unknown else {
      return nil
    }

    let charging = device.batteryState == .charging || device.batteryState == .full
    return ["percent": Int((device.batteryLevel * 100).rounded()), "charging": charging]
  }
}
