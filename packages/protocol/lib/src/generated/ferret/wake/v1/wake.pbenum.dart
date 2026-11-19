// This is a generated file - do not edit.
//
// Generated from ferret/wake/v1/wake.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class WakeResult extends $pb.ProtobufEnum {
  static const WakeResult WAKE_RESULT_UNSPECIFIED =
      WakeResult._(0, _omitEnumNames ? '' : 'WAKE_RESULT_UNSPECIFIED');

  /// The magic packet went out. Whether the device wakes shows when it
  /// connects.
  static const WakeResult WAKE_RESULT_SENT =
      WakeResult._(1, _omitEnumNames ? '' : 'WAKE_RESULT_SENT');

  /// The receiver isn't paired with that device, so it won't wake it.
  static const WakeResult WAKE_RESULT_NOT_PAIRED =
      WakeResult._(2, _omitEnumNames ? '' : 'WAKE_RESULT_NOT_PAIRED');

  /// Its owner turned off waking devices for others on the receiver.
  static const WakeResult WAKE_RESULT_RELAY_OFF =
      WakeResult._(3, _omitEnumNames ? '' : 'WAKE_RESULT_RELAY_OFF');

  /// Neither side knows the device's network card.
  static const WakeResult WAKE_RESULT_NO_INFO =
      WakeResult._(4, _omitEnumNames ? '' : 'WAKE_RESULT_NO_INFO');

  /// Sending failed, such as with no network.
  static const WakeResult WAKE_RESULT_FAILED =
      WakeResult._(5, _omitEnumNames ? '' : 'WAKE_RESULT_FAILED');

  static const $core.List<WakeResult> values = <WakeResult>[
    WAKE_RESULT_UNSPECIFIED,
    WAKE_RESULT_SENT,
    WAKE_RESULT_NOT_PAIRED,
    WAKE_RESULT_RELAY_OFF,
    WAKE_RESULT_NO_INFO,
    WAKE_RESULT_FAILED,
  ];

  static final $core.List<WakeResult?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static WakeResult? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const WakeResult._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
