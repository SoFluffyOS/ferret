import Flutter
import Foundation

/// Carries Shortcuts requests to Dart, which answers them with the same
/// commands as `ferret-cli`, and keeps the device list Shortcuts offers.
/// Requests that come before Dart is ready wait for it.
final class ShortcutsBridge {
  static let shared = ShortcutsBridge()

  static let devicesKey = "ferret.shortcuts.devices"
  private static let patience: TimeInterval = 20

  private var channel: FlutterMethodChannel?
  private var ready = false
  private var waiting: [(arguments: [String: Any], done: ([String: Any]) -> Void)] = []

  func attach(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "io.sofluffy.ferret/shortcuts", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    self.channel = channel
  }

  /// The paired devices as Dart last listed them: id and name.
  static func devices() -> [(id: String, name: String)] {
    let stored = UserDefaults.standard.array(forKey: devicesKey) as? [[String: String]] ?? []
    return stored.compactMap { entry in
      guard let id = entry["id"], let name = entry["name"] else { return nil }
      return (id: id, name: name)
    }
  }

  /// Asks Dart to run a command and waits for its answer.
  func run(_ arguments: [String: Any]) async -> [String: Any] {
    await withCheckedContinuation { continuation in
      var finished = false
      let finish: ([String: Any]) -> Void = { answer in
        guard !finished else { return }
        finished = true
        continuation.resume(returning: answer)
      }

      DispatchQueue.main.async {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.patience) {
          finish(["ok": false, "error": "not_ready"])
        }
        guard self.ready, self.channel != nil else {
          self.waiting.append((arguments: arguments, done: finish))
          return
        }

        self.send(arguments, done: finish)
      }
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "ready":
      ready = true
      let pending = waiting
      waiting.removeAll()
      for request in pending {
        send(request.arguments, done: request.done)
      }
      result(nil)
    case "setDevices":
      let devices = (call.arguments as? [[String: Any]] ?? []).compactMap { entry -> [String: String]? in
        guard let id = entry["id"] as? String, let name = entry["name"] as? String else { return nil }
        return ["id": id, "name": name]
      }
      UserDefaults.standard.set(devices, forKey: Self.devicesKey)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func send(_ arguments: [String: Any], done: @escaping ([String: Any]) -> Void) {
    channel?.invokeMethod("run", arguments: arguments) { answer in
      done(answer as? [String: Any] ?? ["ok": false, "error": "failed"])
    }
  }
}
