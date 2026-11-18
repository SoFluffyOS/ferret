import Foundation
import Security

/// The folder the app and its Share extension both reach: the extension is
/// sandboxed, so an App Group container is the only place it can leave
/// files and requests for the app, and read the device list back.
///
/// The group is named by `FerretShareGroup` in the app's Info.plist; without
/// it there is no Share extension and nothing here does anything.
///
/// macOS only lets an app into a group container when its signature proves
/// the Team ID the group starts with; any other app makes the system ask
/// "would like to access data from other apps", again for every new build.
/// So a build signed without that team (a local debug build) stays out of
/// the folder altogether. Taking a request deletes its file, which is how
/// the extension knows Ferret has it; when the file stays, the extension
/// puts the request in the `ferret://send` link instead: see
/// `request(from:)`.
final class ShareInbox {
  static let wakeNotification = Notification.Name("io.sofluffy.ferret.share")

  /// The extension asks for the device list with the first, and Ferret
  /// answers (and tells of every change) with the second, the list riding
  /// as the notification's object. This reaches the extension even when
  /// the folder doesn't.
  static let askDevicesNotification = Notification.Name("io.sofluffy.ferret.share.devices.ask")
  static let devicesNotification = Notification.Name("io.sofluffy.ferret.share.devices")
  static let wakeScheme = "ferret"
  static let wakeHost = "send"

  /// A copy nobody collected is dropped after a day, such as when the
  /// device went away before the transfer started.
  private static let staleAfter: TimeInterval = 24 * 60 * 60

  private let root: URL?
  private let files = FileManager.default

  init(bundle: Bundle = .main) {
    guard
      let group = bundle.object(forInfoDictionaryKey: "FerretShareGroup") as? String,
      !group.isEmpty,
      ShareInbox.isSignedByTeam(of: group),
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

  private static func isSignedByTeam(of group: String) -> Bool {
    var running: SecCode?
    guard SecCodeCopySelf([], &running) == errSecSuccess, let running = running else {
      return false
    }

    var onDisk: SecStaticCode?
    guard SecCodeCopyStaticCode(running, [], &onDisk) == errSecSuccess, let onDisk = onDisk
    else {
      return false
    }

    var details: CFDictionary?
    let wanted = SecCSFlags(rawValue: kSecCSSigningInformation)
    guard SecCodeCopySigningInformation(onDisk, wanted, &details) == errSecSuccess,
      let signing = details as? [String: Any],
      let team = signing[kSecCodeInfoTeamIdentifier as String] as? String
    else {
      return false
    }

    return group.hasPrefix("\(team).")
  }

  /// Every request the extension left, oldest first. Each is returned once.
  func takeRequests() -> [SharedItems] {
    guard let requests = root?.appendingPathComponent("Requests", isDirectory: true),
      let found = try? files.contentsOfDirectory(
        at: requests, includingPropertiesForKeys: [.creationDateKey])
    else {
      return []
    }

    let oldestFirst = found.filter { $0.pathExtension == "json" }.sorted {
      created($0) < created($1)
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

  /// The request carried by a `ferret://send?request=…` link, which the
  /// extension uses when it can't share a folder with the app.
  func request(from link: URL) -> SharedItems? {
    let query = URLComponents(url: link, resolvingAgainstBaseURL: false)?.queryItems
    guard let encoded = query?.first(where: { $0.name == "request" })?.value,
      let data = Data(base64Encoded: encoded),
      let request = try? JSONDecoder().decode(Request.self, from: data)
    else {
      return nil
    }

    return items(from: request)
  }

  /// Only copies the extension made are Ferret's to delete. Anything else
  /// is somebody's own file.
  private func items(from request: Request) -> SharedItems {
    let copies = root?.appendingPathComponent("Files", isDirectory: true).standardizedFileURL.path
    let areCopies = request.paths.allSatisfy { path in
      guard let copies = copies else {
        return false
      }

      return URL(fileURLWithPath: path).standardizedFileURL.path.hasPrefix(copies + "/")
    }

    return SharedItems(
      paths: request.paths, text: request.text, deviceId: request.deviceId,
      everyDevice: request.everyDevice, keepFiles: areCopies ? nil : true)
  }

  /// The device list as the extension reads it.
  func encode(targets: [ShareTarget]) -> Data? {
    let list = TargetList(
      targets: targets.map { Target(id: $0.deviceId, name: $0.name, kind: $0.kind) })
    return try? JSONEncoder().encode(list)
  }

  /// Keeps the list where the extension finds it while Ferret isn't
  /// running to answer.
  func write(targets: [ShareTarget]) {
    guard let root = root, let data = encode(targets: targets) else {
      return
    }

    try? files.createDirectory(at: root, withIntermediateDirectories: true)
    try? data.write(to: root.appendingPathComponent("targets.json"), options: .atomic)
  }

  /// Sent files are deleted by the app as each transfer ends; this removes
  /// the folders they sat in, and copies that were never sent.
  private func removeStaleCopies() {
    guard let copies = root?.appendingPathComponent("Files", isDirectory: true),
      let folders = try? files.contentsOfDirectory(
        at: copies, includingPropertiesForKeys: [.creationDateKey])
    else {
      return
    }

    let now = Date()
    for folder in folders {
      let isEmpty = (try? files.contentsOfDirectory(atPath: folder.path).isEmpty) ?? false
      let isStale = now.timeIntervalSince(created(folder)) > ShareInbox.staleAfter
      if isEmpty || isStale {
        try? files.removeItem(at: folder)
      }
    }
  }

  private func created(_ url: URL) -> Date {
    let values = try? url.resourceValues(forKeys: [.creationDateKey])
    return values?.creationDate ?? .distantPast
  }

  private struct Request: Decodable {
    let paths: [String]
    let text: String?
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
