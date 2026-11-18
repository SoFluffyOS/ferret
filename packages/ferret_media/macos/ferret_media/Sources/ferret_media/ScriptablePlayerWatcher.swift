import Cocoa
import FlutterMacOS

/// Follows Music and Spotify while they run. Never launches them: every
/// script runs only when the app is already open.
final class ScriptablePlayerWatcher {
  var onChange: (([PlayerInfo]) -> Void)?

  private var observers: [NSObjectProtocol] = []
  private var workspaceObservers: [NSObjectProtocol] = []
  private var memory: [String: Remembered] = [:]
  private var pendingEmit: DispatchWorkItem?

  private struct Remembered {
    var title: String?
    var status: PlayerStatus?
    var lastActiveAtMs: Int64 = 0
    var trackId: String?
    var artwork: FlutterStandardTypedData?
  }

  func start() {
    guard observers.isEmpty else { return }

    let distributed = DistributedNotificationCenter.default()
    for player in ScriptablePlayer.all {
      observers.append(
        distributed.addObserver(
          forName: Notification.Name(player.changeNotification), object: nil, queue: .main
        ) { [weak self] _ in self?.scheduleEmit() })
    }

    let workspace = NSWorkspace.shared.notificationCenter
    for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification] {
      workspaceObservers.append(
        workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
          self?.scheduleEmit()
        })
    }

    scheduleEmit()
  }

  func stop() {
    let distributed = DistributedNotificationCenter.default()
    observers.forEach { distributed.removeObserver($0) }
    observers.removeAll()

    let workspace = NSWorkspace.shared.notificationCenter
    workspaceObservers.forEach { workspace.removeObserver($0) }
    workspaceObservers.removeAll()

    pendingEmit?.cancel()
    pendingEmit = nil
    memory.removeAll()
  }

  /// Granted unless the user refused Automation for a running player.
  func access(askIfNeeded: Bool) -> MediaAccess {
    var refused = false
    for player in ScriptablePlayer.all where isRunning(player) {
      let status = automationStatus(player, askIfNeeded: askIfNeeded)
      if status == OSStatus(errAEEventNotPermitted) || status == OSStatus(errAEEventWouldRequireUserConsent) {
        refused = true
      }
    }
    if refused {
      return .notGranted
    }
    return .granted
  }

  func readPlayers() -> [PlayerInfo] {
    return ScriptablePlayer.all.compactMap { player in
      guard isRunning(player) else {
        memory[player.bundleId] = nil
        return nil
      }
      return read(player)
    }
  }

  func command(playerId: String, action: PlayerAction, positionMs: Int64, volume: Double) -> Bool {
    guard let player = ScriptablePlayer.all.first(where: { $0.bundleId == playerId }), isRunning(player) else {
      return false
    }

    let ok = run(player.commandScript(action, positionMs: positionMs, volume: volume)) != nil
    scheduleEmit()
    return ok
  }

  private func scheduleEmit() {
    pendingEmit?.cancel()
    let work = DispatchWorkItem { [weak self] in
      guard let self else { return }
      self.onChange?(self.readPlayers())
    }
    pendingEmit = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: work)
  }

  private func read(_ player: ScriptablePlayer) -> PlayerInfo? {
    guard let result = run(player.stateScript), result.numberOfItems >= 1 else {
      return nil
    }

    let status = Self.status(result.atIndex(1)?.stringValue)
    guard result.numberOfItems >= 9, status != .stopped else {
      memory[player.bundleId] = nil
      return nil
    }

    let now = Int64(Date().timeIntervalSince1970 * 1000)
    let title = result.atIndex(2)?.stringValue ?? ""
    let trackId = result.atIndex(8)?.stringValue ?? title
    var remembered = memory[player.bundleId] ?? Remembered()
    if remembered.title != title || (status == .playing && remembered.status != .playing) {
      remembered.lastActiveAtMs = now
    }
    remembered.title = title
    remembered.status = status
    if remembered.trackId != trackId {
      remembered.trackId = trackId
      remembered.artwork = artwork(for: player)
    }
    memory[player.bundleId] = remembered

    let duration = result.atIndex(5)?.doubleValue ?? 0
    let durationMs = player.durationInMilliseconds ? Int64(duration) : Int64(duration * 1000)
    let positionMs = Int64((result.atIndex(6)?.doubleValue ?? 0) * 1000)
    let volume = Double(result.atIndex(7)?.int32Value ?? -100) / 100
    let link = result.atIndex(9)?.stringValue ?? ""

    return PlayerInfo(
      id: player.bundleId,
      appId: player.bundleId,
      appName: player.name,
      title: title,
      artist: result.atIndex(3)?.stringValue ?? "",
      album: result.atIndex(4)?.stringValue ?? "",
      artwork: remembered.artwork,
      durationMs: max(0, durationMs),
      positionMs: max(0, positionMs),
      positionAtMs: now,
      status: status,
      playbackRate: 1,
      contentUri: link.isEmpty ? nil : link,
      lastActiveAtMs: remembered.lastActiveAtMs,
      actions: [.play, .pause, .toggle, .next, .previous, .seek, .setVolume],
      volume: volume < 0 ? -1 : volume
    )
  }

  private func artwork(for player: ScriptablePlayer) -> FlutterStandardTypedData? {
    guard player.hasArtworkData, let descriptor = run(player.artworkScript) else {
      return nil
    }
    guard let encoded = ArtworkEncoder.jpeg(from: descriptor.data) else {
      return nil
    }
    return FlutterStandardTypedData(bytes: encoded)
  }

  private func run(_ source: String) -> NSAppleEventDescriptor? {
    guard let script = NSAppleScript(source: source) else { return nil }

    var error: NSDictionary?
    let result = script.executeAndReturnError(&error)
    if let error {
      let code = error[NSAppleScript.errorNumber] as? Int ?? 0
      NSLog("FerretMedia: AppleScript failed with \(code)")
      return nil
    }
    return result
  }

  private func isRunning(_ player: ScriptablePlayer) -> Bool {
    return !NSRunningApplication.runningApplications(withBundleIdentifier: player.bundleId).isEmpty
  }

  private func automationStatus(_ player: ScriptablePlayer, askIfNeeded: Bool) -> OSStatus {
    let target = NSAppleEventDescriptor(bundleIdentifier: player.bundleId)
    guard let address = target.aeDesc else { return OSStatus(procNotFound) }
    return AEDeterminePermissionToAutomateTarget(address, typeWildCard, typeWildCard, askIfNeeded)
  }

  private static func status(_ state: String?) -> PlayerStatus {
    switch state {
    case "playing", "kPSP": return .playing
    case "paused", "kPSp": return .paused
    case "fast forwarding", "rewinding", "kPSF", "kPSR": return .playing
    default: return .stopped
    }
  }
}
