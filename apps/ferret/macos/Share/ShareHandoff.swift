import AppKit
import Foundation

/// A device Ferret says is connected right now.
struct ShareDevice: Decodable, Identifiable {
  let id: String
  let name: String
  let kind: String
}

/// What the picker ends with.
enum ShareChoice {
  case device(String)
  case everyDevice

  /// No device to pick here: Ferret opens and asks once one connects.
  case askInFerret
}

/// The extension's side of the App Group folder it shares with Ferret. The
/// names here match `ShareInbox.swift` in the ferret_drop plugin.
///
/// A request is a file left in that folder; Ferret deletes it as it takes
/// it. When the file is still there a moment later, Ferret can't reach the
/// folder (a build signed without a team isn't let in), so the request
/// rides in the link that opens Ferret instead, with the files' own paths.
struct ShareHandoff {
  private static let wakeNotification = Notification.Name("io.sofluffy.ferret.share")
  private static let wakeLink = "ferret://send"
  private static let askDevicesNotification = Notification.Name(
    "io.sofluffy.ferret.share.devices.ask")
  private static let devicesNotification = Notification.Name("io.sofluffy.ferret.share.devices")

  /// Longer links than this are not worth trusting to the system.
  private static let longestLink = 60_000

  /// How long Ferret gets to take a request, which covers starting up.
  private static let patience: TimeInterval = 4
  private static let lookEvery: TimeInterval = 0.1

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

  /// The devices Ferret last wrote down, to show at once.
  func devices() -> [ShareDevice] {
    guard let file = root?.appendingPathComponent("targets.json"),
      let data = try? Data(contentsOf: file),
      let list = try? JSONDecoder().decode(DeviceList.self, from: data)
    else {
      return []
    }

    return list.targets
  }

  /// Asks a running Ferret for its devices and keeps listening, so the list
  /// is right when Ferret can't write it down, and follows devices that
  /// come and go while the picker is open. The returned token stops it.
  func followDevices(_ onChange: @escaping ([ShareDevice]) -> Void) -> NSObjectProtocol {
    let center = DistributedNotificationCenter.default()
    let token = center.addObserver(
      forName: ShareHandoff.devicesNotification, object: nil, queue: .main
    ) { notification in
      guard let json = notification.object as? String, let data = json.data(using: .utf8),
        let list = try? JSONDecoder().decode(DeviceList.self, from: data)
      else {
        return
      }

      onChange(list.targets)
    }
    center.postNotificationName(
      ShareHandoff.askDevicesNotification, object: nil, userInfo: nil, deliverImmediately: true)

    return token
  }

  func stopFollowing(_ token: NSObjectProtocol) {
    DistributedNotificationCenter.default().removeObserver(token)
  }

  /// A fresh folder for one share's copies.
  func makeCopyFolder() -> URL? {
    guard let root = root else {
      return nil
    }

    let folder =
      root
      .appendingPathComponent("Files", isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    do {
      try files.createDirectory(at: folder, withIntermediateDirectories: true)
    } catch {
      return nil
    }

    return folder
  }

  /// Copies [file] next to the others of this share and returns the copy's
  /// path. Ferret can't use the access Finder gave this extension, so it
  /// gets its own copy; on the same disk that is an instant clone that takes
  /// no extra space. Folders, and files that can't be copied, keep their
  /// own path.
  func copy(_ file: URL, into folder: URL?) -> String {
    let isScoped = file.startAccessingSecurityScopedResource()
    defer {
      if isScoped {
        file.stopAccessingSecurityScopedResource()
      }
    }

    var isFolder: ObjCBool = false
    let exists = files.fileExists(atPath: file.path, isDirectory: &isFolder)
    guard let folder = folder, exists, !isFolder.boolValue else {
      return file.path
    }

    let copy = freeName(file.lastPathComponent, in: folder)
    do {
      try files.copyItem(at: file, to: copy)
    } catch {
      return file.path
    }

    return copy.path
  }

  /// Hands [content] to Ferret, starting it when needed, and says on the
  /// main queue whether Ferret has it.
  func send(
    _ content: SharedContent, to choice: ShareChoice, completion: @escaping (Bool) -> Void
  ) {
    guard let left = leave(request(content.paths, content.text, choice)) else {
      completion(sendInLink(content, choice))
      return
    }

    DistributedNotificationCenter.default().postNotificationName(
      ShareHandoff.wakeNotification, object: nil, userInfo: nil, deliverImmediately: true)
    _ = open(ShareHandoff.wakeLink)
    waitUntilTaken(left, until: Date().addingTimeInterval(ShareHandoff.patience)) { taken in
      completion(taken || self.sendInLink(content, choice))
    }
  }

  private func waitUntilTaken(
    _ request: URL, until deadline: Date, completion: @escaping (Bool) -> Void
  ) {
    guard files.fileExists(atPath: request.path) else {
      completion(true)
      return
    }

    guard Date() < deadline else {
      // Taking it back decides who has it: if it is already gone, Ferret
      // took it after all.
      let tookBack = (try? files.removeItem(at: request)) != nil
      completion(!tookBack)
      return
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + ShareHandoff.lookEvery) {
      self.waitUntilTaken(request, until: deadline, completion: completion)
    }
  }

  /// The request in the link itself, with the files where they are: copies
  /// in the shared folder are no use to a Ferret that can't reach it.
  private func sendInLink(_ content: SharedContent, _ choice: ShareChoice) -> Bool {
    if let copies = content.copyFolder {
      try? files.removeItem(at: copies)
    }

    let paths = content.originals
    let hasSomething = !paths.isEmpty || !(content.text ?? "").isEmpty
    guard hasSomething, let data = request(paths, content.text, choice) else {
      return false
    }

    let link = "\(ShareHandoff.wakeLink)?request=\(urlSafe(data.base64EncodedString()))"
    guard link.count <= ShareHandoff.longestLink else {
      return false
    }

    return open(link)
  }

  private func request(_ paths: [String], _ text: String?, _ choice: ShareChoice) -> Data? {
    var request = Request(paths: paths, text: text, deviceId: nil, everyDevice: nil)
    switch choice {
    case .device(let id):
      request.deviceId = id
    case .everyDevice:
      request.everyDevice = true
    case .askInFerret:
      break
    }

    return try? JSONEncoder().encode(request)
  }

  /// Leaves the request in the shared folder and returns its file.
  private func leave(_ request: Data?) -> URL? {
    guard let request = request, let root = root else {
      return nil
    }

    let requests = root.appendingPathComponent("Requests", isDirectory: true)
    let file = requests.appendingPathComponent("\(UUID().uuidString).json")
    do {
      try files.createDirectory(at: requests, withIntermediateDirectories: true)
      try request.write(to: file, options: .atomic)
    } catch {
      return nil
    }

    return file
  }

  private func open(_ link: String) -> Bool {
    guard let url = URL(string: link) else {
      return false
    }

    let quietly = NSWorkspace.OpenConfiguration()
    quietly.activates = false
    NSWorkspace.shared.open(url, configuration: quietly, completionHandler: nil)
    return true
  }

  private func urlSafe(_ base64: String) -> String {
    return base64.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? base64
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

  private struct Request: Encodable {
    let paths: [String]
    let text: String?
    var deviceId: String?
    var everyDevice: Bool?
  }
}
