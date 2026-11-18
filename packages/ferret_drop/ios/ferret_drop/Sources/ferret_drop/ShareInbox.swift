import Foundation

/// The folder the app and its Share extension both reach: the extension is
/// sandboxed, so an App Group container is the only place it can leave
/// copies and requests for the app, and read the device list back.
///
/// The group is named by `FerretShareGroup` in the app's Info.plist; without
/// it there is no Share extension and nothing here does anything. File and
/// folder names start with the time in milliseconds, which orders requests
/// and ages copies without reading file dates.
final class ShareInbox {
  /// A copy nobody collected is dropped after a day, such as when the
  /// device went away before the transfer started.
  private static let staleAfter: TimeInterval = 24 * 60 * 60

  /// An empty folder younger than this may still be filling up: on an
  /// iPad, Ferret can be open next to the app that is sharing.
  private static let fillingFor: TimeInterval = 10 * 60

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

  init(root: URL) {
    self.root = root
  }

  /// Every request the extension left, oldest first. Each is returned once.
  func takeRequests() -> [SharedItems] {
    guard let requests = root?.appendingPathComponent("Requests", isDirectory: true),
      let found = try? files.contentsOfDirectory(at: requests, includingPropertiesForKeys: nil)
    else {
      return []
    }

    let oldestFirst = found.filter { $0.pathExtension == "json" }.sorted {
      $0.lastPathComponent < $1.lastPathComponent
    }
    var taken: [SharedItems] = []
    for file in oldestFirst {
      let data = try? Data(contentsOf: file)
      try? files.removeItem(at: file)
      guard let data = data, let request = try? JSONDecoder().decode(Request.self, from: data)
      else {
        continue
      }

      taken.append(items(from: request))
    }

    removeStaleCopies()
    return taken
  }

  /// Only copies the extension made are Ferret's to delete.
  private func items(from request: Request) -> SharedItems {
    let copies = root?.appendingPathComponent("Files", isDirectory: true).standardizedFileURL.path
    let areCopies = request.paths.allSatisfy { path in
      guard let copies = copies else {
        return false
      }

      return URL(fileURLWithPath: path).standardizedFileURL.path.hasPrefix(copies + "/")
    }

    return SharedItems(
      paths: request.paths, text: nil, deviceId: request.deviceId,
      everyDevice: request.everyDevice, keepFiles: areCopies ? nil : true)
  }

  /// Keeps the list where the extension finds it, since Ferret is never
  /// running to answer while the share sheet is up.
  func write(targets: [ShareTarget]) {
    let list = TargetList(
      targets: targets.map { Target(id: $0.deviceId, name: $0.name, kind: $0.kind) })
    guard let root = root, let data = try? JSONEncoder().encode(list) else {
      return
    }

    try? files.createDirectory(at: root, withIntermediateDirectories: true)
    try? data.write(to: root.appendingPathComponent("targets.json"), options: .atomic)
  }

  /// Sent files are deleted by the app as each transfer ends; this removes
  /// the folders they sat in, and copies that were never sent.
  private func removeStaleCopies() {
    guard let copies = root?.appendingPathComponent("Files", isDirectory: true),
      let folders = try? files.contentsOfDirectory(at: copies, includingPropertiesForKeys: nil)
    else {
      return
    }

    let now = Date().timeIntervalSince1970
    for folder in folders {
      let isEmpty = (try? files.contentsOfDirectory(atPath: folder.path).isEmpty) ?? false
      let stamp = folder.lastPathComponent.split(separator: "-").first.flatMap { Double($0) }
      let age = now - (stamp ?? 0) / 1000
      if (isEmpty && age > ShareInbox.fillingFor) || age > ShareInbox.staleAfter {
        try? files.removeItem(at: folder)
      }
    }
  }

  private struct Request: Decodable {
    let paths: [String]
    let deviceId: String?
    let everyDevice: Bool?
  }

  private struct TargetList: Encodable {
    let targets: [Target]
  }

  private struct Target: Encodable {
    let id: String
    let name: String
    let kind: String
  }
}
