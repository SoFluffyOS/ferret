// This is a generated file - do not edit.
//
// Generated from ferret/v1/device.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// The operating system a device runs.
class Platform extends $pb.ProtobufEnum {
  static const Platform PLATFORM_UNSPECIFIED =
      Platform._(0, _omitEnumNames ? '' : 'PLATFORM_UNSPECIFIED');
  static const Platform PLATFORM_ANDROID =
      Platform._(1, _omitEnumNames ? '' : 'PLATFORM_ANDROID');
  static const Platform PLATFORM_IOS =
      Platform._(2, _omitEnumNames ? '' : 'PLATFORM_IOS');
  static const Platform PLATFORM_MACOS =
      Platform._(3, _omitEnumNames ? '' : 'PLATFORM_MACOS');
  static const Platform PLATFORM_LINUX =
      Platform._(4, _omitEnumNames ? '' : 'PLATFORM_LINUX');
  static const Platform PLATFORM_WINDOWS =
      Platform._(5, _omitEnumNames ? '' : 'PLATFORM_WINDOWS');
  static const Platform PLATFORM_BROWSER =
      Platform._(6, _omitEnumNames ? '' : 'PLATFORM_BROWSER');
  static const Platform PLATFORM_CLI =
      Platform._(7, _omitEnumNames ? '' : 'PLATFORM_CLI');

  static const $core.List<Platform> values = <Platform>[
    PLATFORM_UNSPECIFIED,
    PLATFORM_ANDROID,
    PLATFORM_IOS,
    PLATFORM_MACOS,
    PLATFORM_LINUX,
    PLATFORM_WINDOWS,
    PLATFORM_BROWSER,
    PLATFORM_CLI,
  ];

  static final $core.List<Platform?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static Platform? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Platform._(super.value, super.name);
}

/// The kind of device, used for icons and for choosing where to suggest things.
class FormFactor extends $pb.ProtobufEnum {
  static const FormFactor FORM_FACTOR_UNSPECIFIED =
      FormFactor._(0, _omitEnumNames ? '' : 'FORM_FACTOR_UNSPECIFIED');
  static const FormFactor FORM_FACTOR_PHONE =
      FormFactor._(1, _omitEnumNames ? '' : 'FORM_FACTOR_PHONE');
  static const FormFactor FORM_FACTOR_TABLET =
      FormFactor._(2, _omitEnumNames ? '' : 'FORM_FACTOR_TABLET');
  static const FormFactor FORM_FACTOR_LAPTOP =
      FormFactor._(3, _omitEnumNames ? '' : 'FORM_FACTOR_LAPTOP');
  static const FormFactor FORM_FACTOR_DESKTOP =
      FormFactor._(4, _omitEnumNames ? '' : 'FORM_FACTOR_DESKTOP');
  static const FormFactor FORM_FACTOR_SERVER =
      FormFactor._(5, _omitEnumNames ? '' : 'FORM_FACTOR_SERVER');

  static const $core.List<FormFactor> values = <FormFactor>[
    FORM_FACTOR_UNSPECIFIED,
    FORM_FACTOR_PHONE,
    FORM_FACTOR_TABLET,
    FORM_FACTOR_LAPTOP,
    FORM_FACTOR_DESKTOP,
    FORM_FACTOR_SERVER,
  ];

  static final $core.List<FormFactor?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static FormFactor? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FormFactor._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
