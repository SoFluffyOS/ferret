import 'package:ferret_remote_input/src/input_action.dart';
import 'package:ferret_remote_input/src/keys/keys.dart';

/// The buttons and keys an injector holds down, so they can all be let go
/// when control ends, even if the controller vanished mid-drag.
class HeldInput {
  final Set<PointerButton> _buttons = {};
  final Map<InputKey, Set<KeyModifier>> _keys = {};
  Set<KeyModifier> _modifiers = const {};

  bool get isEmpty => _buttons.isEmpty && _keys.isEmpty && _modifiers.isEmpty;

  /// The modifier keys held on their own, from [ModifiersAction].
  Set<KeyModifier> get modifiers => _modifiers;

  /// Records [action]. Returns false when it changes nothing, such as a
  /// release of a button that isn't down, so injectors can skip it.
  bool track(InputAction action) {
    switch (action) {
      case ButtonAction(:final button, pressed: true):
        return _buttons.add(button);
      case ButtonAction(:final button, pressed: false):
        return _buttons.remove(button);
      case KeyAction(:final key, pressed: true, :final modifiers):
        _keys[key] = modifiers;
        return true;
      case KeyAction(:final key, pressed: false):
        return _keys.remove(key) != null;
      case ModifiersAction(:final held):
        final changed =
            held.length != _modifiers.length || !_modifiers.containsAll(held);
        _modifiers = Set.unmodifiable(held);
        return changed;
      case MoveAction() || ScrollAction() || TextAction():
        return true;
    }
  }

  /// The modifiers [key] was pressed with, or none.
  Set<KeyModifier> modifiersOf(InputKey key) => _keys[key] ?? const {};

  /// The releases for everything held, and forgets it.
  List<InputAction> releaseAll() {
    final releases = <InputAction>[
      for (final button in _buttons) ButtonAction(button, pressed: false),
      for (final MapEntry(key: key, value: modifiers) in _keys.entries)
        KeyAction(key, pressed: false, modifiers: modifiers),
      if (_modifiers.isNotEmpty) const ModifiersAction({}),
    ];
    _buttons.clear();
    _keys.clear();
    _modifiers = const {};
    return releases;
  }
}
