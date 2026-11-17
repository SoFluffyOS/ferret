// This is a generated file - do not edit.
//
// Generated from ferret/v1/envelope.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ErrorCode extends $pb.ProtobufEnum {
  static const ErrorCode ERROR_CODE_UNSPECIFIED =
      ErrorCode._(0, _omitEnumNames ? '' : 'ERROR_CODE_UNSPECIFIED');
  static const ErrorCode ERROR_CODE_UNSUPPORTED =
      ErrorCode._(1, _omitEnumNames ? '' : 'ERROR_CODE_UNSUPPORTED');
  static const ErrorCode ERROR_CODE_DENIED =
      ErrorCode._(2, _omitEnumNames ? '' : 'ERROR_CODE_DENIED');
  static const ErrorCode ERROR_CODE_INVALID =
      ErrorCode._(3, _omitEnumNames ? '' : 'ERROR_CODE_INVALID');
  static const ErrorCode ERROR_CODE_INTERNAL =
      ErrorCode._(4, _omitEnumNames ? '' : 'ERROR_CODE_INTERNAL');
  static const ErrorCode ERROR_CODE_TIMEOUT =
      ErrorCode._(5, _omitEnumNames ? '' : 'ERROR_CODE_TIMEOUT');
  static const ErrorCode ERROR_CODE_CANCELLED =
      ErrorCode._(6, _omitEnumNames ? '' : 'ERROR_CODE_CANCELLED');

  static const $core.List<ErrorCode> values = <ErrorCode>[
    ERROR_CODE_UNSPECIFIED,
    ERROR_CODE_UNSUPPORTED,
    ERROR_CODE_DENIED,
    ERROR_CODE_INVALID,
    ERROR_CODE_INTERNAL,
    ERROR_CODE_TIMEOUT,
    ERROR_CODE_CANCELLED,
  ];

  static final $core.List<ErrorCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static ErrorCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ErrorCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
