// This is a generated file - do not edit.
//
// Generated from ferret/camera/v1/camera.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// What the computer asks for.
class CaptureKind extends $pb.ProtobufEnum {
  static const CaptureKind CAPTURE_KIND_UNSPECIFIED =
      CaptureKind._(0, _omitEnumNames ? '' : 'CAPTURE_KIND_UNSPECIFIED');
  static const CaptureKind CAPTURE_KIND_PHOTO =
      CaptureKind._(1, _omitEnumNames ? '' : 'CAPTURE_KIND_PHOTO');

  /// A scanned document: a JPEG for one page, a PDF for several. iPhone only.
  static const CaptureKind CAPTURE_KIND_DOCUMENT =
      CaptureKind._(2, _omitEnumNames ? '' : 'CAPTURE_KIND_DOCUMENT');

  static const $core.List<CaptureKind> values = <CaptureKind>[
    CAPTURE_KIND_UNSPECIFIED,
    CAPTURE_KIND_PHOTO,
    CAPTURE_KIND_DOCUMENT,
  ];

  static final $core.List<CaptureKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static CaptureKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CaptureKind._(super.value, super.name);
}

/// Where a request stands.
class CaptureStatus extends $pb.ProtobufEnum {
  static const CaptureStatus CAPTURE_STATUS_UNSPECIFIED =
      CaptureStatus._(0, _omitEnumNames ? '' : 'CAPTURE_STATUS_UNSPECIFIED');

  /// The phone shows the request and waits for its owner.
  static const CaptureStatus CAPTURE_STATUS_ASKING =
      CaptureStatus._(1, _omitEnumNames ? '' : 'CAPTURE_STATUS_ASKING');

  /// A picture was taken; transfer_id names the drop transfer carrying it.
  static const CaptureStatus CAPTURE_STATUS_TAKEN =
      CaptureStatus._(2, _omitEnumNames ? '' : 'CAPTURE_STATUS_TAKEN');

  /// The owner answered "Not now".
  static const CaptureStatus CAPTURE_STATUS_DECLINED =
      CaptureStatus._(3, _omitEnumNames ? '' : 'CAPTURE_STATUS_DECLINED');

  /// The camera closed without a picture.
  static const CaptureStatus CAPTURE_STATUS_CANCELLED =
      CaptureStatus._(4, _omitEnumNames ? '' : 'CAPTURE_STATUS_CANCELLED');

  /// This phone can't take that kind of picture, such as a document scan on
  /// Android.
  static const CaptureStatus CAPTURE_STATUS_UNSUPPORTED =
      CaptureStatus._(5, _omitEnumNames ? '' : 'CAPTURE_STATUS_UNSUPPORTED');

  /// The phone's system didn't let Ferret use the camera.
  static const CaptureStatus CAPTURE_STATUS_NO_PERMISSION =
      CaptureStatus._(6, _omitEnumNames ? '' : 'CAPTURE_STATUS_NO_PERMISSION');

  /// The camera is already open for another request.
  static const CaptureStatus CAPTURE_STATUS_BUSY =
      CaptureStatus._(7, _omitEnumNames ? '' : 'CAPTURE_STATUS_BUSY');
  static const CaptureStatus CAPTURE_STATUS_FAILED =
      CaptureStatus._(8, _omitEnumNames ? '' : 'CAPTURE_STATUS_FAILED');

  /// Nobody answered on the phone in time.
  static const CaptureStatus CAPTURE_STATUS_EXPIRED =
      CaptureStatus._(9, _omitEnumNames ? '' : 'CAPTURE_STATUS_EXPIRED');

  static const $core.List<CaptureStatus> values = <CaptureStatus>[
    CAPTURE_STATUS_UNSPECIFIED,
    CAPTURE_STATUS_ASKING,
    CAPTURE_STATUS_TAKEN,
    CAPTURE_STATUS_DECLINED,
    CAPTURE_STATUS_CANCELLED,
    CAPTURE_STATUS_UNSUPPORTED,
    CAPTURE_STATUS_NO_PERMISSION,
    CAPTURE_STATUS_BUSY,
    CAPTURE_STATUS_FAILED,
    CAPTURE_STATUS_EXPIRED,
  ];

  static final $core.List<CaptureStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 9);
  static CaptureStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CaptureStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
