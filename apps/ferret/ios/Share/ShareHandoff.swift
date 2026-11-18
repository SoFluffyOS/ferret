import Foundation

/// A device Ferret listed the last time it was open.
struct ShareDevice: Decodable, Identifiable {
  let id: String
  let name: String
  let kind: String
}

/// What the picker ends with.
enum ShareChoice {
  case device(String)
  case everyDevice

  /// No device to pick here: Ferret opens and sends once one connects.
  case askInFerret
}

/// The extension's side of the App Group folder it shares with Ferret. The
/// names here match `ShareInbox.swift` in the ferret_drop plugin and
/// `LinkInbox.swift` in the ferret_handoff plugin.
///
/// iOS doesn't let a share extension send anything itself once it closes,
/// and Ferret only sends while it is open. So a share is a request file left
/// in the folder: files go to `Requests` for Drop, text and links to `Links`
/// for Handoff. Ferret takes them when it comes to the front.
struct ShareHandoff {
  private let root: URL?
  private let files = FileManager.default

  init() {
    guard
      let group = Bundle.main.object(forInfoDictionaryKey: "FerretShareGroup") as? String,
      let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: group)
    else {
      root = nil
      return
    }

    root = container.appendingPathComponent("Share", isDirectory: true)
  }

  var isReachable: Bool {
    return root != nil
  }

  /// The devices Ferret last wrote down.
  func devices() -> [ShareDevice] {
    guard let file = root?.appendingPathComponent("targets.json"),
      let data = try? Data(contentsOf: file),
      let list = try? JSONDecoder().decode(DeviceList.self, from: data)
    else {
      return []
    }

    return list.targets
  }

  /// A fresh folder for one share's copies. Its name starts with the time,
  /// so Ferret can clear out old ones without reading file dates.
  func makeCopyFolder() -> URL? {
    guard let root = root else {
      return nil
    }

    let folder =
      root
      .appendingPathComponent("Files", isDirectory: true)
      .appendingPathComponent(ShareHandoff.stampedName(), isDirectory: true)
    do {
      try files.createDirectory(at: folder, withIntermediateDirectories: true)
    } catch {
      return nil
    }

    return folder
  }

  /// Copies [file] into [folder] as [name] and returns the copy's path.
  /// Ferret can't read the sharing app's files, so it always gets a copy.
  func copy(_ file: URL, named name: String, into folder: URL) -> String? {
    let isScoped = file.startAccessingSecurityScopedResource()
    defer {
      if isScoped {
        file.stopAccessingSecurityScopedResource()
      }
    }

    let copy = freeName(name, in: folder)
    do {
      try files.copyItem(at: file, to: copy)
    } catch {
      return nil
    }

    return copy.path
  }

  /// Writes [data] into [folder] as [name] and returns its path.
  func write(_ data: Data, named name: String, into folder: URL) -> String? {
    let file = freeName(name, in: folder)
    do {
      try data.write(to: file, options: .atomic)
    } catch {
      return nil
    }

    return file.path
  }

  /// Leaves [content] for Ferret. [devices] are the ones the picker showed,
  /// so "All my devices" reaches each of them with a link too.
  func leave(_ content: SharedContent, for choice: ShareChoice, devices: [ShareDevice]) -> Bool {
    var isLeft = true
    if !content.paths.isEmpty {
      var request = FilesRequest(paths: content.paths, deviceId: nil, everyDevice: nil)
      switch choice {
      case .device(let id):
        request.deviceId = id
      case .everyDevice:
        request.everyDevice = true
      case .askInFerret:
        break
      }
      isLeft = save(request, in: "Requests") && isLeft
    }

    if let text = content.text {
      let deviceIds: [String]
      switch choice {
      case .device(let id):
        deviceIds = [id]
      case .everyDevice:
        deviceIds = devices.map { $0.id }
      case .askInFerret:
        deviceIds = []
      }
      let request = LinkRequest(
        text: text, deviceIds: deviceIds,
        createdAtMs: Int64(Date().timeIntervalSince1970 * 1000))
      isLeft = save(request, in: "Links") && isLeft
    }

    return isLeft
  }

  /// Removes the copies of a share that was cancelled.
  func discard(_ content: SharedContent) {
    if let folder = content.copyFolder {
      try? files.removeItem(at: folder)
    }
  }

  private func save<Request: Encodable>(_ request: Request, in name: String) -> Bool {
    guard let root = root, let data = try? JSONEncoder().encode(request) else {
      return false
    }

    let folder = root.appendingPathComponent(name, isDirectory: true)
    let file = folder.appendingPathComponent("\(ShareHandoff.stampedName()).json")
    do {
      try files.createDirectory(at: folder, withIntermediateDirectories: true)
      try data.write(to: file, options: .atomic)
    } catch {
      return false
    }

    return true
  }

  private static func stampedName() -> String {
    let millis = Int64(Date().timeIntervalSince1970 * 1000)
    return "\(millis)-\(UUID().uuidString)"
  }

  private func freeName(_ name: String, in folder: URL) -> URL {
    let wanted = folder.appendingPathComponent(name)
    guard files.fileExists(atPath: wanted.path) else {
      return wanted
    }

    let base = wanted.deletingPathExtension().lastPathComponent
    let ext = wanted.pathExtension
    var count = 1
    while true {
      var candidate = folder.appendingPathComponent("\(base) (\(count))")
      if !ext.isEmpty {
        candidate = candidate.appendingPathExtension(ext)
      }
      if !files.fileExists(atPath: candidate.path) {
        return candidate
      }

      count += 1
    }
  }

  private struct DeviceList: Decodable {
    let targets: [ShareDevice]
  }

  private struct FilesRequest: Encodable {
    let paths: [String]
    var deviceId: String?
    var everyDevice: Bool?
  }

  private struct LinkRequest: Encodable {
    let text: String
    let deviceIds: [String]
    let createdAtMs: Int64
  }
}
