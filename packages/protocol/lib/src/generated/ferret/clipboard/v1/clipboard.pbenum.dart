// This is a generated file - do not edit.
//
// Generated from ferret/clipboard/v1/clipboard.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// What a clip holds, so receivers can preview it without parsing.
class ClipKind extends $pb.ProtobufEnum {
  static const ClipKind CLIP_KIND_UNSPECIFIED =
      ClipKind._(0, _omitEnumNames ? '' : 'CLIP_KIND_UNSPECIFIED');
  static const ClipKind CLIP_KIND_TEXT =
      ClipKind._(1, _omitEnumNames ? '' : 'CLIP_KIND_TEXT');
  static const ClipKind CLIP_KIND_IMAGE =
      ClipKind._(2, _omitEnumNames ? '' : 'CLIP_KIND_IMAGE');

  /// Text that is a single http or https link.
  static const ClipKind CLIP_KIND_URL =
      ClipKind._(3, _omitEnumNames ? '' : 'CLIP_KIND_URL');

  static const $core.List<ClipKind> values = <ClipKind>[
    CLIP_KIND_UNSPECIFIED,
    CLIP_KIND_TEXT,
    CLIP_KIND_IMAGE,
    CLIP_KIND_URL,
  ];

  static final $core.List<ClipKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ClipKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ClipKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
