// This is a generated file - do not edit.
//
// Generated from ferret/drop/v1/drop.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class DeclineReason extends $pb.ProtobufEnum {
  static const DeclineReason DECLINE_REASON_UNSPECIFIED =
      DeclineReason._(0, _omitEnumNames ? '' : 'DECLINE_REASON_UNSPECIFIED');

  /// Someone on the receiving device said no.
  static const DeclineReason DECLINE_REASON_DECLINED =
      DeclineReason._(1, _omitEnumNames ? '' : 'DECLINE_REASON_DECLINED');

  /// Nobody answered in time.
  static const DeclineReason DECLINE_REASON_TIMEOUT =
      DeclineReason._(2, _omitEnumNames ? '' : 'DECLINE_REASON_TIMEOUT');

  /// The receiver can't write to its receive folder.
  static const DeclineReason DECLINE_REASON_STORAGE =
      DeclineReason._(3, _omitEnumNames ? '' : 'DECLINE_REASON_STORAGE');

  /// The receiver doesn't know this transfer any more and can't resume it.
  static const DeclineReason DECLINE_REASON_UNKNOWN_TRANSFER = DeclineReason._(
      4, _omitEnumNames ? '' : 'DECLINE_REASON_UNKNOWN_TRANSFER');

  /// The offer is malformed, such as a file without a name.
  static const DeclineReason DECLINE_REASON_INVALID =
      DeclineReason._(5, _omitEnumNames ? '' : 'DECLINE_REASON_INVALID');

  static const $core.List<DeclineReason> values = <DeclineReason>[
    DECLINE_REASON_UNSPECIFIED,
    DECLINE_REASON_DECLINED,
    DECLINE_REASON_TIMEOUT,
    DECLINE_REASON_STORAGE,
    DECLINE_REASON_UNKNOWN_TRANSFER,
    DECLINE_REASON_INVALID,
  ];

  static final $core.List<DeclineReason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static DeclineReason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DeclineReason._(super.value, super.name);
}

class FailureReason extends $pb.ProtobufEnum {
  static const FailureReason FAILURE_REASON_UNSPECIFIED =
      FailureReason._(0, _omitEnumNames ? '' : 'FAILURE_REASON_UNSPECIFIED');

  /// Someone cancelled it.
  static const FailureReason FAILURE_REASON_CANCELLED =
      FailureReason._(1, _omitEnumNames ? '' : 'FAILURE_REASON_CANCELLED');

  /// The received data didn't match the sender's SHA-256.
  static const FailureReason FAILURE_REASON_CHECKSUM =
      FailureReason._(2, _omitEnumNames ? '' : 'FAILURE_REASON_CHECKSUM');

  /// Reading or writing a file failed, such as a full disk.
  static const FailureReason FAILURE_REASON_STORAGE =
      FailureReason._(3, _omitEnumNames ? '' : 'FAILURE_REASON_STORAGE');

  /// The sender's file changed or disappeared during the transfer.
  static const FailureReason FAILURE_REASON_SOURCE_CHANGED =
      FailureReason._(4, _omitEnumNames ? '' : 'FAILURE_REASON_SOURCE_CHANGED');

  /// A chunk didn't match what the receiver expected.
  static const FailureReason FAILURE_REASON_PROTOCOL =
      FailureReason._(5, _omitEnumNames ? '' : 'FAILURE_REASON_PROTOCOL');

  /// The sender no longer has this transfer, so it can't be resumed.
  static const FailureReason FAILURE_REASON_UNKNOWN_TRANSFER = FailureReason._(
      6, _omitEnumNames ? '' : 'FAILURE_REASON_UNKNOWN_TRANSFER');

  static const $core.List<FailureReason> values = <FailureReason>[
    FAILURE_REASON_UNSPECIFIED,
    FAILURE_REASON_CANCELLED,
    FAILURE_REASON_CHECKSUM,
    FAILURE_REASON_STORAGE,
    FAILURE_REASON_SOURCE_CHANGED,
    FAILURE_REASON_PROTOCOL,
    FAILURE_REASON_UNKNOWN_TRANSFER,
  ];

  static final $core.List<FailureReason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static FailureReason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FailureReason._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
