// This is a generated file - do not edit.
//
// Generated from ferret/mirroring/v1/control.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Where control stands on the source.
class ControlStatus extends $pb.ProtobufEnum {
  static const ControlStatus CONTROL_STATUS_UNSPECIFIED =
      ControlStatus._(0, _omitEnumNames ? '' : 'CONTROL_STATUS_UNSPECIFIED');

  /// The source can be controlled. A `ControlAsk` makes it ask its owner.
  static const ControlStatus CONTROL_STATUS_CAN_ASK =
      ControlStatus._(1, _omitEnumNames ? '' : 'CONTROL_STATUS_CAN_ASK');

  /// The owner is being asked, for at most `ControlState.timeout_seconds`.
  static const ControlStatus CONTROL_STATUS_ASKING =
      ControlStatus._(2, _omitEnumNames ? '' : 'CONTROL_STATUS_ASKING');

  /// The viewer may send `ControlInput`.
  static const ControlStatus CONTROL_STATUS_ALLOWED =
      ControlStatus._(3, _omitEnumNames ? '' : 'CONTROL_STATUS_ALLOWED');

  /// The owner said no. The viewer may ask again later.
  static const ControlStatus CONTROL_STATUS_DENIED =
      ControlStatus._(4, _omitEnumNames ? '' : 'CONTROL_STATUS_DENIED');

  /// The owner didn't answer in time.
  static const ControlStatus CONTROL_STATUS_TIMED_OUT =
      ControlStatus._(5, _omitEnumNames ? '' : 'CONTROL_STATUS_TIMED_OUT');

  /// Nothing on the source can inject input until its owner sets it up
  /// there: the accessibility service is off and there are no power-ups.
  static const ControlStatus CONTROL_STATUS_NEEDS_SETUP =
      ControlStatus._(6, _omitEnumNames ? '' : 'CONTROL_STATUS_NEEDS_SETUP');

  /// The source can't be controlled at all, such as an iPhone.
  static const ControlStatus CONTROL_STATUS_UNSUPPORTED =
      ControlStatus._(7, _omitEnumNames ? '' : 'CONTROL_STATUS_UNSUPPORTED');

  /// The owner stopped control on the source. The viewer may ask again.
  static const ControlStatus CONTROL_STATUS_STOPPED =
      ControlStatus._(8, _omitEnumNames ? '' : 'CONTROL_STATUS_STOPPED');

  static const $core.List<ControlStatus> values = <ControlStatus>[
    CONTROL_STATUS_UNSPECIFIED,
    CONTROL_STATUS_CAN_ASK,
    CONTROL_STATUS_ASKING,
    CONTROL_STATUS_ALLOWED,
    CONTROL_STATUS_DENIED,
    CONTROL_STATUS_TIMED_OUT,
    CONTROL_STATUS_NEEDS_SETUP,
    CONTROL_STATUS_UNSUPPORTED,
    CONTROL_STATUS_STOPPED,
  ];

  static final $core.List<ControlStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static ControlStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ControlStatus._(super.value, super.name);
}

/// What the source can take while control is allowed.
class ControlKind extends $pb.ProtobufEnum {
  static const ControlKind CONTROL_KIND_UNSPECIFIED =
      ControlKind._(0, _omitEnumNames ? '' : 'CONTROL_KIND_UNSPECIFIED');

  /// Taps, drags and scrolling: `PointerInput`.
  static const ControlKind CONTROL_KIND_POINTER =
      ControlKind._(1, _omitEnumNames ? '' : 'CONTROL_KIND_POINTER');

  /// Every `ferret.remote_input.v1.Key`, with modifiers.
  static const ControlKind CONTROL_KIND_KEYS =
      ControlKind._(2, _omitEnumNames ? '' : 'CONTROL_KIND_KEYS');

  /// Typed text.
  static const ControlKind CONTROL_KIND_TEXT =
      ControlKind._(3, _omitEnumNames ? '' : 'CONTROL_KIND_TEXT');

  /// The device's own buttons: `ButtonPress`.
  static const ControlKind CONTROL_KIND_BUTTONS =
      ControlKind._(4, _omitEnumNames ? '' : 'CONTROL_KIND_BUTTONS');

  /// A computer's mouse: `TOUCH_PHASE_HOVER` moves the pointer with
  /// nothing pressed, and `PointerInput.button` picks the button a press
  /// and its release are for. Sent by a computer's extra display.
  static const ControlKind CONTROL_KIND_MOUSE =
      ControlKind._(5, _omitEnumNames ? '' : 'CONTROL_KIND_MOUSE');

  static const $core.List<ControlKind> values = <ControlKind>[
    CONTROL_KIND_UNSPECIFIED,
    CONTROL_KIND_POINTER,
    CONTROL_KIND_KEYS,
    CONTROL_KIND_TEXT,
    CONTROL_KIND_BUTTONS,
    CONTROL_KIND_MOUSE,
  ];

  static final $core.List<ControlKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static ControlKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ControlKind._(super.value, super.name);
}

/// What a pointer does.
class TouchPhase extends $pb.ProtobufEnum {
  static const TouchPhase TOUCH_PHASE_UNSPECIFIED =
      TouchPhase._(0, _omitEnumNames ? '' : 'TOUCH_PHASE_UNSPECIFIED');

  /// A finger goes down at (`x`, `y`).
  static const TouchPhase TOUCH_PHASE_DOWN =
      TouchPhase._(1, _omitEnumNames ? '' : 'TOUCH_PHASE_DOWN');

  /// The finger that is down moves to (`x`, `y`).
  static const TouchPhase TOUCH_PHASE_MOVE =
      TouchPhase._(2, _omitEnumNames ? '' : 'TOUCH_PHASE_MOVE');

  /// The finger lifts at (`x`, `y`).
  static const TouchPhase TOUCH_PHASE_UP =
      TouchPhase._(3, _omitEnumNames ? '' : 'TOUCH_PHASE_UP');

  /// The touch is abandoned: nothing under it is activated.
  static const TouchPhase TOUCH_PHASE_CANCEL =
      TouchPhase._(4, _omitEnumNames ? '' : 'TOUCH_PHASE_CANCEL');

  /// The content under (`x`, `y`) scrolls by `scroll_x` and `scroll_y`.
  static const TouchPhase TOUCH_PHASE_SCROLL =
      TouchPhase._(5, _omitEnumNames ? '' : 'TOUCH_PHASE_SCROLL');

  /// The pointer moves to (`x`, `y`) with nothing pressed. Only for a
  /// source that takes `CONTROL_KIND_MOUSE`.
  static const TouchPhase TOUCH_PHASE_HOVER =
      TouchPhase._(6, _omitEnumNames ? '' : 'TOUCH_PHASE_HOVER');

  static const $core.List<TouchPhase> values = <TouchPhase>[
    TOUCH_PHASE_UNSPECIFIED,
    TOUCH_PHASE_DOWN,
    TOUCH_PHASE_MOVE,
    TOUCH_PHASE_UP,
    TOUCH_PHASE_CANCEL,
    TOUCH_PHASE_SCROLL,
    TOUCH_PHASE_HOVER,
  ];

  static final $core.List<TouchPhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static TouchPhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TouchPhase._(super.value, super.name);
}

/// A button of the device itself.
class ControlButton extends $pb.ProtobufEnum {
  static const ControlButton CONTROL_BUTTON_UNSPECIFIED =
      ControlButton._(0, _omitEnumNames ? '' : 'CONTROL_BUTTON_UNSPECIFIED');
  static const ControlButton CONTROL_BUTTON_BACK =
      ControlButton._(1, _omitEnumNames ? '' : 'CONTROL_BUTTON_BACK');
  static const ControlButton CONTROL_BUTTON_HOME =
      ControlButton._(2, _omitEnumNames ? '' : 'CONTROL_BUTTON_HOME');
  static const ControlButton CONTROL_BUTTON_RECENTS =
      ControlButton._(3, _omitEnumNames ? '' : 'CONTROL_BUTTON_RECENTS');

  /// Opens the notification shade.
  static const ControlButton CONTROL_BUTTON_NOTIFICATIONS =
      ControlButton._(4, _omitEnumNames ? '' : 'CONTROL_BUTTON_NOTIFICATIONS');

  /// Turns the screen off; with power-ups it also turns it back on.
  static const ControlButton CONTROL_BUTTON_POWER =
      ControlButton._(5, _omitEnumNames ? '' : 'CONTROL_BUTTON_POWER');
  static const ControlButton CONTROL_BUTTON_VOLUME_UP =
      ControlButton._(6, _omitEnumNames ? '' : 'CONTROL_BUTTON_VOLUME_UP');
  static const ControlButton CONTROL_BUTTON_VOLUME_DOWN =
      ControlButton._(7, _omitEnumNames ? '' : 'CONTROL_BUTTON_VOLUME_DOWN');

  static const $core.List<ControlButton> values = <ControlButton>[
    CONTROL_BUTTON_UNSPECIFIED,
    CONTROL_BUTTON_BACK,
    CONTROL_BUTTON_HOME,
    CONTROL_BUTTON_RECENTS,
    CONTROL_BUTTON_NOTIFICATIONS,
    CONTROL_BUTTON_POWER,
    CONTROL_BUTTON_VOLUME_UP,
    CONTROL_BUTTON_VOLUME_DOWN,
  ];

  static final $core.List<ControlButton?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static ControlButton? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ControlButton._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
