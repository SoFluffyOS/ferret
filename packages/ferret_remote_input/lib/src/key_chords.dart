import 'package:ferret_remote_input/src/keys/keys.dart';

/// One raw key press or release, in a platform's codes.
typedef RawKey = ({int code, bool pressed});

/// Turns a key with modifiers into raw presses, for platforms that hold the
/// modifier keys themselves (Windows, uinput, ydotool). Only modifiers that
/// aren't already down are pressed, and released again with the key.
/// Modifiers held on their own ([latch]) stay down across keys.
class KeyChords {
  KeyChords(this._modifierCodes);

  final Map<KeyModifier, int> _modifierCodes;
  final Map<int, Set<KeyModifier>> _added = {};
  Set<KeyModifier> _latched = const {};

  List<RawKey> press(int code, Set<KeyModifier> modifiers) {
    final repeated = _added.remove(code) ?? const <KeyModifier>{};
    final held = {..._addedByKeys, ..._latched, ...repeated};
    final toPress = modifiers.difference(held);
    _added[code] = {...repeated, ...toPress};

    return [
      for (final modifier in KeyModifier.values)
        if (toPress.contains(modifier))
          (code: _codeOf(modifier), pressed: true),
      (code: code, pressed: true),
    ];
  }

  List<RawKey> release(int code) {
    final added = _added.remove(code) ?? const <KeyModifier>{};
    final stillHeld = {..._addedByKeys, ..._latched};

    return [
      (code: code, pressed: false),
      for (final modifier in KeyModifier.values.reversed)
        if (added.contains(modifier) && !stillHeld.contains(modifier))
          (code: _codeOf(modifier), pressed: false),
    ];
  }

  /// Holds exactly [held] down on their own, such as Shift for a
  /// Shift-click: the presses and releases that get there.
  List<RawKey> latch(Set<KeyModifier> held) {
    final byKeys = _addedByKeys;
    final toRelease = _latched.difference(held).difference(byKeys);
    final toPress = held.difference(_latched).difference(byKeys);
    _latched = Set.unmodifiable(held);

    return [
      for (final modifier in KeyModifier.values.reversed)
        if (toRelease.contains(modifier))
          (code: _codeOf(modifier), pressed: false),
      for (final modifier in KeyModifier.values)
        if (toPress.contains(modifier))
          (code: _codeOf(modifier), pressed: true),
    ];
  }

  /// A press and release, such as for a typed character with Shift.
  List<RawKey> tap(int code, Set<KeyModifier> modifiers) => [
    ...press(code, modifiers),
    ...release(code),
  ];

  void reset() {
    _added.clear();
    _latched = const {};
  }

  Set<KeyModifier> get _addedByKeys => {
    for (final added in _added.values) ...added,
  };

  int _codeOf(KeyModifier modifier) => _modifierCodes[modifier] ?? 0;
}
