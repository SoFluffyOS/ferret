// This is a generated file - do not edit.
//
// Generated from ferret/v1/session.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class GoodbyeReason extends $pb.ProtobufEnum {
  static const GoodbyeReason GOODBYE_REASON_UNSPECIFIED =
      GoodbyeReason._(0, _omitEnumNames ? '' : 'GOODBYE_REASON_UNSPECIFIED');
  static const GoodbyeReason GOODBYE_REASON_SHUTDOWN =
      GoodbyeReason._(1, _omitEnumNames ? '' : 'GOODBYE_REASON_SHUTDOWN');
  static const GoodbyeReason GOODBYE_REASON_UNPAIRED =
      GoodbyeReason._(2, _omitEnumNames ? '' : 'GOODBYE_REASON_UNPAIRED');
  static const GoodbyeReason GOODBYE_REASON_DUPLICATE =
      GoodbyeReason._(3, _omitEnumNames ? '' : 'GOODBYE_REASON_DUPLICATE');

  static const $core.List<GoodbyeReason> values = <GoodbyeReason>[
    GOODBYE_REASON_UNSPECIFIED,
    GOODBYE_REASON_SHUTDOWN,
    GOODBYE_REASON_UNPAIRED,
    GOODBYE_REASON_DUPLICATE,
  ];

  static final $core.List<GoodbyeReason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static GoodbyeReason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GoodbyeReason._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
