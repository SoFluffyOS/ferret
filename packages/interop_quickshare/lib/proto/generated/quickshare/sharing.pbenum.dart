// This is a generated file - do not edit.
//
// Generated from quickshare/sharing.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SharingFrame_Version extends $pb.ProtobufEnum {
  static const SharingFrame_Version UNKNOWN_VERSION =
      SharingFrame_Version._(0, _omitEnumNames ? '' : 'UNKNOWN_VERSION');
  static const SharingFrame_Version V1 =
      SharingFrame_Version._(1, _omitEnumNames ? '' : 'V1');

  static const $core.List<SharingFrame_Version> values = <SharingFrame_Version>[
    UNKNOWN_VERSION,
    V1,
  ];

  static final $core.List<SharingFrame_Version?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static SharingFrame_Version? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SharingFrame_Version._(super.value, super.name);
}

class SharingFrameV1_FrameType extends $pb.ProtobufEnum {
  static const SharingFrameV1_FrameType UNKNOWN_FRAME_TYPE =
      SharingFrameV1_FrameType._(0, _omitEnumNames ? '' : 'UNKNOWN_FRAME_TYPE');
  static const SharingFrameV1_FrameType INTRODUCTION =
      SharingFrameV1_FrameType._(1, _omitEnumNames ? '' : 'INTRODUCTION');
  static const SharingFrameV1_FrameType RESPONSE =
      SharingFrameV1_FrameType._(2, _omitEnumNames ? '' : 'RESPONSE');
  static const SharingFrameV1_FrameType PAIRED_KEY_ENCRYPTION =
      SharingFrameV1_FrameType._(
          3, _omitEnumNames ? '' : 'PAIRED_KEY_ENCRYPTION');
  static const SharingFrameV1_FrameType PAIRED_KEY_RESULT =
      SharingFrameV1_FrameType._(4, _omitEnumNames ? '' : 'PAIRED_KEY_RESULT');
  static const SharingFrameV1_FrameType CERTIFICATE_INFO =
      SharingFrameV1_FrameType._(5, _omitEnumNames ? '' : 'CERTIFICATE_INFO');
  static const SharingFrameV1_FrameType CANCEL =
      SharingFrameV1_FrameType._(6, _omitEnumNames ? '' : 'CANCEL');
  static const SharingFrameV1_FrameType PROGRESS_UPDATE =
      SharingFrameV1_FrameType._(7, _omitEnumNames ? '' : 'PROGRESS_UPDATE');

  static const $core.List<SharingFrameV1_FrameType> values =
      <SharingFrameV1_FrameType>[
    UNKNOWN_FRAME_TYPE,
    INTRODUCTION,
    RESPONSE,
    PAIRED_KEY_ENCRYPTION,
    PAIRED_KEY_RESULT,
    CERTIFICATE_INFO,
    CANCEL,
    PROGRESS_UPDATE,
  ];

  static final $core.List<SharingFrameV1_FrameType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static SharingFrameV1_FrameType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SharingFrameV1_FrameType._(super.value, super.name);
}

class FileMetadata_Type extends $pb.ProtobufEnum {
  static const FileMetadata_Type UNKNOWN =
      FileMetadata_Type._(0, _omitEnumNames ? '' : 'UNKNOWN');
  static const FileMetadata_Type IMAGE =
      FileMetadata_Type._(1, _omitEnumNames ? '' : 'IMAGE');
  static const FileMetadata_Type VIDEO =
      FileMetadata_Type._(2, _omitEnumNames ? '' : 'VIDEO');
  static const FileMetadata_Type ANDROID_APP =
      FileMetadata_Type._(3, _omitEnumNames ? '' : 'ANDROID_APP');
  static const FileMetadata_Type AUDIO =
      FileMetadata_Type._(4, _omitEnumNames ? '' : 'AUDIO');
  static const FileMetadata_Type DOCUMENT =
      FileMetadata_Type._(5, _omitEnumNames ? '' : 'DOCUMENT');
  static const FileMetadata_Type CONTACT_CARD =
      FileMetadata_Type._(6, _omitEnumNames ? '' : 'CONTACT_CARD');

  static const $core.List<FileMetadata_Type> values = <FileMetadata_Type>[
    UNKNOWN,
    IMAGE,
    VIDEO,
    ANDROID_APP,
    AUDIO,
    DOCUMENT,
    CONTACT_CARD,
  ];

  static final $core.List<FileMetadata_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static FileMetadata_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FileMetadata_Type._(super.value, super.name);
}

class TextMetadata_Type extends $pb.ProtobufEnum {
  static const TextMetadata_Type UNKNOWN =
      TextMetadata_Type._(0, _omitEnumNames ? '' : 'UNKNOWN');
  static const TextMetadata_Type TEXT =
      TextMetadata_Type._(1, _omitEnumNames ? '' : 'TEXT');
  static const TextMetadata_Type URL =
      TextMetadata_Type._(2, _omitEnumNames ? '' : 'URL');
  static const TextMetadata_Type ADDRESS =
      TextMetadata_Type._(3, _omitEnumNames ? '' : 'ADDRESS');
  static const TextMetadata_Type PHONE_NUMBER =
      TextMetadata_Type._(4, _omitEnumNames ? '' : 'PHONE_NUMBER');

  static const $core.List<TextMetadata_Type> values = <TextMetadata_Type>[
    UNKNOWN,
    TEXT,
    URL,
    ADDRESS,
    PHONE_NUMBER,
  ];

  static final $core.List<TextMetadata_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static TextMetadata_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TextMetadata_Type._(super.value, super.name);
}

class TransferResponse_Status extends $pb.ProtobufEnum {
  static const TransferResponse_Status UNKNOWN =
      TransferResponse_Status._(0, _omitEnumNames ? '' : 'UNKNOWN');
  static const TransferResponse_Status ACCEPT =
      TransferResponse_Status._(1, _omitEnumNames ? '' : 'ACCEPT');
  static const TransferResponse_Status REJECT =
      TransferResponse_Status._(2, _omitEnumNames ? '' : 'REJECT');
  static const TransferResponse_Status NOT_ENOUGH_SPACE =
      TransferResponse_Status._(3, _omitEnumNames ? '' : 'NOT_ENOUGH_SPACE');
  static const TransferResponse_Status UNSUPPORTED_ATTACHMENT_TYPE =
      TransferResponse_Status._(
          4, _omitEnumNames ? '' : 'UNSUPPORTED_ATTACHMENT_TYPE');
  static const TransferResponse_Status TIMED_OUT =
      TransferResponse_Status._(5, _omitEnumNames ? '' : 'TIMED_OUT');

  static const $core.List<TransferResponse_Status> values =
      <TransferResponse_Status>[
    UNKNOWN,
    ACCEPT,
    REJECT,
    NOT_ENOUGH_SPACE,
    UNSUPPORTED_ATTACHMENT_TYPE,
    TIMED_OUT,
  ];

  static final $core.List<TransferResponse_Status?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static TransferResponse_Status? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TransferResponse_Status._(super.value, super.name);
}

class PairedKeyResult_Status extends $pb.ProtobufEnum {
  static const PairedKeyResult_Status UNKNOWN =
      PairedKeyResult_Status._(0, _omitEnumNames ? '' : 'UNKNOWN');
  static const PairedKeyResult_Status SUCCESS =
      PairedKeyResult_Status._(1, _omitEnumNames ? '' : 'SUCCESS');
  static const PairedKeyResult_Status FAIL =
      PairedKeyResult_Status._(2, _omitEnumNames ? '' : 'FAIL');
  static const PairedKeyResult_Status UNABLE =
      PairedKeyResult_Status._(3, _omitEnumNames ? '' : 'UNABLE');

  static const $core.List<PairedKeyResult_Status> values =
      <PairedKeyResult_Status>[
    UNKNOWN,
    SUCCESS,
    FAIL,
    UNABLE,
  ];

  static final $core.List<PairedKeyResult_Status?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PairedKeyResult_Status? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PairedKeyResult_Status._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
