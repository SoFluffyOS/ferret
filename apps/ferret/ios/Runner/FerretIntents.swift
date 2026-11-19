import AppIntents
import UIKit

/// One of your paired devices, as Shortcuts offers it.
@available(iOS 16.0, *)
struct FerretDeviceEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Device"
  static var defaultQuery = FerretDeviceQuery()

  var id: String
  var name: String

  var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

@available(iOS 16.0, *)
struct FerretDeviceQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [FerretDeviceEntity] {
    ShortcutsBridge.devices()
      .filter { identifiers.contains($0.id) }
      .map { FerretDeviceEntity(id: $0.id, name: $0.name) }
  }

  func suggestedEntities() async throws -> [FerretDeviceEntity] {
    ShortcutsBridge.devices().map { FerretDeviceEntity(id: $0.id, name: $0.name) }
  }
}

/// What Ferret answered, as Shortcuts shows it when it didn't work.
@available(iOS 16.0, *)
struct FerretIntentError: Error, CustomLocalizedStringResourceConvertible {
  let answer: [String: Any]

  var localizedStringResource: LocalizedStringResource {
    let device = answer["device"] as? String ?? "That device"
    switch answer["error"] as? String ?? answer["result"] as? String {
    case "not_connected":
      return "\(device) isn't connected right now. Open Ferret on both and try again."
    case "unknown_device":
      return "No paired device has that name."
    case "not_ready":
      return "Ferret didn't start in time. Try again."
    case "nothing_to_send":
      return "There is nothing to send."
    case "not_supported":
      return "Ferret on \(device) can't do that. Update it there."
    default:
      return "It didn't work."
    }
  }
}

@available(iOS 16.0, *)
private func runInFerret(_ arguments: [String: Any]) async throws -> String {
  let answer = await ShortcutsBridge.shared.run(arguments)
  guard answer["ok"] as? Bool == true else {
    throw FerretIntentError(answer: answer)
  }

  return answer["device"] as? String ?? ""
}

/// Sends what you copied to one of your devices, or to all of them.
@available(iOS 16.0, *)
struct SendClipboardIntent: AppIntent {
  static var title: LocalizedStringResource = "Send Clipboard"
  static var description = IntentDescription("Sends what you copied to one of your devices, or to every connected one.")
  static var openAppWhenRun = true

  @Parameter(title: "Device")
  var device: FerretDeviceEntity?

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    let text = UIPasteboard.general.string ?? ""
    var arguments: [String: Any] = ["command": "clipboard_send", "value": text]
    if let device {
      arguments["device"] = device.id
    }

    _ = try await runInFerret(arguments)
    return .result(dialog: "Sent.")
  }
}

/// Rings one of your devices, even when it's on silent.
@available(iOS 16.0, *)
struct RingDeviceIntent: AppIntent {
  static var title: LocalizedStringResource = "Ring Device"
  static var description = IntentDescription("Rings one of your devices so you can find it.")
  static var openAppWhenRun = true

  @Parameter(title: "Device")
  var device: FerretDeviceEntity

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let name = try await runInFerret(["command": "ring", "device": device.id])
    return .result(dialog: "\(name) is ringing.")
  }
}

/// Sends a file to one of your devices.
@available(iOS 16.0, *)
struct SendFileIntent: AppIntent {
  static var title: LocalizedStringResource = "Send File"
  static var description = IntentDescription("Sends a file to one of your devices.")
  static var openAppWhenRun = true

  @Parameter(title: "File")
  var file: IntentFile

  @Parameter(title: "Device")
  var device: FerretDeviceEntity

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let folder = FileManager.default.temporaryDirectory
      .appendingPathComponent("Shortcuts", isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let name = (file.filename as NSString).lastPathComponent
    let destination = folder.appendingPathComponent(name.isEmpty ? "File" : name)
    try file.data.write(to: destination)

    let deviceName = try await runInFerret([
      "command": "send_files",
      "device": device.id,
      "paths": [destination.path],
    ])
    return .result(dialog: "Sending to \(deviceName).")
  }
}

/// Opens a web page on one of your devices.
@available(iOS 16.0, *)
struct OpenLinkIntent: AppIntent {
  static var title: LocalizedStringResource = "Open Link on Device"
  static var description = IntentDescription("Opens a web page or a map link on one of your devices.")
  static var openAppWhenRun = true

  @Parameter(title: "Link")
  var link: URL

  @Parameter(title: "Device")
  var device: FerretDeviceEntity

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let name = try await runInFerret([
      "command": "open",
      "device": device.id,
      "value": link.absoluteString,
    ])
    return .result(dialog: "Opened on \(name).")
  }
}

@available(iOS 16.0, *)
struct FerretShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: SendClipboardIntent(),
      phrases: ["Send clipboard with \(.applicationName)"]
    )
    AppShortcut(
      intent: RingDeviceIntent(),
      phrases: ["Ring my device with \(.applicationName)"]
    )
  }
}
