import 'dart:async';

import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:remote_input/feature/remote_input_feature.dart';

/// The presentation remote: Next and Back as a clicker sends them, a black
/// screen, and how long the talk has run.
class PresentationViewModel extends ChangeNotifier {
  PresentationViewModel(this.feature, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final RemoteInputFeature feature;
  final DateTime Function() _clock;

  DateTime? _startedAt;
  Timer? _ticker;
  bool _isBlack = false;

  /// Whether the slides are blacked out, as far as this phone knows.
  bool get isBlack => _isBlack;

  /// How long since the first slide turned, or since the timer restarted.
  Duration get elapsed => switch (_startedAt) {
    final startedAt? => _clock().difference(startedAt),
    null => Duration.zero,
  };

  bool get isTiming => _startedAt != null;

  // Presenter clickers send Page Down and Page Up, which PowerPoint,
  // Keynote, Google Slides and PDF viewers all take in full screen.
  void next() => _tap(.pageDown);

  void previous() => _tap(.pageUp);

  /// B blacks the screen out in PowerPoint, Keynote and Google Slides, and
  /// brings the slide back.
  void toggleBlack() {
    _isBlack = !_isBlack;
    _tap(.b, startsTimer: false);
  }

  void restartTimer() {
    _startedAt = null;
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void _tap(InputKey key, {bool startsTimer = true}) {
    unawaited(HapticFeedback.selectionClick());
    feature.client?.tapKey(key);
    if (startsTimer && _startedAt == null) {
      _startedAt = _clock();
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => notifyListeners(),
      );
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
