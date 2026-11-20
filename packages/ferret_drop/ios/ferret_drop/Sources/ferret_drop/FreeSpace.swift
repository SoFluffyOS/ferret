import Foundation
import Flutter

/// Free space where received files land. The space the system would free
/// for a file the user wants, such as purgeable space, counts.
enum FreeSpace {
  static let channelName = "io.sofluffy.ferret_drop/space"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "freeBytes":
        guard let path = call.arguments as? String else {
          result(nil)
          return
        }
        result(bytes(at: path).map { NSNumber(value: $0) })
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  static func bytes(at path: String) -> Int64? {
    let url = URL(fileURLWithPath: path)
    let values = try? url.resourceValues(forKeys: [
      .volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey,
    ])
    if let important = values?.volumeAvailableCapacityForImportantUsage, important > 0 {
      return important
    }

    return values?.volumeAvailableCapacity.map { Int64($0) }
  }
}
