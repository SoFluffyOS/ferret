import 'dart:async';

import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:remote_input/feature/remote_input_feature.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/services/services.dart';

/// The touchpad page and the phone's card: where control of another device
/// stands, and the touches, keys and text to send it.
class TouchpadViewModel extends ChangeNotifier implements TouchpadSink {
  TouchpadViewModel(this.feature) {
    _subscription = feature.changes.listen((_) => notifyListeners());
  }

  final RemoteInputFeature feature;
  late final StreamSubscription<void> _subscription;
  final Set<KeyModifier> _armed = {};

  ControlClient? get _client => feature.client;

  OutgoingControl? get current => _client?.current;

  /// Modifiers that apply to the next key or character, like a sticky
  /// Ctrl on a phone keyboard.
  Set<KeyModifier> get armed => Set.unmodifiable(_armed);

  double get speed => feature.settings.touchpadSpeed;

  bool get naturalScroll => feature.settings.naturalScroll;

  Future<void> setSpeed(double value) =>
      feature.settings.setTouchpadSpeed(value);

  Future<void> setNaturalScroll(bool value) =>
      feature.settings.setNaturalScroll(value);

  Future<void> start(String deviceId) async => feature.control(deviceId);

  Future<void> stop() async => _client?.stop();

  void dismiss() => _client?.dismiss();

  @override
  void move(double dx, double dy, Duration elapsed) {
    final (pointerX, pointerY) = PointerAcceleration(
      speed: speed,
    ).apply(dx, dy, elapsed);
    _client?.move(pointerX, pointerY);
  }

  /// Fingers moving up scroll down with natural scrolling, as on a touch
  /// screen; the other way, as on a mouse wheel, without it.
  @override
  void scroll(double dx, double dy) {
    final direction = switch (naturalScroll) {
      true => -1.0,
      false => 1.0,
    };
    _client?.scroll(dx * direction * speed, dy * direction * speed);
  }

  @override
  void click(PointerButton button) {
    unawaited(HapticFeedback.selectionClick());
    _client?.click(button);
  }

  @override
  void press(PointerButton button) {
    unawaited(HapticFeedback.selectionClick());
    _client?.press(button);
  }

  @override
  void release(PointerButton button) => _client?.release(button);

  void toggleModifier(KeyModifier modifier) {
    if (!_armed.remove(modifier)) {
      _armed.add(modifier);
    }

    notifyListeners();
  }

  void tapKey(InputKey key) {
    _client?.tapKey(key, modifiers: _takeArmed());
  }

  /// What the keyboard field typed: Backspace for each deleted character,
  /// then the new text. With a modifier armed, a letter or digit goes as a
  /// shortcut, such as Ctrl+C.
  void typed(TextChange change) {
    for (var count = 0; count < change.deleted; count++) {
      _client?.tapKey(.backspace);
    }

    final text = change.inserted;
    if (text.isEmpty) {
      return;
    }

    if (_armed.isNotEmpty) {
      if (InputKey.ofCharacter(text) case final key?) {
        _client?.tapKey(key, modifiers: _takeArmed());
        return;
      }
    }

    _client?.type(text);
  }

  Set<KeyModifier> _takeArmed() {
    if (_armed.isEmpty) {
      return const {};
    }

    final modifiers = Set.of(_armed);
    _armed.clear();
    notifyListeners();
    return modifiers;
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
