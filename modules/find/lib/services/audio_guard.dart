import 'package:core/core.dart';
import 'package:ferret_find/ferret_find.dart';
import 'package:find/models/models.dart';

/// Raises the volume for a ring and puts it back afterwards. The state
/// before ringing is saved in settings first, so a crash mid-ring is undone
/// at the next start.
class AudioGuard {
  AudioGuard(this._platform, this._settings);

  final FindPlatform _platform;
  final FindSettings _settings;

  /// The output state now, or null when the platform can't read it.
  Future<AudioState?> read() async {
    try {
      return await _platform.readAudio();
    } on Object catch (error) {
      printWarning('Could not read the volume', error);
      return null;
    }
  }

  /// Makes [current] as loud as allowed. Keeps an older saved state, which
  /// is the person's own volume when a previous ring never restored.
  Future<void> raise(
    AudioState? current, {
    required bool liftDoNotDisturb,
  }) async {
    if (current == null) {
      return;
    }

    if (_settings.savedAudio == null) {
      await _settings.setSavedAudio(current);
    }

    final loudest = current.loudest(liftDoNotDisturb: liftDoNotDisturb);
    if (loudest == current) {
      return;
    }

    try {
      await _platform.applyAudio(loudest);
    } on Object catch (error) {
      printWarning('Could not raise the volume', error);
    }
  }

  /// Puts back the state saved by [raise], if any.
  Future<void> restore() async {
    final saved = _settings.savedAudio;
    if (saved == null) {
      return;
    }

    try {
      await _platform.applyAudio(saved);
    } on Object catch (error) {
      printWarning('Could not restore the volume', error);
    }

    await _settings.setSavedAudio(null);
  }
}
