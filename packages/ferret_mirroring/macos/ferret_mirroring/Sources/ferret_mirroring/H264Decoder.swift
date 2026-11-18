import CoreMedia
import CoreVideo
import Foundation
import VideoToolbox
import sofluffy_texture

/// Decodes H.264 access units with VideoToolbox, on its own queue, into
/// BGRA pixel buffers Metal can draw without a copy, and shows each on a
/// sofluffy_texture texture.
final class H264Decoder {
  private let queue = DispatchQueue(label: "io.sofluffy.ferret_mirroring.decoder")
  private let texture: OpaquePointer
  private let onPicture: (Int, Int, Int64) -> Void
  private let onError: (OSStatus) -> Void
  private var format: CMVideoFormatDescription?
  private var session: VTDecompressionSession?
  private var needsKeyframe = true
  private var invalidated = false
  private var shown: CVPixelBuffer?

  /// Pictures go to `texture`, which must outlive the decoder: call
  /// `invalidate` before disposing it. `onPicture` gets the size and
  /// timestamp of each picture shown. Both callbacks run on the decoder's
  /// queue.
  init(
    texture: OpaquePointer,
    onPicture: @escaping (Int, Int, Int64) -> Void,
    onError: @escaping (OSStatus) -> Void
  ) {
    self.texture = texture
    self.onPicture = onPicture
    self.onError = onError
  }

  /// Sets up for a stream with these parameter sets. Returns the status
  /// VideoToolbox gave, `noErr` when it worked.
  func configure(sps: Data, pps: Data) -> OSStatus {
    queue.sync {
      closeSession()
      var created: CMVideoFormatDescription?
      let status = sps.withUnsafeBytes { (spsBytes: UnsafeRawBufferPointer) -> OSStatus in
        pps.withUnsafeBytes { (ppsBytes: UnsafeRawBufferPointer) -> OSStatus in
          guard let spsBase = spsBytes.bindMemory(to: UInt8.self).baseAddress,
            let ppsBase = ppsBytes.bindMemory(to: UInt8.self).baseAddress
          else {
            return kCMFormatDescriptionError_InvalidParameter
          }

          let sets = [spsBase, ppsBase]
          let sizes = [sps.count, pps.count]
          return CMVideoFormatDescriptionCreateFromH264ParameterSets(
            allocator: kCFAllocatorDefault,
            parameterSetCount: 2,
            parameterSetPointers: sets,
            parameterSetSizes: sizes,
            nalUnitHeaderLength: 4,
            formatDescriptionOut: &created)
        }
      }
      guard status == noErr, let created else {
        return status
      }

      format = created
      needsKeyframe = true
      return openSession(for: created)
    }
  }

  func decode(data: Data, ptsUs: Int64, keyframe: Bool) {
    queue.async { [weak self] in
      self?.decodeNow(data: data, ptsUs: ptsUs, keyframe: keyframe)
    }
  }

  func invalidate() {
    queue.sync {
      invalidated = true
      closeSession()
      format = nil
      shown = nil
    }
  }

  /// The picture on the texture right now, or nil before the first one.
  func picture() -> CVPixelBuffer? {
    queue.sync { shown }
  }

  private func openSession(for format: CMVideoFormatDescription) -> OSStatus {
    let attributes: [CFString: Any] = [
      kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
      kCVPixelBufferMetalCompatibilityKey: true,
      kCVPixelBufferIOSurfacePropertiesKey: [String: Any](),
    ]
    var created: VTDecompressionSession?
    let status = VTDecompressionSessionCreate(
      allocator: kCFAllocatorDefault,
      formatDescription: format,
      decoderSpecification: nil,
      imageBufferAttributes: attributes as CFDictionary,
      outputCallback: nil,
      decompressionSessionOut: &created)
    guard status == noErr, let created else {
      return status
    }

    VTSessionSetProperty(created, key: kVTDecompressionPropertyKey_RealTime, value: kCFBooleanTrue)
    session = created
    return noErr
  }

  private func closeSession() {
    guard let session else {
      return
    }

    VTDecompressionSessionInvalidate(session)
    self.session = nil
  }

  private func decodeNow(data: Data, ptsUs: Int64, keyframe: Bool) {
    guard !invalidated, let format else {
      return
    }

    if needsKeyframe && !keyframe {
      return
    }

    if session == nil, openSession(for: format) != noErr {
      fail(kVTInvalidSessionErr)
      return
    }

    guard let session, let sample = sampleBuffer(data: data, ptsUs: ptsUs, format: format) else {
      fail(kVTParameterErr)
      return
    }

    var decodeStatus: OSStatus = noErr
    var picture: CVImageBuffer?
    let status = VTDecompressionSessionDecodeFrame(
      session, sampleBuffer: sample, flags: [], infoFlagsOut: nil
    ) { frameStatus, _, imageBuffer, _, _ in
      decodeStatus = frameStatus
      picture = imageBuffer
    }

    if status == kVTInvalidSessionErr {
      // The system took the decoder away, such as after sleep. A new one
      // starts from the next keyframe.
      closeSession()
    }

    guard status == noErr, decodeStatus == noErr, let picture else {
      fail(status != noErr ? status : decodeStatus)
      return
    }

    needsKeyframe = false
    // The texture keeps the buffer until the next picture is on screen,
    // then VideoToolbox's pool has it back.
    sft_texture_present_pixel_buffer(texture, picture)
    shown = picture
    onPicture(CVPixelBufferGetWidth(picture), CVPixelBufferGetHeight(picture), ptsUs)
  }

  private func fail(_ status: OSStatus) {
    needsKeyframe = true
    onError(status)
  }

  private func sampleBuffer(data: Data, ptsUs: Int64, format: CMVideoFormatDescription)
    -> CMSampleBuffer?
  {
    let payload = AnnexB.lengthPrefixed(data)
    guard !payload.isEmpty else {
      return nil
    }

    var block: CMBlockBuffer?
    var status = CMBlockBufferCreateWithMemoryBlock(
      allocator: kCFAllocatorDefault,
      memoryBlock: nil,
      blockLength: payload.count,
      blockAllocator: kCFAllocatorDefault,
      customBlockSource: nil,
      offsetToData: 0,
      dataLength: payload.count,
      flags: kCMBlockBufferAssureMemoryNowFlag,
      blockBufferOut: &block)
    guard status == kCMBlockBufferNoErr, let block else {
      return nil
    }

    status = payload.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> OSStatus in
      guard let base = bytes.baseAddress else {
        return kCMBlockBufferBadPointerParameterErr
      }

      return CMBlockBufferReplaceDataBytes(
        with: base, blockBuffer: block, offsetIntoDestination: 0, dataLength: payload.count)
    }
    guard status == kCMBlockBufferNoErr else {
      return nil
    }

    var timing = CMSampleTimingInfo(
      duration: .invalid,
      presentationTimeStamp: CMTime(value: ptsUs, timescale: 1_000_000),
      decodeTimeStamp: .invalid)
    var size = payload.count
    var sample: CMSampleBuffer?
    status = CMSampleBufferCreateReady(
      allocator: kCFAllocatorDefault,
      dataBuffer: block,
      formatDescription: format,
      sampleCount: 1,
      sampleTimingEntryCount: 1,
      sampleTimingArray: &timing,
      sampleSizeEntryCount: 1,
      sampleSizeArray: &size,
      sampleBufferOut: &sample)
    guard status == noErr else {
      return nil
    }

    return sample
  }
}
