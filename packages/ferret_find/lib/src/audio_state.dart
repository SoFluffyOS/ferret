/// The output volume, mute and Do Not Disturb state, saved before ringing
/// and put back afterwards.
class AudioState {
  const AudioState({
    required this.volume,
    required this.maxVolume,
    this.muted = false,
    this.interruptionFilter = unknownFilter,
    this.quiet = false,
  });

  /// [interruptionFilter] when the platform has no Do Not Disturb filter.
  static const unknownFilter = 0;

  /// Android's `INTERRUPTION_FILTER_ALL`: Do Not Disturb is off.
  static const filterAll = 1;

  final int volume;
  final int maxVolume;
  final bool muted;
  final int interruptionFilter;

  /// On silent, vibrate or Do Not Disturb. Read only: applying a state never
  /// changes it directly.
  final bool quiet;

  bool get isLoudest =>
      volume >= maxVolume &&
      !muted &&
      (interruptionFilter == unknownFilter || interruptionFilter == filterAll);

  /// The loudest state: full volume, unmuted, and Do Not Disturb lifted when
  /// [liftDoNotDisturb] (it needs a permission on Android).
  AudioState loudest({required bool liftDoNotDisturb}) => AudioState(
    volume: maxVolume,
    maxVolume: maxVolume,
    interruptionFilter: switch (liftDoNotDisturb &&
        interruptionFilter != unknownFilter) {
      true => filterAll,
      false => interruptionFilter,
    },
    quiet: quiet,
  );

  Map<String, Object?> toJson() => {
    'volume': volume,
    'max_volume': maxVolume,
    'muted': muted,
    'interruption_filter': interruptionFilter,
  };

  /// The state saved by [toJson], or null when [json] isn't one.
  static AudioState? fromJson(Object? json) {
    if (json case {
      'volume': final int volume,
      'max_volume': final int maxVolume,
      'muted': final bool muted,
      'interruption_filter': final int interruptionFilter,
    }) {
      return AudioState(
        volume: volume,
        maxVolume: maxVolume,
        muted: muted,
        interruptionFilter: interruptionFilter,
      );
    }

    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is AudioState &&
      other.volume == volume &&
      other.maxVolume == maxVolume &&
      other.muted == muted &&
      other.interruptionFilter == interruptionFilter &&
      other.quiet == quiet;

  @override
  int get hashCode =>
      Object.hash(volume, maxVolume, muted, interruptionFilter, quiet);

  @override
  String toString() =>
      'AudioState($volume/$maxVolume, muted: $muted, '
      'filter: $interruptionFilter, quiet: $quiet)';
}
