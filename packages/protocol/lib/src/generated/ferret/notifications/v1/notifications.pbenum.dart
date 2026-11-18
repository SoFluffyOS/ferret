// This is a generated file - do not edit.
//
// Generated from ferret/notifications/v1/notifications.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Which apps the source mirrors.
class AppFilter extends $pb.ProtobufEnum {
  /// Sent by sources that predate the filter: they mirror `allowed_packages`
  /// only, as `APP_FILTER_ONLY`.
  static const AppFilter APP_FILTER_UNSPECIFIED =
      AppFilter._(0, _omitEnumNames ? '' : 'APP_FILTER_UNSPECIFIED');

  /// Every app.
  static const AppFilter APP_FILTER_ALL =
      AppFilter._(1, _omitEnumNames ? '' : 'APP_FILTER_ALL');

  /// Every app except `excluded_packages`.
  static const AppFilter APP_FILTER_ALL_EXCEPT =
      AppFilter._(2, _omitEnumNames ? '' : 'APP_FILTER_ALL_EXCEPT');

  /// Only `allowed_packages`.
  static const AppFilter APP_FILTER_ONLY =
      AppFilter._(3, _omitEnumNames ? '' : 'APP_FILTER_ONLY');

  static const $core.List<AppFilter> values = <AppFilter>[
    APP_FILTER_UNSPECIFIED,
    APP_FILTER_ALL,
    APP_FILTER_ALL_EXCEPT,
    APP_FILTER_ONLY,
  ];

  static final $core.List<AppFilter?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static AppFilter? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AppFilter._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
