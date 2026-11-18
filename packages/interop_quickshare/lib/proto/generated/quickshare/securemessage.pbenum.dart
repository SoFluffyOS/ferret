// This is a generated file - do not edit.
//
// Generated from quickshare/securemessage.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SigScheme extends $pb.ProtobufEnum {
  static const SigScheme UNKNOWN_SIG_SCHEME =
      SigScheme._(0, _omitEnumNames ? '' : 'UNKNOWN_SIG_SCHEME');
  static const SigScheme HMAC_SHA256 =
      SigScheme._(1, _omitEnumNames ? '' : 'HMAC_SHA256');
  static const SigScheme ECDSA_P256_SHA256 =
      SigScheme._(2, _omitEnumNames ? '' : 'ECDSA_P256_SHA256');
  static const SigScheme RSA2048_SHA256 =
      SigScheme._(3, _omitEnumNames ? '' : 'RSA2048_SHA256');

  static const $core.List<SigScheme> values = <SigScheme>[
    UNKNOWN_SIG_SCHEME,
    HMAC_SHA256,
    ECDSA_P256_SHA256,
    RSA2048_SHA256,
  ];

  static final $core.List<SigScheme?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static SigScheme? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SigScheme._(super.value, super.name);
}

class EncScheme extends $pb.ProtobufEnum {
  static const EncScheme UNKNOWN_ENC_SCHEME =
      EncScheme._(0, _omitEnumNames ? '' : 'UNKNOWN_ENC_SCHEME');
  static const EncScheme NONE = EncScheme._(1, _omitEnumNames ? '' : 'NONE');
  static const EncScheme AES_256_CBC =
      EncScheme._(2, _omitEnumNames ? '' : 'AES_256_CBC');

  static const $core.List<EncScheme> values = <EncScheme>[
    UNKNOWN_ENC_SCHEME,
    NONE,
    AES_256_CBC,
  ];

  static final $core.List<EncScheme?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static EncScheme? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const EncScheme._(super.value, super.name);
}

class PublicKeyType extends $pb.ProtobufEnum {
  static const PublicKeyType UNKNOWN_PUBLIC_KEY_TYPE =
      PublicKeyType._(0, _omitEnumNames ? '' : 'UNKNOWN_PUBLIC_KEY_TYPE');
  static const PublicKeyType EC_P256 =
      PublicKeyType._(1, _omitEnumNames ? '' : 'EC_P256');
  static const PublicKeyType RSA2048 =
      PublicKeyType._(2, _omitEnumNames ? '' : 'RSA2048');
  static const PublicKeyType DH2048_MODP =
      PublicKeyType._(3, _omitEnumNames ? '' : 'DH2048_MODP');

  static const $core.List<PublicKeyType> values = <PublicKeyType>[
    UNKNOWN_PUBLIC_KEY_TYPE,
    EC_P256,
    RSA2048,
    DH2048_MODP,
  ];

  static final $core.List<PublicKeyType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PublicKeyType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PublicKeyType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
