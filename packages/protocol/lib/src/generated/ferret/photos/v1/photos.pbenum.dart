// This is a generated file - do not edit.
//
// Generated from ferret/photos/v1/photos.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// What a photo is.
class PhotoKind extends $pb.ProtobufEnum {
  static const PhotoKind PHOTO_KIND_UNSPECIFIED =
      PhotoKind._(0, _omitEnumNames ? '' : 'PHOTO_KIND_UNSPECIFIED');
  static const PhotoKind PHOTO_KIND_PHOTO =
      PhotoKind._(1, _omitEnumNames ? '' : 'PHOTO_KIND_PHOTO');

  /// A screenshot or screen recording still, as the phone files it.
  static const PhotoKind PHOTO_KIND_SCREENSHOT =
      PhotoKind._(2, _omitEnumNames ? '' : 'PHOTO_KIND_SCREENSHOT');
  static const PhotoKind PHOTO_KIND_VIDEO =
      PhotoKind._(3, _omitEnumNames ? '' : 'PHOTO_KIND_VIDEO');

  static const $core.List<PhotoKind> values = <PhotoKind>[
    PHOTO_KIND_UNSPECIFIED,
    PHOTO_KIND_PHOTO,
    PHOTO_KIND_SCREENSHOT,
    PHOTO_KIND_VIDEO,
  ];

  static final $core.List<PhotoKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PhotoKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PhotoKind._(super.value, super.name);
}

/// How much the asking device may see right now.
class PhotoAccess extends $pb.ProtobufEnum {
  static const PhotoAccess PHOTO_ACCESS_UNSPECIFIED =
      PhotoAccess._(0, _omitEnumNames ? '' : 'PHOTO_ACCESS_UNSPECIFIED');

  /// The phone's owner hasn't let the asking device see photos.
  static const PhotoAccess PHOTO_ACCESS_NOT_ALLOWED =
      PhotoAccess._(1, _omitEnumNames ? '' : 'PHOTO_ACCESS_NOT_ALLOWED');

  /// The phone's system hasn't given Ferret photo access yet, or it was
  /// turned off.
  static const PhotoAccess PHOTO_ACCESS_NO_PERMISSION =
      PhotoAccess._(2, _omitEnumNames ? '' : 'PHOTO_ACCESS_NO_PERMISSION');

  /// Only the photos the owner picked: Android 14's "Selected photos" or the
  /// iPhone's limited library.
  static const PhotoAccess PHOTO_ACCESS_LIMITED =
      PhotoAccess._(3, _omitEnumNames ? '' : 'PHOTO_ACCESS_LIMITED');
  static const PhotoAccess PHOTO_ACCESS_FULL =
      PhotoAccess._(4, _omitEnumNames ? '' : 'PHOTO_ACCESS_FULL');

  /// The phone can't read photos right now, such as an iPhone with Ferret
  /// in the background.
  static const PhotoAccess PHOTO_ACCESS_UNAVAILABLE =
      PhotoAccess._(5, _omitEnumNames ? '' : 'PHOTO_ACCESS_UNAVAILABLE');

  static const $core.List<PhotoAccess> values = <PhotoAccess>[
    PHOTO_ACCESS_UNSPECIFIED,
    PHOTO_ACCESS_NOT_ALLOWED,
    PHOTO_ACCESS_NO_PERMISSION,
    PHOTO_ACCESS_LIMITED,
    PHOTO_ACCESS_FULL,
    PHOTO_ACCESS_UNAVAILABLE,
  ];

  static final $core.List<PhotoAccess?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static PhotoAccess? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PhotoAccess._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
