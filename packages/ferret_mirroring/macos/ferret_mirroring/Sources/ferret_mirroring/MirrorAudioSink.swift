import FlutterMacOS

/// Dart's way to `SoundPlayer`.
final class MirrorAudioSink: MirrorAudioHostApi {
  private let player = SoundPlayer()

  func configure(codec: NativeAudioCodec, sampleRate: Int64, channels: Int64, silent: Bool) throws {
    do {
      try player.configure(
        codec: codec == .opus ? .opus : .pcm,
        sampleRate: Double(sampleRate),
        channels: UInt32(clamping: channels),
        silent: silent)
    } catch {
      throw PigeonError(
        code: "no_sound", message: "This sound can't be played here (\(error))", details: nil)
    }
  }

  func play(data: FlutterStandardTypedData) throws {
    player.play(data.data)
  }

  func flush() throws {
    player.flush()
  }

  func setVolume(volume: Double) throws {
    player.setVolume(Float(volume))
  }

  func stats() throws -> NativeAudioStats {
    NativeAudioStats(frames: player.frames, peak: Double(player.peak))
  }

  func close() throws {
    player.stop()
  }
}
