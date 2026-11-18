// This is a generated file - do not edit.
//
// Generated from ferret/v1/pairing.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PairingResult extends $pb.ProtobufEnum {
  static const PairingResult PAIRING_RESULT_UNSPECIFIED =
      PairingResult._(0, _omitEnumNames ? '' : 'PAIRING_RESULT_UNSPECIFIED');
  static const PairingResult PAIRING_RESULT_ACCEPTED =
      PairingResult._(1, _omitEnumNames ? '' : 'PAIRING_RESULT_ACCEPTED');
  static const PairingResult PAIRING_RESULT_REJECTED =
      PairingResult._(2, _omitEnumNames ? '' : 'PAIRING_RESULT_REJECTED');
  static const PairingResult PAIRING_RESULT_EXPIRED =
      PairingResult._(3, _omitEnumNames ? '' : 'PAIRING_RESULT_EXPIRED');
  static const PairingResult PAIRING_RESULT_BAD_PROOF =
      PairingResult._(4, _omitEnumNames ? '' : 'PAIRING_RESULT_BAD_PROOF');

  /// Nobody answered the prompt in time.
  static const PairingResult PAIRING_RESULT_TIMED_OUT =
      PairingResult._(5, _omitEnumNames ? '' : 'PAIRING_RESULT_TIMED_OUT');

  static const $core.List<PairingResult> values = <PairingResult>[
    PAIRING_RESULT_UNSPECIFIED,
    PAIRING_RESULT_ACCEPTED,
    PAIRING_RESULT_REJECTED,
    PAIRING_RESULT_EXPIRED,
    PAIRING_RESULT_BAD_PROOF,
    PAIRING_RESULT_TIMED_OUT,
  ];

  static final $core.List<PairingResult?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static PairingResult? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PairingResult._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
