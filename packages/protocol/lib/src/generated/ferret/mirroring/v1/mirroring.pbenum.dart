// This is a generated file - do not edit.
//
// Generated from ferret/mirroring/v1/mirroring.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// How the pictures are encoded.
class Codec extends $pb.ProtobufEnum {
  static const Codec CODEC_UNSPECIFIED =
      Codec._(0, _omitEnumNames ? '' : 'CODEC_UNSPECIFIED');

  /// H.264 video. `Frame.data` is one access unit in Annex-B form.
  static const Codec CODEC_H264 =
      Codec._(1, _omitEnumNames ? '' : 'CODEC_H264');

  /// A JPEG picture per frame, for viewers without a video decoder. Fewer
  /// frames per second and a smaller picture.
  static const Codec CODEC_JPEG =
      Codec._(2, _omitEnumNames ? '' : 'CODEC_JPEG');

  static const $core.List<Codec> values = <Codec>[
    CODEC_UNSPECIFIED,
    CODEC_H264,
    CODEC_JPEG,
  ];

  static final $core.List<Codec?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Codec? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Codec._(super.value, super.name);
}

/// Why a source said no.
class DenyReason extends $pb.ProtobufEnum {
  static const DenyReason DENY_REASON_UNSPECIFIED =
      DenyReason._(0, _omitEnumNames ? '' : 'DENY_REASON_UNSPECIFIED');

  /// Its owner said no on the system prompt.
  static const DenyReason DENY_REASON_DENIED =
      DenyReason._(1, _omitEnumNames ? '' : 'DENY_REASON_DENIED');

  /// Nobody answered on the source in time.
  static const DenyReason DENY_REASON_TIMEOUT =
      DenyReason._(2, _omitEnumNames ? '' : 'DENY_REASON_TIMEOUT');

  /// It already shares its screen, or is asking its owner, for another
  /// device.
  static const DenyReason DENY_REASON_BUSY =
      DenyReason._(3, _omitEnumNames ? '' : 'DENY_REASON_BUSY');

  /// This device can't capture its screen.
  static const DenyReason DENY_REASON_UNSUPPORTED =
      DenyReason._(4, _omitEnumNames ? '' : 'DENY_REASON_UNSUPPORTED');

  /// Its owner turned screen mirroring off.
  static const DenyReason DENY_REASON_TURNED_OFF =
      DenyReason._(5, _omitEnumNames ? '' : 'DENY_REASON_TURNED_OFF');

  /// The viewer speaks a newer version.
  static const DenyReason DENY_REASON_VERSION =
      DenyReason._(6, _omitEnumNames ? '' : 'DENY_REASON_VERSION');

  /// The source can't encode any of `StartRequest.codecs`.
  static const DenyReason DENY_REASON_NO_CODEC =
      DenyReason._(7, _omitEnumNames ? '' : 'DENY_REASON_NO_CODEC');

  /// The source couldn't show the question, such as when its app is in the
  /// background and may not post notices.
  static const DenyReason DENY_REASON_CANNOT_ASK =
      DenyReason._(8, _omitEnumNames ? '' : 'DENY_REASON_CANNOT_ASK');

  /// Capturing or encoding failed to start.
  static const DenyReason DENY_REASON_FAILED =
      DenyReason._(9, _omitEnumNames ? '' : 'DENY_REASON_FAILED');

  static const $core.List<DenyReason> values = <DenyReason>[
    DENY_REASON_UNSPECIFIED,
    DENY_REASON_DENIED,
    DENY_REASON_TIMEOUT,
    DENY_REASON_BUSY,
    DENY_REASON_UNSUPPORTED,
    DENY_REASON_TURNED_OFF,
    DENY_REASON_VERSION,
    DENY_REASON_NO_CODEC,
    DENY_REASON_CANNOT_ASK,
    DENY_REASON_FAILED,
  ];

  static final $core.List<DenyReason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 9);
  static DenyReason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DenyReason._(super.value, super.name);
}

/// Why mirroring ended.
class StopReason extends $pb.ProtobufEnum {
  static const StopReason STOP_REASON_UNSPECIFIED =
      StopReason._(0, _omitEnumNames ? '' : 'STOP_REASON_UNSPECIFIED');

  /// The viewer is done, such as when its mirror page closed, or it gave up
  /// waiting for the answer.
  static const StopReason STOP_REASON_VIEWER_DONE =
      StopReason._(1, _omitEnumNames ? '' : 'STOP_REASON_VIEWER_DONE');

  /// Someone on the source pressed Stop.
  static const StopReason STOP_REASON_STOPPED_ON_SOURCE =
      StopReason._(2, _omitEnumNames ? '' : 'STOP_REASON_STOPPED_ON_SOURCE');

  /// The source's system ended the capture, such as when the phone was
  /// locked.
  static const StopReason STOP_REASON_SYSTEM_ENDED =
      StopReason._(3, _omitEnumNames ? '' : 'STOP_REASON_SYSTEM_ENDED');

  /// The source's owner turned screen mirroring off.
  static const StopReason STOP_REASON_TURNED_OFF =
      StopReason._(4, _omitEnumNames ? '' : 'STOP_REASON_TURNED_OFF');

  /// Capturing or encoding stopped working.
  static const StopReason STOP_REASON_FAILED =
      StopReason._(5, _omitEnumNames ? '' : 'STOP_REASON_FAILED');

  /// A frame or request arrived for a mirroring session that isn't running.
  static const StopReason STOP_REASON_NOT_MIRRORING =
      StopReason._(6, _omitEnumNames ? '' : 'STOP_REASON_NOT_MIRRORING');

  static const $core.List<StopReason> values = <StopReason>[
    STOP_REASON_UNSPECIFIED,
    STOP_REASON_VIEWER_DONE,
    STOP_REASON_STOPPED_ON_SOURCE,
    STOP_REASON_SYSTEM_ENDED,
    STOP_REASON_TURNED_OFF,
    STOP_REASON_FAILED,
    STOP_REASON_NOT_MIRRORING,
  ];

  static final $core.List<StopReason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static StopReason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const StopReason._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
