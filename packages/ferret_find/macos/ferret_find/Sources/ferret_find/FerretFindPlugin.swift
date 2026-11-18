import Cocoa
import FlutterMacOS

/// Rings this Mac: a system sound on repeat at full volume, and a bounce of
/// the Dock icon. The app shows the "Found it" notice and popover.
public class FerretFindPlugin: NSObject, FlutterPlugin, FindHostApi {
  private static let soundNames = ["Sosumi", "Glass", "Ping"]
  private static let beatInterval: TimeInterval = 1.2

  private let flutterApi: FindFlutterApi
  private var sound: NSSound?
  private var beat: Timer?
  private var limit: Timer?
  private var attentionRequest: Int?

  init(flutterApi: FindFlutterApi) {
    self.flutterApi = flutterApi
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretFindPlugin(
      flutterApi: FindFlutterApi(binaryMessenger: registrar.messenger))
    FindHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  func abilities() throws -> PlatformRingAbilities {
    PlatformRingAbilities(
      controlsVolume: SystemVolume.isSettable,
      needsDndAccess: false,
      dndAccessGranted: false,
      fullScreenAllowed: true,
      hasTorch: false,
      ringsInBackground: true,
      showsOwnAlert: false)
  }

  func readAudio() throws -> PlatformAudio? {
    guard let volume = SystemVolume.volume() else {
      return nil
    }

    return PlatformAudio(
      volume: Int64((volume * 100).rounded()),
      maxVolume: 100,
      muted: SystemVolume.isMuted(),
      interruptionFilter: 0,
      quiet: false)
  }

  func applyAudio(audio: PlatformAudio) throws {
    let maxVolume = max(audio.maxVolume, 1)
    SystemVolume.setMuted(audio.muted)
    SystemVolume.setVolume(Float32(audio.volume) / Float32(maxVolume))
  }

  func startAlert(alert: PlatformAlert) throws {
    stopRinging()

    if !alert.silent {
      guard let sound = Self.soundNames.lazy.compactMap({ NSSound(named: $0) }).first else {
        throw PigeonError(code: "no_sound", message: "No system sound to ring with.", details: nil)
      }

      sound.volume = 1
      sound.play()
      self.sound = sound
      beat = Timer.scheduledTimer(withTimeInterval: Self.beatInterval, repeats: true) {
        [weak self] _ in
        guard let sound = self?.sound else {
          return
        }

        sound.stop()
        sound.play()
      }
    }

    attentionRequest = NSApp.requestUserAttention(.criticalRequest)
    let seconds = TimeInterval(max(alert.maxSeconds, 1))
    limit = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
      self?.stopRinging()
      self?.report("timeout")
    }
  }

  func stopAlert() throws {
    stopRinging()
  }

  func openDndAccessSettings() throws {}

  func openFullScreenSettings() throws {}

  private func stopRinging() {
    beat?.invalidate()
    beat = nil
    limit?.invalidate()
    limit = nil
    sound?.stop()
    sound = nil
    if let request = attentionRequest {
      NSApp.cancelUserAttentionRequest(request)
      attentionRequest = nil
    }
  }

  private func report(_ reason: String) {
    let api = flutterApi
    Task { @MainActor in
      try? await api.onAlertStopped(reason: reason)
    }
  }
}
