import AVFoundation
import AudioToolbox
import Flutter
import UIKit

/// Rings this iPhone while Ferret is open: the bundled tone on the playback
/// audio session, which plays through the silent switch, and vibration. iOS
/// gives apps no way to ring from the background or change the volume.
public class FerretFindPlugin: NSObject, FlutterPlugin, FindHostApi {
  private static let vibrateInterval: TimeInterval = 1.5
  private static let alertSoundId = SystemSoundID(1005)

  private let flutterApi: FindFlutterApi
  private let soundPath: String?
  private var player: AVAudioPlayer?
  private var vibration: Timer?
  private var fallbackBeat: Timer?
  private var limit: Timer?

  init(flutterApi: FindFlutterApi, soundPath: String?) {
    self.flutterApi = flutterApi
    self.soundPath = soundPath
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let key = registrar.lookupKey(forAsset: "assets/ring.wav", fromPackage: "ferret_find")
    let instance = FerretFindPlugin(
      flutterApi: FindFlutterApi(binaryMessenger: registrar.messenger()),
      soundPath: Bundle.main.path(forResource: key, ofType: nil))
    FindHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  func abilities() throws -> PlatformRingAbilities {
    PlatformRingAbilities(
      controlsVolume: false,
      needsDndAccess: false,
      dndAccessGranted: false,
      fullScreenAllowed: true,
      hasTorch: false,
      ringsInBackground: false,
      showsOwnAlert: false)
  }

  func readAudio() throws -> PlatformAudio? {
    nil
  }

  func applyAudio(audio: PlatformAudio) throws {}

  func startAlert(alert: PlatformAlert) throws {
    stopRinging()

    if !alert.silent {
      playSound()
    }

    if alert.vibrate {
      AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
      vibration = Timer.scheduledTimer(withTimeInterval: Self.vibrateInterval, repeats: true) { _ in
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
      }
    }

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

  private func playSound() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .default, options: [])
    try? session.setActive(true)

    if let path = soundPath, let player = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path)) {
      player.numberOfLoops = -1
      player.volume = 1
      player.play()
      self.player = player
      return
    }

    AudioServicesPlayAlertSound(Self.alertSoundId)
    fallbackBeat = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
      AudioServicesPlayAlertSound(Self.alertSoundId)
    }
  }

  private func stopRinging() {
    vibration?.invalidate()
    vibration = nil
    fallbackBeat?.invalidate()
    fallbackBeat = nil
    limit?.invalidate()
    limit = nil

    guard let player else {
      return
    }

    player.stop()
    self.player = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func report(_ reason: String) {
    let api = flutterApi
    Task { @MainActor in
      try? await api.onAlertStopped(reason: reason)
    }
  }
}
