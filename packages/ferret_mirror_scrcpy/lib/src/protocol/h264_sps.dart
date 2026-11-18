import 'dart:typed_data';

import 'package:ferret_mirror_scrcpy/src/protocol/annex_b.dart';
import 'package:ferret_mirror_scrcpy/src/protocol/bit_reader.dart';

/// What a sequence parameter set says about the picture.
class H264Sps {
  const H264Sps({
    required this.profile,
    required this.level,
    required this.width,
    required this.height,
  });

  static const Set<int> _profilesWithChromaInfo = {
    100, 110, 122, 244, 44, 83, 86, 118, 128, 138, 139, 134, 135, //
  };

  final int profile;
  final int level;

  /// The size shown, after cropping.
  final int width;
  final int height;

  /// Reads [unit], one SPS NAL unit without its start code (H.264 spec,
  /// 7.3.2.1.1). Throws a [FormatException] when it isn't one.
  static H264Sps parse(Uint8List unit) {
    if (unit.isEmpty || AnnexB.typeOf(unit) != AnnexB.sequenceParameterSet) {
      throw const FormatException('Not a sequence parameter set');
    }

    final reader = BitReader(AnnexB.payload(unit));
    final profile = reader.bits(8);
    reader.bits(8);
    final level = reader.bits(8);
    reader.unsignedExpGolomb();

    final chromaFormat = _readChromaFormat(reader, profile);
    _skipPictureOrder(reader);
    reader.unsignedExpGolomb();
    reader.flag();

    final widthInMacroblocks = reader.unsignedExpGolomb() + 1;
    final heightInMapUnits = reader.unsignedExpGolomb() + 1;
    final isFrameOnly = reader.flag();
    if (!isFrameOnly) {
      reader.flag();
    }
    reader.flag();

    final crop = _readCrop(reader);
    final frameHeightFactor = switch (isFrameOnly) {
      true => 1,
      false => 2,
    };
    final (cropUnitX, cropUnitY) = switch (chromaFormat) {
      0 => (1, frameHeightFactor),
      1 => (2, 2 * frameHeightFactor),
      2 => (2, frameHeightFactor),
      _ => (1, frameHeightFactor),
    };

    return H264Sps(
      profile: profile,
      level: level,
      width: widthInMacroblocks * 16 - cropUnitX * (crop.left + crop.right),
      height:
          heightInMapUnits * 16 * frameHeightFactor -
          cropUnitY * (crop.top + crop.bottom),
    );
  }

  static int _readChromaFormat(BitReader reader, int profile) {
    if (!_profilesWithChromaInfo.contains(profile)) {
      return 1;
    }

    final chromaFormat = reader.unsignedExpGolomb();
    if (chromaFormat == 3) {
      reader.flag();
    }
    reader.unsignedExpGolomb();
    reader.unsignedExpGolomb();
    reader.flag();

    final hasScalingMatrix = reader.flag();
    if (hasScalingMatrix) {
      _skipScalingLists(reader, chromaFormat);
    }

    return chromaFormat;
  }

  static void _skipScalingLists(BitReader reader, int chromaFormat) {
    final listCount = switch (chromaFormat) {
      3 => 12,
      _ => 8,
    };
    for (var listIndex = 0; listIndex < listCount; listIndex++) {
      final isPresent = reader.flag();
      if (!isPresent) {
        continue;
      }

      final size = switch (listIndex < 6) {
        true => 16,
        false => 64,
      };
      _skipScalingList(reader, size);
    }
  }

  static void _skipScalingList(BitReader reader, int size) {
    var lastScale = 8;
    var nextScale = 8;
    for (var index = 0; index < size; index++) {
      if (nextScale != 0) {
        nextScale = (lastScale + reader.signedExpGolomb() + 256) % 256;
      }
      if (nextScale != 0) {
        lastScale = nextScale;
      }
    }
  }

  static void _skipPictureOrder(BitReader reader) {
    reader.unsignedExpGolomb();
    final pictureOrderType = reader.unsignedExpGolomb();
    if (pictureOrderType == 0) {
      reader.unsignedExpGolomb();
      return;
    }

    if (pictureOrderType != 1) {
      return;
    }

    reader.flag();
    reader.signedExpGolomb();
    reader.signedExpGolomb();
    final cycleLength = reader.unsignedExpGolomb();
    for (var index = 0; index < cycleLength; index++) {
      reader.signedExpGolomb();
    }
  }

  static ({int left, int right, int top, int bottom}) _readCrop(
    BitReader reader,
  ) {
    final hasCrop = reader.flag();
    if (!hasCrop) {
      return (left: 0, right: 0, top: 0, bottom: 0);
    }

    final left = reader.unsignedExpGolomb();
    final right = reader.unsignedExpGolomb();
    final top = reader.unsignedExpGolomb();
    final bottom = reader.unsignedExpGolomb();
    return (left: left, right: right, top: top, bottom: bottom);
  }
}
