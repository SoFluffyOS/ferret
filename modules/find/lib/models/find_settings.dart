import 'package:core/core.dart';
import 'package:ferret_find/ferret_find.dart';

/// Find my device's settings, stored under `find.*`.
class FindSettings {
  const FindSettings(this._store);

  static const ringOnSilentKey = 'find.ring_on_silent';
  static const flashTorchKey = 'find.flash_torch';

  /// The volume before ringing, kept until it is put back so a crash while
  /// ringing doesn't leave the phone at full volume.
  static const savedAudioKey = 'find.saved_audio';

  final SettingsStore _store;

  /// Rings at full volume through silent and Do Not Disturb (lesson: finding
  /// a phone must work even when it is muted).
  bool get ringOnSilent => _store.get<bool>(ringOnSilentKey) ?? true;

  /// Blinks the torch while ringing, on phones that have one.
  bool get flashTorch => _store.get<bool>(flashTorchKey) ?? true;

  AudioState? get savedAudio =>
      AudioState.fromJson(_store.get<Object>(savedAudioKey));

  Future<void> setRingOnSilent(bool value) =>
      _store.set(ringOnSilentKey, value);

  Future<void> setFlashTorch(bool value) => _store.set(flashTorchKey, value);

  Future<void> setSavedAudio(AudioState? state) =>
      _store.set(savedAudioKey, state?.toJson());

  /// Fires with the key of each setting people change.
  Stream<String> get changes => _store.changes.where(
    (key) => key.startsWith('find.') && key != savedAudioKey,
  );
}
