// This is a generated file - do not edit.
//
// Generated from ferret/scripting/v1/scripting.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ScriptNoticeResult extends $pb.ProtobufEnum {
  static const ScriptNoticeResult SCRIPT_NOTICE_RESULT_UNSPECIFIED =
      ScriptNoticeResult._(
          0, _omitEnumNames ? '' : 'SCRIPT_NOTICE_RESULT_UNSPECIFIED');

  /// The receiver showed it.
  static const ScriptNoticeResult SCRIPT_NOTICE_RESULT_SHOWN =
      ScriptNoticeResult._(
          1, _omitEnumNames ? '' : 'SCRIPT_NOTICE_RESULT_SHOWN');

  /// Its owner hasn't allowed scripts from the sending device to notify.
  static const ScriptNoticeResult SCRIPT_NOTICE_RESULT_NOT_ALLOWED =
      ScriptNoticeResult._(
          2, _omitEnumNames ? '' : 'SCRIPT_NOTICE_RESULT_NOT_ALLOWED');

  /// Too many notices came in a short time, so this one was dropped.
  static const ScriptNoticeResult SCRIPT_NOTICE_RESULT_TOO_MANY =
      ScriptNoticeResult._(
          3, _omitEnumNames ? '' : 'SCRIPT_NOTICE_RESULT_TOO_MANY');

  /// It had no title and no body.
  static const ScriptNoticeResult SCRIPT_NOTICE_RESULT_EMPTY =
      ScriptNoticeResult._(
          4, _omitEnumNames ? '' : 'SCRIPT_NOTICE_RESULT_EMPTY');

  static const $core.List<ScriptNoticeResult> values = <ScriptNoticeResult>[
    SCRIPT_NOTICE_RESULT_UNSPECIFIED,
    SCRIPT_NOTICE_RESULT_SHOWN,
    SCRIPT_NOTICE_RESULT_NOT_ALLOWED,
    SCRIPT_NOTICE_RESULT_TOO_MANY,
    SCRIPT_NOTICE_RESULT_EMPTY,
  ];

  static final $core.List<ScriptNoticeResult?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ScriptNoticeResult? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ScriptNoticeResult._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
