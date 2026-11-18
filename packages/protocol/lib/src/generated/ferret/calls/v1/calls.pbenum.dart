// This is a generated file - do not edit.
//
// Generated from ferret/calls/v1/calls.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Who started a call.
class CallDirection extends $pb.ProtobufEnum {
  static const CallDirection CALL_DIRECTION_UNSPECIFIED =
      CallDirection._(0, _omitEnumNames ? '' : 'CALL_DIRECTION_UNSPECIFIED');

  /// Someone is calling the phone.
  static const CallDirection CALL_DIRECTION_INCOMING =
      CallDirection._(1, _omitEnumNames ? '' : 'CALL_DIRECTION_INCOMING');

  /// The phone is calling someone.
  static const CallDirection CALL_DIRECTION_OUTGOING =
      CallDirection._(2, _omitEnumNames ? '' : 'CALL_DIRECTION_OUTGOING');

  static const $core.List<CallDirection> values = <CallDirection>[
    CALL_DIRECTION_UNSPECIFIED,
    CALL_DIRECTION_INCOMING,
    CALL_DIRECTION_OUTGOING,
  ];

  static final $core.List<CallDirection?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static CallDirection? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CallDirection._(super.value, super.name);
}

/// Where a call is in its life.
class CallState extends $pb.ProtobufEnum {
  static const CallState CALL_STATE_UNSPECIFIED =
      CallState._(0, _omitEnumNames ? '' : 'CALL_STATE_UNSPECIFIED');

  /// An incoming call nobody answered yet.
  static const CallState CALL_STATE_RINGING =
      CallState._(1, _omitEnumNames ? '' : 'CALL_STATE_RINGING');

  /// An outgoing call. Phones that can't tell when the other side picks up
  /// stay in this state until the call ends.
  static const CallState CALL_STATE_DIALING =
      CallState._(2, _omitEnumNames ? '' : 'CALL_STATE_DIALING');
  static const CallState CALL_STATE_ACTIVE =
      CallState._(3, _omitEnumNames ? '' : 'CALL_STATE_ACTIVE');
  static const CallState CALL_STATE_HELD =
      CallState._(4, _omitEnumNames ? '' : 'CALL_STATE_HELD');

  /// The call is over. The last update for its id.
  static const CallState CALL_STATE_ENDED =
      CallState._(5, _omitEnumNames ? '' : 'CALL_STATE_ENDED');

  static const $core.List<CallState> values = <CallState>[
    CALL_STATE_UNSPECIFIED,
    CALL_STATE_RINGING,
    CALL_STATE_DIALING,
    CALL_STATE_ACTIVE,
    CALL_STATE_HELD,
    CALL_STATE_ENDED,
  ];

  static final $core.List<CallState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static CallState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CallState._(super.value, super.name);
}

/// How a call that rang ended, when the phone knows.
class CallOutcome extends $pb.ProtobufEnum {
  static const CallOutcome CALL_OUTCOME_UNSPECIFIED =
      CallOutcome._(0, _omitEnumNames ? '' : 'CALL_OUTCOME_UNSPECIFIED');
  static const CallOutcome CALL_OUTCOME_ANSWERED =
      CallOutcome._(1, _omitEnumNames ? '' : 'CALL_OUTCOME_ANSWERED');

  /// It rang out, or the caller gave up.
  static const CallOutcome CALL_OUTCOME_MISSED =
      CallOutcome._(2, _omitEnumNames ? '' : 'CALL_OUTCOME_MISSED');

  /// Someone declined it through Ferret.
  static const CallOutcome CALL_OUTCOME_DECLINED =
      CallOutcome._(3, _omitEnumNames ? '' : 'CALL_OUTCOME_DECLINED');

  static const $core.List<CallOutcome> values = <CallOutcome>[
    CALL_OUTCOME_UNSPECIFIED,
    CALL_OUTCOME_ANSWERED,
    CALL_OUTCOME_MISSED,
    CALL_OUTCOME_DECLINED,
  ];

  static final $core.List<CallOutcome?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static CallOutcome? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CallOutcome._(super.value, super.name);
}

/// What a computer asks the phone to do with a call.
class CallAction extends $pb.ProtobufEnum {
  static const CallAction CALL_ACTION_UNSPECIFIED =
      CallAction._(0, _omitEnumNames ? '' : 'CALL_ACTION_UNSPECIFIED');

  /// Pick up the ringing call. Audio stays on the phone.
  static const CallAction CALL_ACTION_ANSWER =
      CallAction._(1, _omitEnumNames ? '' : 'CALL_ACTION_ANSWER');

  /// Decline the ringing call, or hang up the ongoing one.
  static const CallAction CALL_ACTION_END =
      CallAction._(2, _omitEnumNames ? '' : 'CALL_ACTION_END');

  /// Stop the ringtone without declining.
  static const CallAction CALL_ACTION_SILENCE =
      CallAction._(3, _omitEnumNames ? '' : 'CALL_ACTION_SILENCE');

  /// Call `number`.
  static const CallAction CALL_ACTION_DIAL =
      CallAction._(4, _omitEnumNames ? '' : 'CALL_ACTION_DIAL');

  static const $core.List<CallAction> values = <CallAction>[
    CALL_ACTION_UNSPECIFIED,
    CALL_ACTION_ANSWER,
    CALL_ACTION_END,
    CALL_ACTION_SILENCE,
    CALL_ACTION_DIAL,
  ];

  static final $core.List<CallAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static CallAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CallAction._(super.value, super.name);
}

class CallCommandStatus extends $pb.ProtobufEnum {
  static const CallCommandStatus CALL_COMMAND_STATUS_UNSPECIFIED =
      CallCommandStatus._(
          0, _omitEnumNames ? '' : 'CALL_COMMAND_STATUS_UNSPECIFIED');
  static const CallCommandStatus CALL_COMMAND_STATUS_OK =
      CallCommandStatus._(1, _omitEnumNames ? '' : 'CALL_COMMAND_STATUS_OK');

  /// The call is gone, or nothing is ringing.
  static const CallCommandStatus CALL_COMMAND_STATUS_NO_CALL =
      CallCommandStatus._(
          2, _omitEnumNames ? '' : 'CALL_COMMAND_STATUS_NO_CALL');

  /// Calls are turned off on the phone.
  static const CallCommandStatus CALL_COMMAND_STATUS_DISABLED =
      CallCommandStatus._(
          3, _omitEnumNames ? '' : 'CALL_COMMAND_STATUS_DISABLED');

  /// The phone's owner did not give Ferret the permission this needs.
  static const CallCommandStatus CALL_COMMAND_STATUS_PERMISSION_MISSING =
      CallCommandStatus._(
          4, _omitEnumNames ? '' : 'CALL_COMMAND_STATUS_PERMISSION_MISSING');

  /// This phone's system version can't do it.
  static const CallCommandStatus CALL_COMMAND_STATUS_UNSUPPORTED =
      CallCommandStatus._(
          5, _omitEnumNames ? '' : 'CALL_COMMAND_STATUS_UNSUPPORTED');

  /// The number is empty or has characters a phone can't dial.
  static const CallCommandStatus CALL_COMMAND_STATUS_INVALID_NUMBER =
      CallCommandStatus._(
          6, _omitEnumNames ? '' : 'CALL_COMMAND_STATUS_INVALID_NUMBER');
  static const CallCommandStatus CALL_COMMAND_STATUS_FAILED =
      CallCommandStatus._(
          7, _omitEnumNames ? '' : 'CALL_COMMAND_STATUS_FAILED');

  static const $core.List<CallCommandStatus> values = <CallCommandStatus>[
    CALL_COMMAND_STATUS_UNSPECIFIED,
    CALL_COMMAND_STATUS_OK,
    CALL_COMMAND_STATUS_NO_CALL,
    CALL_COMMAND_STATUS_DISABLED,
    CALL_COMMAND_STATUS_PERMISSION_MISSING,
    CALL_COMMAND_STATUS_UNSUPPORTED,
    CALL_COMMAND_STATUS_INVALID_NUMBER,
    CALL_COMMAND_STATUS_FAILED,
  ];

  static final $core.List<CallCommandStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static CallCommandStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CallCommandStatus._(super.value, super.name);
}

/// What a past call was.
class CallLogType extends $pb.ProtobufEnum {
  static const CallLogType CALL_LOG_TYPE_UNSPECIFIED =
      CallLogType._(0, _omitEnumNames ? '' : 'CALL_LOG_TYPE_UNSPECIFIED');
  static const CallLogType CALL_LOG_TYPE_INCOMING =
      CallLogType._(1, _omitEnumNames ? '' : 'CALL_LOG_TYPE_INCOMING');
  static const CallLogType CALL_LOG_TYPE_OUTGOING =
      CallLogType._(2, _omitEnumNames ? '' : 'CALL_LOG_TYPE_OUTGOING');
  static const CallLogType CALL_LOG_TYPE_MISSED =
      CallLogType._(3, _omitEnumNames ? '' : 'CALL_LOG_TYPE_MISSED');

  /// The phone's owner declined it.
  static const CallLogType CALL_LOG_TYPE_REJECTED =
      CallLogType._(4, _omitEnumNames ? '' : 'CALL_LOG_TYPE_REJECTED');

  static const $core.List<CallLogType> values = <CallLogType>[
    CALL_LOG_TYPE_UNSPECIFIED,
    CALL_LOG_TYPE_INCOMING,
    CALL_LOG_TYPE_OUTGOING,
    CALL_LOG_TYPE_MISSED,
    CALL_LOG_TYPE_REJECTED,
  ];

  static final $core.List<CallLogType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static CallLogType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CallLogType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
