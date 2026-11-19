import AVFoundation
import AudioToolbox

/// Plays a mirrored device's sound: Opus decoded by AudioToolbox, or plain
/// 16-bit samples, queued back to back on an AVAudioEngine player. It never
/// touches the microphone.
final class SoundPlayer {
  enum Codec {
    case opus
    case pcm
  }

  enum Failure: Error {
    case badFormat
    case noDecoder
    case noOutput(Error)
  }

  private static let opusSampleRate = 48_000.0
  private static let opusFrames: UInt32 = 960
  private static let mostFramesPerPacket: AVAudioFrameCount = 5_760

  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private var codec = Codec.opus
  private var channels: UInt32 = 2
  private var playFormat: AVAudioFormat?
  private var opusFormat: AVAudioFormat?
  private var converter: AVAudioConverter?
  private var silent = false
  private var attached = false
  private var volume: Float = 1

  /// Samples per channel decoded since the last `configure`.
  private(set) var frames: Int64 = 0

  /// The loudest decoded sample since then, from 0 to 1.
  private(set) var peak: Float = 0

  /// Gets ready for a stream. With `silent`, the engine is never started:
  /// packets are decoded and measured only.
  func configure(codec: Codec, sampleRate: Double, channels: UInt32, silent: Bool) throws {
    stop()
    guard channels == 1 || channels == 2, sampleRate > 0,
      let playFormat = AVAudioFormat(
        standardFormatWithSampleRate: codec == .opus ? Self.opusSampleRate : sampleRate,
        channels: channels)
    else {
      throw Failure.badFormat
    }

    self.codec = codec
    self.channels = channels
    self.playFormat = playFormat
    self.silent = silent
    frames = 0
    peak = 0
    if codec == .opus {
      try makeDecoder(to: playFormat)
    }

    if silent {
      return
    }

    engine.attach(player)
    attached = true
    engine.connect(player, to: engine.mainMixerNode, format: playFormat)
    player.volume = volume
    do {
      try engine.start()
    } catch {
      stop()
      throw Failure.noOutput(error)
    }

    player.play()
  }

  /// Decodes one packet and queues it after what is already queued.
  func play(_ data: Data) {
    guard let playFormat, !data.isEmpty else {
      return
    }

    let decoded: AVAudioPCMBuffer?
    switch codec {
    case .opus:
      decoded = decodeOpus(data, to: playFormat)
    case .pcm:
      decoded = samples(data, format: playFormat)
    }

    guard let buffer = decoded, buffer.frameLength > 0 else {
      return
    }

    measure(buffer)
    if !silent && engine.isRunning {
      player.scheduleBuffer(buffer, completionHandler: nil)
    }
  }

  /// Drops what is queued and hasn't played yet.
  func flush() {
    guard !silent, attached else {
      return
    }

    player.stop()
    if engine.isRunning {
      player.play()
    }
  }

  func setVolume(_ volume: Float) {
    self.volume = min(max(volume, 0), 1)
    player.volume = self.volume
  }

  func stop() {
    if attached {
      player.stop()
      engine.stop()
      engine.detach(player)
      attached = false
    }

    converter = nil
    opusFormat = nil
    playFormat = nil
  }

  private func makeDecoder(to playFormat: AVAudioFormat) throws {
    var description = AudioStreamBasicDescription(
      mSampleRate: Self.opusSampleRate,
      mFormatID: kAudioFormatOpus,
      mFormatFlags: 0,
      mBytesPerPacket: 0,
      mFramesPerPacket: Self.opusFrames,
      mBytesPerFrame: 0,
      mChannelsPerFrame: channels,
      mBitsPerChannel: 0,
      mReserved: 0)
    guard let opusFormat = AVAudioFormat(streamDescription: &description),
      let converter = AVAudioConverter(from: opusFormat, to: playFormat)
    else {
      throw Failure.noDecoder
    }

    self.opusFormat = opusFormat
    self.converter = converter
  }

  private func decodeOpus(_ data: Data, to playFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
    guard let converter, let opusFormat,
      let output = AVAudioPCMBuffer(
        pcmFormat: playFormat, frameCapacity: Self.mostFramesPerPacket)
    else {
      return nil
    }

    let packet = AVAudioCompressedBuffer(
      format: opusFormat, packetCapacity: 1, maximumPacketSize: data.count)
    data.copyBytes(
      to: packet.data.assumingMemoryBound(to: UInt8.self), count: data.count)
    packet.byteLength = UInt32(data.count)
    packet.packetCount = 1
    packet.packetDescriptions?.pointee = AudioStreamPacketDescription(
      mStartOffset: 0, mVariableFramesInPacket: 0, mDataByteSize: UInt32(data.count))

    var handedOver = false
    var failure: NSError?
    let status = converter.convert(to: output, error: &failure) { _, inputStatus in
      if handedOver {
        inputStatus.pointee = .noDataNow
        return nil
      }

      handedOver = true
      inputStatus.pointee = .haveData
      return packet
    }

    if status == .error {
      return nil
    }

    return output
  }

  /// Interleaved 16-bit samples into the engine's own float buffers.
  private func samples(_ data: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
    let channelCount = Int(channels)
    let frameCount = data.count / (2 * channelCount)
    guard frameCount > 0,
      let buffer = AVAudioPCMBuffer(
        pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)),
      let floats = buffer.floatChannelData
    else {
      return nil
    }

    buffer.frameLength = AVAudioFrameCount(frameCount)
    data.withUnsafeBytes { raw in
      for frame in 0..<frameCount {
        for channel in 0..<channelCount {
          let offset = (frame * channelCount + channel) * 2
          let sample = Int16(littleEndian: raw.loadUnaligned(fromByteOffset: offset, as: Int16.self))
          floats[channel][frame] = Float(sample) / 32_768
        }
      }
    }

    return buffer
  }

  private func measure(_ buffer: AVAudioPCMBuffer) {
    frames += Int64(buffer.frameLength)
    guard let floats = buffer.floatChannelData else {
      return
    }

    for channel in 0..<Int(buffer.format.channelCount) {
      for frame in 0..<Int(buffer.frameLength) {
        peak = max(peak, abs(floats[channel][frame]))
      }
    }
  }
}
