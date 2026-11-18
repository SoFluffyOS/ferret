import Cocoa
import FlutterMacOS

/// Music and Spotify through AppleScript. macOS no longer lets third-party
/// apps read the system Now Playing, so other players are not visible here.
public class FerretMediaPlugin: NSObject, FlutterPlugin, MediaHostApi {
  private let flutterApi: MediaFlutterApi
  private let watcher = ScriptablePlayerWatcher()

  init(flutterApi: MediaFlutterApi) {
    self.flutterApi = flutterApi
    super.init()
    watcher.onChange = { [weak self] players in
      self?.deliverPlayers(players)
    }
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretMediaPlugin(flutterApi: MediaFlutterApi(binaryMessenger: registrar.messenger))
    MediaHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  func access() throws -> MediaAccess {
    return watcher.access(askIfNeeded: false)
  }

  func requestAccess() async throws -> MediaAccess {
    let watcher = self.watcher
    let access = await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        continuation.resume(returning: watcher.access(askIfNeeded: true))
      }
    }
    deliverAccess(access)
    return access
  }

  func openAccessSettings() throws {
    let link = "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
    if let url = URL(string: link) {
      NSWorkspace.shared.open(url)
    }
  }

  func startWatching() throws {
    watcher.start()
  }

  func stopWatching() throws {
    watcher.stop()
  }

  func players() async throws -> [PlayerInfo] {
    return watcher.readPlayers()
  }

  func command(playerId: String, action: PlayerAction, positionMs: Int64, volume: Double) async throws -> Bool {
    return watcher.command(playerId: playerId, action: action, positionMs: positionMs, volume: volume)
  }

  private func deliverPlayers(_ players: [PlayerInfo]) {
    Task { @MainActor in
      try? await flutterApi.onPlayersChanged(players: players)
    }
  }

  private func deliverAccess(_ access: MediaAccess) {
    Task { @MainActor in
      try? await flutterApi.onAccessChanged(access: access)
    }
  }
}
