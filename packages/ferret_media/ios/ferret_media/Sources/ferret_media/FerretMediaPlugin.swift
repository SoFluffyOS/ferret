import Flutter
import UIKit

/// iOS never lets an app see or control what other apps play, so this
/// reports the platform as unsupported. Ferret on iPhone still shows and
/// controls media playing on the user's other devices.
public class FerretMediaPlugin: NSObject, FlutterPlugin, MediaHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretMediaPlugin()
    MediaHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  func access() throws -> MediaAccess {
    return .unsupported
  }

  func requestAccess() async throws -> MediaAccess {
    return .unsupported
  }

  func openAccessSettings() throws {}

  func startWatching() throws {}

  func stopWatching() throws {}

  func players() async throws -> [PlayerInfo] {
    return []
  }

  func command(playerId: String, action: PlayerAction, positionMs: Int64, volume: Double) async throws -> Bool {
    return false
  }
}
