// This is a generated file - do not edit.
//
// Generated from ferret/remote_input/v1/remote_input.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// What kind of controller asks.
class ControlMode extends $pb.ProtobufEnum {
  /// A phone or tablet used as a touchpad and keyboard. Every controller
  /// sent this before modes existed.
  static const ControlMode CONTROL_MODE_UNSPECIFIED =
      ControlMode._(0, _omitEnumNames ? '' : 'CONTROL_MODE_UNSPECIFIED');

  /// Another computer lending its own keyboard and mouse: it sends
  /// `EnterScreen` when its person switches over, `LeaveScreen` when they
  /// switch back, and modifier keys as `ModifierState`. Send it only to a
  /// computer whose `FeatureSupport` flags for this feature include
  /// "screen"; older computers treat it as a phone.
  static const ControlMode CONTROL_MODE_SCREEN =
      ControlMode._(1, _omitEnumNames ? '' : 'CONTROL_MODE_SCREEN');

  static const $core.List<ControlMode> values = <ControlMode>[
    CONTROL_MODE_UNSPECIFIED,
    CONTROL_MODE_SCREEN,
  ];

  static final $core.List<ControlMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static ControlMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ControlMode._(super.value, super.name);
}

/// Why a computer said no.
class DenyReason extends $pb.ProtobufEnum {
  static const DenyReason DENY_REASON_UNSPECIFIED =
      DenyReason._(0, _omitEnumNames ? '' : 'DENY_REASON_UNSPECIFIED');

  /// Its owner said no.
  static const DenyReason DENY_REASON_DENIED =
      DenyReason._(1, _omitEnumNames ? '' : 'DENY_REASON_DENIED');

  /// Nobody answered on the computer in time.
  static const DenyReason DENY_REASON_TIMEOUT =
      DenyReason._(2, _omitEnumNames ? '' : 'DENY_REASON_TIMEOUT');

  /// Another device controls it, or asks to, right now.
  static const DenyReason DENY_REASON_BUSY =
      DenyReason._(3, _omitEnumNames ? '' : 'DENY_REASON_BUSY');

  /// The system permission to control input is missing, such as
  /// Accessibility on macOS. The computer shows its owner how to allow it.
  static const DenyReason DENY_REASON_NEEDS_PERMISSION =
      DenyReason._(4, _omitEnumNames ? '' : 'DENY_REASON_NEEDS_PERMISSION');

  /// This computer has no way to inject input, such as Linux without uinput
  /// access, xdotool or ydotool.
  static const DenyReason DENY_REASON_UNSUPPORTED =
      DenyReason._(5, _omitEnumNames ? '' : 'DENY_REASON_UNSUPPORTED');

  /// Its owner turned remote input off.
  static const DenyReason DENY_REASON_TURNED_OFF =
      DenyReason._(6, _omitEnumNames ? '' : 'DENY_REASON_TURNED_OFF');

  /// The controller speaks a newer major version.
  static const DenyReason DENY_REASON_VERSION =
      DenyReason._(7, _omitEnumNames ? '' : 'DENY_REASON_VERSION');

  static const $core.List<DenyReason> values = <DenyReason>[
    DENY_REASON_UNSPECIFIED,
    DENY_REASON_DENIED,
    DENY_REASON_TIMEOUT,
    DENY_REASON_BUSY,
    DENY_REASON_NEEDS_PERMISSION,
    DENY_REASON_UNSUPPORTED,
    DENY_REASON_TURNED_OFF,
    DENY_REASON_VERSION,
  ];

  static final $core.List<DenyReason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static DenyReason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DenyReason._(super.value, super.name);
}

/// Why control ended.
class StopReason extends $pb.ProtobufEnum {
  static const StopReason STOP_REASON_UNSPECIFIED =
      StopReason._(0, _omitEnumNames ? '' : 'STOP_REASON_UNSPECIFIED');

  /// The controller is done, such as when its touchpad page closed.
  static const StopReason STOP_REASON_CONTROLLER_DONE =
      StopReason._(1, _omitEnumNames ? '' : 'STOP_REASON_CONTROLLER_DONE');

  /// Someone on the computer pressed Stop.
  static const StopReason STOP_REASON_STOPPED_ON_HOST =
      StopReason._(2, _omitEnumNames ? '' : 'STOP_REASON_STOPPED_ON_HOST');

  /// Nothing happened for a long time.
  static const StopReason STOP_REASON_IDLE =
      StopReason._(3, _omitEnumNames ? '' : 'STOP_REASON_IDLE');

  /// The computer's owner revoked this device, or turned remote input off.
  static const StopReason STOP_REASON_REVOKED =
      StopReason._(4, _omitEnumNames ? '' : 'STOP_REASON_REVOKED');

  /// Input arrived from a device that has no control right now.
  static const StopReason STOP_REASON_NOT_CONTROLLING =
      StopReason._(5, _omitEnumNames ? '' : 'STOP_REASON_NOT_CONTROLLING');

  /// The computer can no longer inject input, such as when its owner turned
  /// Accessibility access off.
  static const StopReason STOP_REASON_FAILED =
      StopReason._(6, _omitEnumNames ? '' : 'STOP_REASON_FAILED');

  static const $core.List<StopReason> values = <StopReason>[
    STOP_REASON_UNSPECIFIED,
    STOP_REASON_CONTROLLER_DONE,
    STOP_REASON_STOPPED_ON_HOST,
    STOP_REASON_IDLE,
    STOP_REASON_REVOKED,
    STOP_REASON_NOT_CONTROLLING,
    STOP_REASON_FAILED,
  ];

  static final $core.List<StopReason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static StopReason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const StopReason._(super.value, super.name);
}

/// A pointer button.
class MouseButton extends $pb.ProtobufEnum {
  static const MouseButton MOUSE_BUTTON_UNSPECIFIED =
      MouseButton._(0, _omitEnumNames ? '' : 'MOUSE_BUTTON_UNSPECIFIED');
  static const MouseButton MOUSE_BUTTON_LEFT =
      MouseButton._(1, _omitEnumNames ? '' : 'MOUSE_BUTTON_LEFT');
  static const MouseButton MOUSE_BUTTON_RIGHT =
      MouseButton._(2, _omitEnumNames ? '' : 'MOUSE_BUTTON_RIGHT');
  static const MouseButton MOUSE_BUTTON_MIDDLE =
      MouseButton._(3, _omitEnumNames ? '' : 'MOUSE_BUTTON_MIDDLE');

  static const $core.List<MouseButton> values = <MouseButton>[
    MOUSE_BUTTON_UNSPECIFIED,
    MOUSE_BUTTON_LEFT,
    MOUSE_BUTTON_RIGHT,
    MOUSE_BUTTON_MIDDLE,
  ];

  static final $core.List<MouseButton?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static MouseButton? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MouseButton._(super.value, super.name);
}

/// A key, by what it is rather than by any platform's code. Text goes as
/// `TextInput`; keys are for shortcuts and keys that type nothing.
class Key extends $pb.ProtobufEnum {
  static const Key KEY_UNSPECIFIED =
      Key._(0, _omitEnumNames ? '' : 'KEY_UNSPECIFIED');
  static const Key KEY_ENTER = Key._(1, _omitEnumNames ? '' : 'KEY_ENTER');
  static const Key KEY_BACKSPACE =
      Key._(2, _omitEnumNames ? '' : 'KEY_BACKSPACE');
  static const Key KEY_DELETE = Key._(3, _omitEnumNames ? '' : 'KEY_DELETE');
  static const Key KEY_TAB = Key._(4, _omitEnumNames ? '' : 'KEY_TAB');
  static const Key KEY_ESCAPE = Key._(5, _omitEnumNames ? '' : 'KEY_ESCAPE');
  static const Key KEY_SPACE = Key._(6, _omitEnumNames ? '' : 'KEY_SPACE');
  static const Key KEY_ARROW_LEFT =
      Key._(7, _omitEnumNames ? '' : 'KEY_ARROW_LEFT');
  static const Key KEY_ARROW_RIGHT =
      Key._(8, _omitEnumNames ? '' : 'KEY_ARROW_RIGHT');
  static const Key KEY_ARROW_UP =
      Key._(9, _omitEnumNames ? '' : 'KEY_ARROW_UP');
  static const Key KEY_ARROW_DOWN =
      Key._(10, _omitEnumNames ? '' : 'KEY_ARROW_DOWN');
  static const Key KEY_HOME = Key._(11, _omitEnumNames ? '' : 'KEY_HOME');
  static const Key KEY_END = Key._(12, _omitEnumNames ? '' : 'KEY_END');
  static const Key KEY_PAGE_UP = Key._(13, _omitEnumNames ? '' : 'KEY_PAGE_UP');
  static const Key KEY_PAGE_DOWN =
      Key._(14, _omitEnumNames ? '' : 'KEY_PAGE_DOWN');
  static const Key KEY_MEDIA_PLAY_PAUSE =
      Key._(20, _omitEnumNames ? '' : 'KEY_MEDIA_PLAY_PAUSE');
  static const Key KEY_MEDIA_NEXT =
      Key._(21, _omitEnumNames ? '' : 'KEY_MEDIA_NEXT');
  static const Key KEY_MEDIA_PREVIOUS =
      Key._(22, _omitEnumNames ? '' : 'KEY_MEDIA_PREVIOUS');
  static const Key KEY_VOLUME_UP =
      Key._(23, _omitEnumNames ? '' : 'KEY_VOLUME_UP');
  static const Key KEY_VOLUME_DOWN =
      Key._(24, _omitEnumNames ? '' : 'KEY_VOLUME_DOWN');
  static const Key KEY_VOLUME_MUTE =
      Key._(25, _omitEnumNames ? '' : 'KEY_VOLUME_MUTE');
  static const Key KEY_F1 = Key._(31, _omitEnumNames ? '' : 'KEY_F1');
  static const Key KEY_F2 = Key._(32, _omitEnumNames ? '' : 'KEY_F2');
  static const Key KEY_F3 = Key._(33, _omitEnumNames ? '' : 'KEY_F3');
  static const Key KEY_F4 = Key._(34, _omitEnumNames ? '' : 'KEY_F4');
  static const Key KEY_F5 = Key._(35, _omitEnumNames ? '' : 'KEY_F5');
  static const Key KEY_F6 = Key._(36, _omitEnumNames ? '' : 'KEY_F6');
  static const Key KEY_F7 = Key._(37, _omitEnumNames ? '' : 'KEY_F7');
  static const Key KEY_F8 = Key._(38, _omitEnumNames ? '' : 'KEY_F8');
  static const Key KEY_F9 = Key._(39, _omitEnumNames ? '' : 'KEY_F9');
  static const Key KEY_F10 = Key._(40, _omitEnumNames ? '' : 'KEY_F10');
  static const Key KEY_F11 = Key._(41, _omitEnumNames ? '' : 'KEY_F11');
  static const Key KEY_F12 = Key._(42, _omitEnumNames ? '' : 'KEY_F12');

  /// Letters and digits, for shortcuts such as Ctrl+C.
  static const Key KEY_A = Key._(65, _omitEnumNames ? '' : 'KEY_A');
  static const Key KEY_B = Key._(66, _omitEnumNames ? '' : 'KEY_B');
  static const Key KEY_C = Key._(67, _omitEnumNames ? '' : 'KEY_C');
  static const Key KEY_D = Key._(68, _omitEnumNames ? '' : 'KEY_D');
  static const Key KEY_E = Key._(69, _omitEnumNames ? '' : 'KEY_E');
  static const Key KEY_F = Key._(70, _omitEnumNames ? '' : 'KEY_F');
  static const Key KEY_G = Key._(71, _omitEnumNames ? '' : 'KEY_G');
  static const Key KEY_H = Key._(72, _omitEnumNames ? '' : 'KEY_H');
  static const Key KEY_I = Key._(73, _omitEnumNames ? '' : 'KEY_I');
  static const Key KEY_J = Key._(74, _omitEnumNames ? '' : 'KEY_J');
  static const Key KEY_K = Key._(75, _omitEnumNames ? '' : 'KEY_K');
  static const Key KEY_L = Key._(76, _omitEnumNames ? '' : 'KEY_L');
  static const Key KEY_M = Key._(77, _omitEnumNames ? '' : 'KEY_M');
  static const Key KEY_N = Key._(78, _omitEnumNames ? '' : 'KEY_N');
  static const Key KEY_O = Key._(79, _omitEnumNames ? '' : 'KEY_O');
  static const Key KEY_P = Key._(80, _omitEnumNames ? '' : 'KEY_P');
  static const Key KEY_Q = Key._(81, _omitEnumNames ? '' : 'KEY_Q');
  static const Key KEY_R = Key._(82, _omitEnumNames ? '' : 'KEY_R');
  static const Key KEY_S = Key._(83, _omitEnumNames ? '' : 'KEY_S');
  static const Key KEY_T = Key._(84, _omitEnumNames ? '' : 'KEY_T');
  static const Key KEY_U = Key._(85, _omitEnumNames ? '' : 'KEY_U');
  static const Key KEY_V = Key._(86, _omitEnumNames ? '' : 'KEY_V');
  static const Key KEY_W = Key._(87, _omitEnumNames ? '' : 'KEY_W');
  static const Key KEY_X = Key._(88, _omitEnumNames ? '' : 'KEY_X');
  static const Key KEY_Y = Key._(89, _omitEnumNames ? '' : 'KEY_Y');
  static const Key KEY_Z = Key._(90, _omitEnumNames ? '' : 'KEY_Z');
  static const Key KEY_DIGIT_0 =
      Key._(100, _omitEnumNames ? '' : 'KEY_DIGIT_0');
  static const Key KEY_DIGIT_1 =
      Key._(101, _omitEnumNames ? '' : 'KEY_DIGIT_1');
  static const Key KEY_DIGIT_2 =
      Key._(102, _omitEnumNames ? '' : 'KEY_DIGIT_2');
  static const Key KEY_DIGIT_3 =
      Key._(103, _omitEnumNames ? '' : 'KEY_DIGIT_3');
  static const Key KEY_DIGIT_4 =
      Key._(104, _omitEnumNames ? '' : 'KEY_DIGIT_4');
  static const Key KEY_DIGIT_5 =
      Key._(105, _omitEnumNames ? '' : 'KEY_DIGIT_5');
  static const Key KEY_DIGIT_6 =
      Key._(106, _omitEnumNames ? '' : 'KEY_DIGIT_6');
  static const Key KEY_DIGIT_7 =
      Key._(107, _omitEnumNames ? '' : 'KEY_DIGIT_7');
  static const Key KEY_DIGIT_8 =
      Key._(108, _omitEnumNames ? '' : 'KEY_DIGIT_8');
  static const Key KEY_DIGIT_9 =
      Key._(109, _omitEnumNames ? '' : 'KEY_DIGIT_9');

  /// Punctuation keys by where they sit on a US keyboard, for shortcuts
  /// such as Cmd+, or Ctrl+/. Typed punctuation still goes as text.
  static const Key KEY_MINUS = Key._(110, _omitEnumNames ? '' : 'KEY_MINUS');
  static const Key KEY_EQUAL = Key._(111, _omitEnumNames ? '' : 'KEY_EQUAL');
  static const Key KEY_BRACKET_LEFT =
      Key._(112, _omitEnumNames ? '' : 'KEY_BRACKET_LEFT');
  static const Key KEY_BRACKET_RIGHT =
      Key._(113, _omitEnumNames ? '' : 'KEY_BRACKET_RIGHT');
  static const Key KEY_BACKSLASH =
      Key._(114, _omitEnumNames ? '' : 'KEY_BACKSLASH');
  static const Key KEY_SEMICOLON =
      Key._(115, _omitEnumNames ? '' : 'KEY_SEMICOLON');
  static const Key KEY_QUOTE = Key._(116, _omitEnumNames ? '' : 'KEY_QUOTE');
  static const Key KEY_BACKQUOTE =
      Key._(117, _omitEnumNames ? '' : 'KEY_BACKQUOTE');
  static const Key KEY_COMMA = Key._(118, _omitEnumNames ? '' : 'KEY_COMMA');
  static const Key KEY_PERIOD = Key._(119, _omitEnumNames ? '' : 'KEY_PERIOD');
  static const Key KEY_SLASH = Key._(120, _omitEnumNames ? '' : 'KEY_SLASH');

  static const $core.List<Key> values = <Key>[
    KEY_UNSPECIFIED,
    KEY_ENTER,
    KEY_BACKSPACE,
    KEY_DELETE,
    KEY_TAB,
    KEY_ESCAPE,
    KEY_SPACE,
    KEY_ARROW_LEFT,
    KEY_ARROW_RIGHT,
    KEY_ARROW_UP,
    KEY_ARROW_DOWN,
    KEY_HOME,
    KEY_END,
    KEY_PAGE_UP,
    KEY_PAGE_DOWN,
    KEY_MEDIA_PLAY_PAUSE,
    KEY_MEDIA_NEXT,
    KEY_MEDIA_PREVIOUS,
    KEY_VOLUME_UP,
    KEY_VOLUME_DOWN,
    KEY_VOLUME_MUTE,
    KEY_F1,
    KEY_F2,
    KEY_F3,
    KEY_F4,
    KEY_F5,
    KEY_F6,
    KEY_F7,
    KEY_F8,
    KEY_F9,
    KEY_F10,
    KEY_F11,
    KEY_F12,
    KEY_A,
    KEY_B,
    KEY_C,
    KEY_D,
    KEY_E,
    KEY_F,
    KEY_G,
    KEY_H,
    KEY_I,
    KEY_J,
    KEY_K,
    KEY_L,
    KEY_M,
    KEY_N,
    KEY_O,
    KEY_P,
    KEY_Q,
    KEY_R,
    KEY_S,
    KEY_T,
    KEY_U,
    KEY_V,
    KEY_W,
    KEY_X,
    KEY_Y,
    KEY_Z,
    KEY_DIGIT_0,
    KEY_DIGIT_1,
    KEY_DIGIT_2,
    KEY_DIGIT_3,
    KEY_DIGIT_4,
    KEY_DIGIT_5,
    KEY_DIGIT_6,
    KEY_DIGIT_7,
    KEY_DIGIT_8,
    KEY_DIGIT_9,
    KEY_MINUS,
    KEY_EQUAL,
    KEY_BRACKET_LEFT,
    KEY_BRACKET_RIGHT,
    KEY_BACKSLASH,
    KEY_SEMICOLON,
    KEY_QUOTE,
    KEY_BACKQUOTE,
    KEY_COMMA,
    KEY_PERIOD,
    KEY_SLASH,
  ];

  static final $core.Map<$core.int, Key> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static Key? valueOf($core.int value) => _byValue[value];

  const Key._(super.value, super.name);
}

/// A key held with another key. `MODIFIER_META` is Command on macOS, the
/// Windows key on Windows and Super on Linux.
class Modifier extends $pb.ProtobufEnum {
  static const Modifier MODIFIER_UNSPECIFIED =
      Modifier._(0, _omitEnumNames ? '' : 'MODIFIER_UNSPECIFIED');
  static const Modifier MODIFIER_SHIFT =
      Modifier._(1, _omitEnumNames ? '' : 'MODIFIER_SHIFT');
  static const Modifier MODIFIER_CONTROL =
      Modifier._(2, _omitEnumNames ? '' : 'MODIFIER_CONTROL');
  static const Modifier MODIFIER_ALT =
      Modifier._(3, _omitEnumNames ? '' : 'MODIFIER_ALT');
  static const Modifier MODIFIER_META =
      Modifier._(4, _omitEnumNames ? '' : 'MODIFIER_META');

  static const $core.List<Modifier> values = <Modifier>[
    MODIFIER_UNSPECIFIED,
    MODIFIER_SHIFT,
    MODIFIER_CONTROL,
    MODIFIER_ALT,
    MODIFIER_META,
  ];

  static final $core.List<Modifier?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static Modifier? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Modifier._(super.value, super.name);
}

/// What came of a `LockRequest`.
class LockResult extends $pb.ProtobufEnum {
  static const LockResult LOCK_RESULT_UNSPECIFIED =
      LockResult._(0, _omitEnumNames ? '' : 'LOCK_RESULT_UNSPECIFIED');

  /// The screen is locked.
  static const LockResult LOCK_RESULT_LOCKED =
      LockResult._(1, _omitEnumNames ? '' : 'LOCK_RESULT_LOCKED');

  /// Its owner said no.
  static const LockResult LOCK_RESULT_DENIED =
      LockResult._(2, _omitEnumNames ? '' : 'LOCK_RESULT_DENIED');

  /// Nobody answered on the computer in time.
  static const LockResult LOCK_RESULT_TIMEOUT =
      LockResult._(3, _omitEnumNames ? '' : 'LOCK_RESULT_TIMEOUT');

  /// The computer is asking its owner about another device right now.
  static const LockResult LOCK_RESULT_BUSY =
      LockResult._(4, _omitEnumNames ? '' : 'LOCK_RESULT_BUSY');

  /// Its owner turned remote input off.
  static const LockResult LOCK_RESULT_TURNED_OFF =
      LockResult._(5, _omitEnumNames ? '' : 'LOCK_RESULT_TURNED_OFF');

  /// The computer tried and couldn't lock.
  static const LockResult LOCK_RESULT_FAILED =
      LockResult._(6, _omitEnumNames ? '' : 'LOCK_RESULT_FAILED');

  static const $core.List<LockResult> values = <LockResult>[
    LOCK_RESULT_UNSPECIFIED,
    LOCK_RESULT_LOCKED,
    LOCK_RESULT_DENIED,
    LOCK_RESULT_TIMEOUT,
    LOCK_RESULT_BUSY,
    LOCK_RESULT_TURNED_OFF,
    LOCK_RESULT_FAILED,
  ];

  static final $core.List<LockResult?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static LockResult? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LockResult._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
