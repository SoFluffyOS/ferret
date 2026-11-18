// This is a generated file - do not edit.
//
// Generated from ferret/find/v1/find.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Whether a device rings.
class RingState extends $pb.ProtobufEnum {
  static const RingState RING_STATE_UNSPECIFIED =
      RingState._(0, _omitEnumNames ? '' : 'RING_STATE_UNSPECIFIED');
  static const RingState RING_STATE_RINGING =
      RingState._(1, _omitEnumNames ? '' : 'RING_STATE_RINGING');
  static const RingState RING_STATE_STOPPED =
      RingState._(2, _omitEnumNames ? '' : 'RING_STATE_STOPPED');

  static const $core.List<RingState> values = <RingState>[
    RING_STATE_UNSPECIFIED,
    RING_STATE_RINGING,
    RING_STATE_STOPPED,
  ];

  static final $core.List<RingState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static RingState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RingState._(super.value, super.name);
}

/// Why a ring stopped.
class StopReason extends $pb.ProtobufEnum {
  static const StopReason STOP_REASON_UNSPECIFIED =
      StopReason._(0, _omitEnumNames ? '' : 'STOP_REASON_UNSPECIFIED');

  /// Someone tapped "Found it" or pressed a volume key on the ringing device.
  static const StopReason STOP_REASON_FOUND =
      StopReason._(1, _omitEnumNames ? '' : 'STOP_REASON_FOUND');

  /// The ring ran for its whole duration.
  static const StopReason STOP_REASON_TIMEOUT =
      StopReason._(2, _omitEnumNames ? '' : 'STOP_REASON_TIMEOUT');

  /// A `StopRingRequest` arrived.
  static const StopReason STOP_REASON_STOPPED_REMOTELY =
      StopReason._(3, _omitEnumNames ? '' : 'STOP_REASON_STOPPED_REMOTELY');

  /// The device could not play a sound at all.
  static const StopReason STOP_REASON_FAILED =
      StopReason._(4, _omitEnumNames ? '' : 'STOP_REASON_FAILED');

  static const $core.List<StopReason> values = <StopReason>[
    STOP_REASON_UNSPECIFIED,
    STOP_REASON_FOUND,
    STOP_REASON_TIMEOUT,
    STOP_REASON_STOPPED_REMOTELY,
    STOP_REASON_FAILED,
  ];

  static final $core.List<StopReason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static StopReason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const StopReason._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
