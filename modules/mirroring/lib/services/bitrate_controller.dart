import 'package:mirroring/services/mirror_protocol.dart';

/// Picks the video bitrate from how the last second went: down fast when
/// frames were dropped, back up slowly after a calm stretch.
class BitrateController {
  BitrateController({
    this.min = MirrorProtocol.minBitrate,
    this.max = MirrorProtocol.maxBitrate,
    int start = MirrorProtocol.startBitrate,
    this.calmWindowsToRaise = 5,
  }) : _bitrate = start.clamp(min, max);

  static const _lowerTo = 0.7;
  static const _raiseTo = 1.2;

  final int min;
  final int max;

  /// How many seconds in a row without a drop before trying more.
  final int calmWindowsToRaise;

  int _bitrate;
  int _calmWindows = 0;

  /// Bits per second.
  int get bitrate => _bitrate;

  /// Takes one second's result. Returns the new bitrate when it changed.
  int? onWindow({required bool congested}) {
    final previous = _bitrate;
    if (congested) {
      _calmWindows = 0;
      _bitrate = (_bitrate * _lowerTo).round().clamp(min, max);
      return _changedFrom(previous);
    }

    _calmWindows++;
    if (_calmWindows < calmWindowsToRaise) {
      return null;
    }

    _calmWindows = 0;
    _bitrate = (_bitrate * _raiseTo).round().clamp(min, max);
    return _changedFrom(previous);
  }

  int? _changedFrom(int previous) {
    if (_bitrate == previous) {
      return null;
    }

    return _bitrate;
  }
}
