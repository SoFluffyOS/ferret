import 'dart:async';

import 'package:core/core.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/foundation.dart';

/// How setting the decoder up for a new stream went.
enum ConfigureResult {
  ready,

  /// A newer config arrived, or the player closed, before this one was
  /// set up.
  superseded,

  /// This computer can't decode the stream.
  failed,
}

/// Plays one feed's frames, whatever route they came through: sets the
/// decoder up for each config, keeps frames while it does, skips to the
/// next keyframe when a frame is lost or the decoder backs up, and counts
/// what it shows.
class FeedPlayer {
  FeedPlayer({
    required MirrorDecoder decoder,
    required DateTime Function() clock,
    required this.maxDecoding,
    required void Function() onShown,
    required void Function() onKeyframeNeeded,
  }) : _decoder = decoder,
       _clock = clock,
       _onShown = onShown,
       _onKeyframeNeeded = onKeyframeNeeded {
    _subscriptions
      ..add(decoder.decoded.listen(_onDecoded))
      ..add(decoder.errors.listen((_) => _loseKeyframe()));
  }

  /// Frames handed to the decoder and not shown yet at which new ones are
  /// dropped, up to the next keyframe.
  final int maxDecoding;

  /// Frames kept while the decoder is being set up for a new config.
  static const _maxHeldFrames = 120;
  static const _keyframeRequestGap = Duration(milliseconds: 500);

  final MirrorDecoder _decoder;
  final DateTime Function() _clock;
  final void Function() _onShown;
  final void Function() _onKeyframeNeeded;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Map<int, DateTime> _decodingSince = {};
  final List<MirrorFrame> _held = [];

  int _configuration = 0;
  bool _configuring = false;
  bool _needsKeyframe = true;
  bool _closed = false;
  DateTime? _keyframeAskedAt;
  int _shownInWindow = 0;
  int _droppedInWindow = 0;
  int _decodeMs = 0;

  /// The picture to draw, or null before the first frame.
  ValueListenable<MirrorPicture?> get picture => _decoder.picture;

  /// How long the last picture took to decode.
  int get decodeMs => _decodeMs;

  /// Sets the decoder up for [config]. Frames that arrive meanwhile wait,
  /// and play in order once it is ready.
  Future<ConfigureResult> configure(MirrorStreamConfig config) async {
    final configuration = ++_configuration;
    _configuring = true;
    _needsKeyframe = true;
    _held.clear();
    _decodingSince.clear();
    try {
      await _decoder.configure(config);
    } on Object catch (error) {
      printWarning('This computer cannot decode the mirrored screen', error);
      if (_closed) {
        return .superseded;
      }

      return .failed;
    }

    if (_closed || configuration != _configuration) {
      return .superseded;
    }

    _configuring = false;
    final held = List.of(_held);
    _held.clear();
    for (final frame in held) {
      _decode(frame);
    }

    return .ready;
  }

  /// Takes the next frame of the feed, with how many were lost before it.
  void add(MirrorFrame frame, {int lost = 0}) {
    if (_closed) {
      return;
    }

    _droppedInWindow += lost;
    if (_configuring) {
      if (_held.length < _maxHeldFrames) {
        _held.add(frame);
      }

      return;
    }

    _decode(frame);
  }

  /// Pictures shown and frames dropped since the last call.
  ({int shown, int dropped}) takeWindow() {
    final window = (shown: _shownInWindow, dropped: _droppedInWindow);
    _shownInWindow = 0;
    _droppedInWindow = 0;
    return window;
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;
    _held.clear();
    _decodingSince.clear();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    try {
      await _decoder.dispose();
    } on Object catch (error) {
      printWarning('Closing the mirror decoder failed', error);
    }
  }

  void _decode(MirrorFrame frame) {
    if (_needsKeyframe && !frame.keyframe) {
      _droppedInWindow++;
      return;
    }

    if (_decodingSince.length >= maxDecoding) {
      _droppedInWindow++;
      _decodingSince.clear();
      _loseKeyframe();
      return;
    }

    _needsKeyframe = false;
    _decodingSince[frame.ptsUs] = _clock();
    _decoder.decode(frame);
  }

  void _onDecoded(DecodedFrame frame) {
    _shownInWindow++;
    final since = _decodingSince.remove(frame.ptsUs);
    _decodingSince.removeWhere((ptsUs, _) => ptsUs < frame.ptsUs);
    if (since != null) {
      _decodeMs = _clock().difference(since).inMilliseconds;
    }

    _onShown();
  }

  /// A frame was lost: nothing decodes until the other side sends a
  /// keyframe. Asks for one, but not again within the gap.
  void _loseKeyframe() {
    _needsKeyframe = true;
    _decodingSince.clear();
    final now = _clock();
    final askedAt = _keyframeAskedAt;
    if (_closed ||
        (askedAt != null && now.difference(askedAt) < _keyframeRequestGap)) {
      return;
    }

    _keyframeAskedAt = now;
    _onKeyframeNeeded();
  }
}
