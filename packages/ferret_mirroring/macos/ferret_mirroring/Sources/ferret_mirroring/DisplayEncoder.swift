// Real-time H.264 for an extra display. The encoder settings follow
// OpenDisplay (https://github.com/peetzweg/opendisplay, GPL-3.0),
// Mac/MacSender.swift: low-latency rate control, no frame reordering, no
// periodic keyframes, one frame in the encoder at a time.

import CoreMedia
import Foundation
import VideoToolbox

/// One encoded picture, or new parameter sets before it.
struct EncodedPicture {
  /// Annex-B access unit, without parameter sets.
  let data: Data
  let ptsUs: Int64
  let keyframe: Bool

  /// Set when they differ from the last picture's: the viewer needs a new
  /// stream config first.
  let parameterSets: (sps: Data, pps: Data)?
}

final class DisplayEncoder {
  private static let startCode = Data([0, 0, 0, 1])

  private var session: VTCompressionSession?
  private var lastSps = Data()
  private var lastPps = Data()

  let width: Int
  let height: Int

  init(width: Int, height: Int, fps: Int, bitrate: Int) throws {
    self.width = width
    self.height = height
    var status = create(lowLatency: true)
    // Macs whose only encoder is AMD have no low-latency mode: the
    // properties below make the same promises without it.
    if session == nil {
      status = create(lowLatency: false)
    }

    guard let session else {
      throw PigeonError(
        code: "no_encoder", message: "VideoToolbox could not start (\(status))", details: nil)
    }

    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
    VTSessionSetProperty(
      session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
    VTSessionSetProperty(
      session, key: kVTCompressionPropertyKey_ProfileLevel,
      value: kVTProfileLevel_H264_High_AutoLevel)
    // Keyframes only when the viewer asks: each one is a burst of bits.
    VTSessionSetProperty(
      session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: 3600 as CFNumber)
    VTSessionSetProperty(
      session, key: kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, value: 60 as CFNumber)
    VTSessionSetProperty(
      session, key: kVTCompressionPropertyKey_MaxFrameDelayCount, value: 0 as CFNumber)
    VTSessionSetProperty(
      session, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: fps as CFNumber)
    VTSessionSetProperty(
      session, key: kVTCompressionPropertyKey_PrioritizeEncodingSpeedOverQuality,
      value: kCFBooleanTrue)
    setBitrate(bitrate)
    VTCompressionSessionPrepareToEncodeFrames(session)
  }

  deinit {
    invalidate()
  }

  func setBitrate(_ bitrate: Int) {
    guard let session, bitrate > 0 else {
      return
    }

    VTSessionSetProperty(
      session, key: kVTCompressionPropertyKey_AverageBitRate, value: bitrate as CFNumber)
  }

  func invalidate() {
    if let session {
      VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
      VTCompressionSessionInvalidate(session)
    }

    session = nil
  }

  /// Encodes one picture. `done` runs once, on VideoToolbox's thread,
  /// with the picture or nil when it couldn't be encoded. False when the
  /// frame wasn't taken at all.
  func encode(
    _ pixelBuffer: CVPixelBuffer, pts: CMTime, keyframe: Bool,
    done: @escaping (EncodedPicture?) -> Void
  ) -> Bool {
    guard let session else {
      return false
    }

    let properties: CFDictionary? =
      keyframe ? [kVTEncodeFrameOptionKey_ForceKeyFrame: kCFBooleanTrue] as CFDictionary : nil
    let status = VTCompressionSessionEncodeFrame(
      session, imageBuffer: pixelBuffer, presentationTimeStamp: pts, duration: .invalid,
      frameProperties: properties, infoFlagsOut: nil
    ) { [weak self] status, _, sample in
      guard let self, status == noErr, let sample else {
        done(nil)
        return
      }

      done(self.picture(of: sample))
    }

    return status == noErr
  }

  private func create(lowLatency: Bool) -> OSStatus {
    var spec: [CFString: Any] = [:]
    if lowLatency {
      spec[kVTVideoEncoderSpecification_EnableLowLatencyRateControl] = kCFBooleanTrue
    }

    return VTCompressionSessionCreate(
      allocator: nil, width: Int32(width), height: Int32(height),
      codecType: kCMVideoCodecType_H264,
      encoderSpecification: spec.isEmpty ? nil : spec as CFDictionary,
      imageBufferAttributes: nil, compressedDataAllocator: nil, outputCallback: nil, refcon: nil,
      compressionSessionOut: &session)
  }

  private func picture(of sample: CMSampleBuffer) -> EncodedPicture? {
    guard let block = CMSampleBufferGetDataBuffer(sample) else {
      return nil
    }

    var length = 0
    var pointer: UnsafeMutablePointer<Int8>?
    guard
      CMBlockBufferGetDataPointer(
        block, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length,
        dataPointerOut: &pointer) == noErr, let pointer
    else {
      return nil
    }

    // Length-prefixed NAL units become start codes.
    var data = Data(capacity: length + 16)
    let raw = UnsafeRawPointer(pointer)
    var offset = 0
    while offset + 4 <= length {
      var unitLength: UInt32 = 0
      memcpy(&unitLength, raw + offset, 4)
      unitLength = CFSwapInt32BigToHost(unitLength)
      offset += 4
      guard offset + Int(unitLength) <= length else {
        break
      }

      data.append(Self.startCode)
      data.append(Data(bytes: raw + offset, count: Int(unitLength)))
      offset += Int(unitLength)
    }

    let keyframe = isKeyframe(sample)
    let pts = CMSampleBufferGetPresentationTimeStamp(sample)
    return EncodedPicture(
      data: data,
      ptsUs: Int64(CMTimeGetSeconds(pts) * 1_000_000),
      keyframe: keyframe,
      parameterSets: keyframe ? newParameterSets(of: sample) : nil)
  }

  private func isKeyframe(_ sample: CMSampleBuffer) -> Bool {
    guard
      let attachments = CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: false)
        as? [[CFString: Any]], let first = attachments.first
    else {
      return true
    }

    return !(first[kCMSampleAttachmentKey_NotSync] as? Bool ?? false)
  }

  private func newParameterSets(of sample: CMSampleBuffer) -> (sps: Data, pps: Data)? {
    guard let format = CMSampleBufferGetFormatDescription(sample),
      let sps = parameterSet(format, at: 0), let pps = parameterSet(format, at: 1)
    else {
      return nil
    }

    if sps == lastSps && pps == lastPps {
      return nil
    }

    lastSps = sps
    lastPps = pps
    return (sps, pps)
  }

  private func parameterSet(_ format: CMFormatDescription, at index: Int) -> Data? {
    var pointer: UnsafePointer<UInt8>?
    var size = 0
    let status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
      format, parameterSetIndex: index, parameterSetPointerOut: &pointer,
      parameterSetSizeOut: &size, parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil)
    guard status == noErr, let pointer else {
      return nil
    }

    return Data(bytes: pointer, count: size)
  }
}
