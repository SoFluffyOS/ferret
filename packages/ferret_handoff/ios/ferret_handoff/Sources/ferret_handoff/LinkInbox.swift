import Foundation

/// Links and text Ferret's iOS Share extension left in the App Group folder
/// it shares with the app (see `ShareHandoff.swift` in the app's Share
/// target). Each request names the devices picked in the share sheet; none
/// means Ferret picks, or asks.
final class LinkInbox {
  private let root: URL?
  private let files = FileManager.default

  init(bundle: Bundle = .main) {
    guard
      let group = bundle.object(forInfoDictionaryKey: "FerretShareGroup") as? String,
      !group.isEmpty,
      let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: group)
    else {
      root = nil
      return
    }

    root = container.appendingPathComponent("Share", isDirectory: true)
  }

  /// Every request left, oldest first, one item per picked device. Each is
  /// returned once.
  func take() -> [SharedItem] {
    guard let links = root?.appendingPathComponent("Links", isDirectory: true),
      let found = try? files.contentsOfDirectory(at: links, includingPropertiesForKeys: nil)
    else {
      return []
    }

    let oldestFirst = found.filter { $0.pathExtension == "json" }.sorted {
      $0.lastPathComponent < $1.lastPathComponent
    }
    var taken: [SharedItem] = []
    for file in oldestFirst {
      let data = try? Data(contentsOf: file)
      try? files.removeItem(at: file)
      guard let data = data, let request = try? JSONDecoder().decode(Request.self, from: data)
      else {
        continue
      }

      taken.append(contentsOf: items(from: request))
    }

    return taken
  }

  private func items(from request: Request) -> [SharedItem] {
    let devices: [String?] = request.deviceIds.isEmpty ? [nil] : request.deviceIds
    return devices.map { deviceId in
      SharedItem(
        origin: .shareSheet, targetDeviceId: deviceId, text: request.text,
        createdAtMs: request.createdAtMs)
    }
  }

  private struct Request: Decodable {
    let text: String
    let deviceIds: [String]
    let createdAtMs: Int64
  }
}
