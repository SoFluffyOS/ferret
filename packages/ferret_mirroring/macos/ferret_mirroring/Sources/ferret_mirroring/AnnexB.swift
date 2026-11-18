import Foundation

/// H.264 as the encoder sends it: NAL units separated by start codes
/// (00 00 01 or 00 00 00 01). VideoToolbox wants each unit behind a 4-byte
/// length instead.
enum AnnexB {
  private static let sequenceParameterSet: UInt8 = 7
  private static let pictureParameterSet: UInt8 = 8
  private static let accessUnitDelimiter: UInt8 = 9

  /// The ranges of the NAL units in `data`, without their start codes.
  static func units(in data: Data) -> [Range<Int>] {
    var units: [Range<Int>] = []
    var unitStart: Int? = nil
    var index = 0
    let count = data.count

    data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
      while index + 2 < count {
        guard bytes[index] == 0, bytes[index + 1] == 0, bytes[index + 2] == 1 else {
          index += 1
          continue
        }

        if let start = unitStart {
          var end = index
          while end > start, bytes[end - 1] == 0 {
            end -= 1
          }

          if end > start {
            units.append(start..<end)
          }
        }

        unitStart = index + 3
        index += 3
      }
    }

    if let start = unitStart, start < count {
      units.append(start..<count)
    }

    return units
  }

  /// The picture data of one access unit, each NAL unit behind its length.
  /// Parameter sets and delimiters are left out: the decoder has the sets
  /// from its format description.
  static func lengthPrefixed(_ data: Data) -> Data {
    var result = Data(capacity: data.count + 16)
    for unit in units(in: data) {
      let kind = data[data.startIndex + unit.lowerBound] & 0x1f
      if kind == sequenceParameterSet || kind == pictureParameterSet
        || kind == accessUnitDelimiter
      {
        continue
      }

      var length = UInt32(unit.count).bigEndian
      withUnsafeBytes(of: &length) { result.append(contentsOf: $0) }
      result.append(data.subdata(in: (data.startIndex + unit.lowerBound)..<(data.startIndex + unit.upperBound)))
    }

    return result
  }
}
