// This is a generated file - do not edit.
//
// Generated from ferret/handoff/v1/handoff.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// What an activity is, which decides how the receiving device opens it.
class ActivityKind extends $pb.ProtobufEnum {
  static const ActivityKind ACTIVITY_KIND_UNSPECIFIED =
      ActivityKind._(0, _omitEnumNames ? '' : 'ACTIVITY_KIND_UNSPECIFIED');

  /// A web page: `uri` is http(s).
  static const ActivityKind ACTIVITY_KIND_WEB =
      ActivityKind._(1, _omitEnumNames ? '' : 'ACTIVITY_KIND_WEB');

  /// Something inside an app: `deep_link` and `apps`, with `fallback_web_uri`
  /// for devices that don't have the app.
  static const ActivityKind ACTIVITY_KIND_APP =
      ActivityKind._(2, _omitEnumNames ? '' : 'ACTIVITY_KIND_APP');

  /// A place: `uri` is a geo: URI (RFC 5870).
  static const ActivityKind ACTIVITY_KIND_GEO =
      ActivityKind._(3, _omitEnumNames ? '' : 'ACTIVITY_KIND_GEO');

  /// Plain text in `text`, such as a note or an address.
  static const ActivityKind ACTIVITY_KIND_TEXT =
      ActivityKind._(4, _omitEnumNames ? '' : 'ACTIVITY_KIND_TEXT');

  static const $core.List<ActivityKind> values = <ActivityKind>[
    ACTIVITY_KIND_UNSPECIFIED,
    ACTIVITY_KIND_WEB,
    ACTIVITY_KIND_APP,
    ACTIVITY_KIND_GEO,
    ACTIVITY_KIND_TEXT,
  ];

  static final $core.List<ActivityKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ActivityKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ActivityKind._(super.value, super.name);
}

/// What the receiver did with a ContinueActivity.
class ContinueOutcome extends $pb.ProtobufEnum {
  static const ContinueOutcome CONTINUE_OUTCOME_UNSPECIFIED = ContinueOutcome._(
      0, _omitEnumNames ? '' : 'CONTINUE_OUTCOME_UNSPECIFIED');

  /// Opened right away.
  static const ContinueOutcome CONTINUE_OUTCOME_OPENED =
      ContinueOutcome._(1, _omitEnumNames ? '' : 'CONTINUE_OUTCOME_OPENED');

  /// Kept as a suggestion with a notice, because the user turned automatic
  /// opening off.
  static const ContinueOutcome CONTINUE_OUTCOME_SUGGESTED =
      ContinueOutcome._(2, _omitEnumNames ? '' : 'CONTINUE_OUTCOME_SUGGESTED');

  /// Could not open it, such as a URI scheme it doesn't accept.
  static const ContinueOutcome CONTINUE_OUTCOME_FAILED =
      ContinueOutcome._(3, _omitEnumNames ? '' : 'CONTINUE_OUTCOME_FAILED');

  static const $core.List<ContinueOutcome> values = <ContinueOutcome>[
    CONTINUE_OUTCOME_UNSPECIFIED,
    CONTINUE_OUTCOME_OPENED,
    CONTINUE_OUTCOME_SUGGESTED,
    CONTINUE_OUTCOME_FAILED,
  ];

  static final $core.List<ContinueOutcome?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ContinueOutcome? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ContinueOutcome._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
