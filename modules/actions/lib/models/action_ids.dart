/// The ids of the actions every computer knows. A custom action's id
/// starts with [customPrefix].
abstract final class ActionIds {
  static const sleep = 'sleep';
  static const restart = 'restart';
  static const shutDown = 'shut_down';
  static const mute = 'mute';
  static const volumeUp = 'volume_up';
  static const volumeDown = 'volume_down';

  static const customPrefix = 'custom.';

  /// What "Always allow" for mute or a volume step covers: all three.
  static const soundGrant = 'sound';
}
