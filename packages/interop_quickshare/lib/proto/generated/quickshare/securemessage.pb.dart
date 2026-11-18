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

import 'securemessage.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'securemessage.pbenum.dart';

class SecureMessage extends $pb.GeneratedMessage {
  factory SecureMessage({
    $core.List<$core.int>? headerAndBody,
    $core.List<$core.int>? signature,
  }) {
    final result = SecureMessage._();
    if (headerAndBody != null) result.headerAndBody = headerAndBody;
    if (signature != null) result.signature = signature;
    return result;
  }

  SecureMessage._();

  factory SecureMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SecureMessage()..mergeFromBuffer(data, registry);
  factory SecureMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SecureMessage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SecureMessage',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.securemessage'),
      createEmptyInstance: SecureMessage.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'headerAndBody', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SecureMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SecureMessage copyWith(void Function(SecureMessage) updates) =>
      super.copyWith((message) => updates(message as SecureMessage))
          as SecureMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SecureMessage() / SecureMessage.new instead')
  static SecureMessage create() => SecureMessage._();
  static $pb.GeneratedMessage $_createMessage() => SecureMessage._();
  @$core.override
  SecureMessage createEmptyInstance() => SecureMessage._();
  @$core.pragma('dart2js:noInline')
  static SecureMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SecureMessage>(
          SecureMessage.$_createMessage);
  static SecureMessage? _defaultInstance;

  /// A serialized HeaderAndBody. The signature covers exactly these bytes.
  @$pb.TagNumber(1)
  $core.List<$core.int> get headerAndBody => $_getN(0);
  @$pb.TagNumber(1)
  set headerAndBody($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHeaderAndBody() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeaderAndBody() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get signature => $_getN(1);
  @$pb.TagNumber(2)
  set signature($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSignature() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignature() => $_clearField(2);
}

class Header extends $pb.GeneratedMessage {
  factory Header({
    SigScheme? signatureScheme,
    EncScheme? encryptionScheme,
    $core.List<$core.int>? verificationKeyId,
    $core.List<$core.int>? decryptionKeyId,
    $core.List<$core.int>? iv,
    $core.List<$core.int>? publicMetadata,
    $core.int? associatedDataLength,
  }) {
    final result = Header._();
    if (signatureScheme != null) result.signatureScheme = signatureScheme;
    if (encryptionScheme != null) result.encryptionScheme = encryptionScheme;
    if (verificationKeyId != null) result.verificationKeyId = verificationKeyId;
    if (decryptionKeyId != null) result.decryptionKeyId = decryptionKeyId;
    if (iv != null) result.iv = iv;
    if (publicMetadata != null) result.publicMetadata = publicMetadata;
    if (associatedDataLength != null)
      result.associatedDataLength = associatedDataLength;
    return result;
  }

  Header._();

  factory Header.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Header()..mergeFromBuffer(data, registry);
  factory Header.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Header()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Header',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.securemessage'),
      createEmptyInstance: Header.$_createMessage)
    ..aE<SigScheme>(1, _omitFieldNames ? '' : 'signatureScheme',
        enumValues: SigScheme.values)
    ..aE<EncScheme>(2, _omitFieldNames ? '' : 'encryptionScheme',
        enumValues: EncScheme.values)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'verificationKeyId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'decryptionKeyId', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'iv', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'publicMetadata', $pb.PbFieldType.OY)
    ..aI(7, _omitFieldNames ? '' : 'associatedDataLength',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Header clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Header copyWith(void Function(Header) updates) =>
      super.copyWith((message) => updates(message as Header)) as Header;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Header() / Header.new instead')
  static Header create() => Header._();
  static $pb.GeneratedMessage $_createMessage() => Header._();
  @$core.override
  Header createEmptyInstance() => Header._();
  @$core.pragma('dart2js:noInline')
  static Header getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Header>(Header.$_createMessage);
  static Header? _defaultInstance;

  @$pb.TagNumber(1)
  SigScheme get signatureScheme => $_getN(0);
  @$pb.TagNumber(1)
  set signatureScheme(SigScheme value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSignatureScheme() => $_has(0);
  @$pb.TagNumber(1)
  void clearSignatureScheme() => $_clearField(1);

  @$pb.TagNumber(2)
  EncScheme get encryptionScheme => $_getN(1);
  @$pb.TagNumber(2)
  set encryptionScheme(EncScheme value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEncryptionScheme() => $_has(1);
  @$pb.TagNumber(2)
  void clearEncryptionScheme() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get verificationKeyId => $_getN(2);
  @$pb.TagNumber(3)
  set verificationKeyId($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVerificationKeyId() => $_has(2);
  @$pb.TagNumber(3)
  void clearVerificationKeyId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get decryptionKeyId => $_getN(3);
  @$pb.TagNumber(4)
  set decryptionKeyId($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDecryptionKeyId() => $_has(3);
  @$pb.TagNumber(4)
  void clearDecryptionKeyId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get iv => $_getN(4);
  @$pb.TagNumber(5)
  set iv($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIv() => $_has(4);
  @$pb.TagNumber(5)
  void clearIv() => $_clearField(5);

  /// A serialized GcmMetadata.
  @$pb.TagNumber(6)
  $core.List<$core.int> get publicMetadata => $_getN(5);
  @$pb.TagNumber(6)
  set publicMetadata($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPublicMetadata() => $_has(5);
  @$pb.TagNumber(6)
  void clearPublicMetadata() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get associatedDataLength => $_getIZ(6);
  @$pb.TagNumber(7)
  set associatedDataLength($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAssociatedDataLength() => $_has(6);
  @$pb.TagNumber(7)
  void clearAssociatedDataLength() => $_clearField(7);
}

class HeaderAndBody extends $pb.GeneratedMessage {
  factory HeaderAndBody({
    Header? header,
    $core.List<$core.int>? body,
  }) {
    final result = HeaderAndBody._();
    if (header != null) result.header = header;
    if (body != null) result.body = body;
    return result;
  }

  HeaderAndBody._();

  factory HeaderAndBody.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HeaderAndBody()..mergeFromBuffer(data, registry);
  factory HeaderAndBody.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HeaderAndBody()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeaderAndBody',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.securemessage'),
      createEmptyInstance: HeaderAndBody.$_createMessage)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header',
        subBuilder: Header.$_createMessage)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'body', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeaderAndBody clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeaderAndBody copyWith(void Function(HeaderAndBody) updates) =>
      super.copyWith((message) => updates(message as HeaderAndBody))
          as HeaderAndBody;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HeaderAndBody() / HeaderAndBody.new instead')
  static HeaderAndBody create() => HeaderAndBody._();
  static $pb.GeneratedMessage $_createMessage() => HeaderAndBody._();
  @$core.override
  HeaderAndBody createEmptyInstance() => HeaderAndBody._();
  @$core.pragma('dart2js:noInline')
  static HeaderAndBody getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HeaderAndBody>(
          HeaderAndBody.$_createMessage);
  static HeaderAndBody? _defaultInstance;

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  /// An encrypted DeviceToDeviceMessage.
  @$pb.TagNumber(2)
  $core.List<$core.int> get body => $_getN(1);
  @$pb.TagNumber(2)
  set body($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearBody() => $_clearField(2);
}

class GcmMetadata extends $pb.GeneratedMessage {
  factory GcmMetadata({
    $core.int? type,
    $core.int? version,
  }) {
    final result = GcmMetadata._();
    if (type != null) result.type = type;
    if (version != null) result.version = version;
    return result;
  }

  GcmMetadata._();

  factory GcmMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GcmMetadata()..mergeFromBuffer(data, registry);
  factory GcmMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GcmMetadata()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GcmMetadata',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.securemessage'),
      createEmptyInstance: GcmMetadata.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'type')
    ..aI(2, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GcmMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GcmMetadata copyWith(void Function(GcmMetadata) updates) =>
      super.copyWith((message) => updates(message as GcmMetadata))
          as GcmMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GcmMetadata() / GcmMetadata.new instead')
  static GcmMetadata create() => GcmMetadata._();
  static $pb.GeneratedMessage $_createMessage() => GcmMetadata._();
  @$core.override
  GcmMetadata createEmptyInstance() => GcmMetadata._();
  @$core.pragma('dart2js:noInline')
  static GcmMetadata getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GcmMetadata>(
          GcmMetadata.$_createMessage);
  static GcmMetadata? _defaultInstance;

  /// 13 marks a device to device message, the only kind Quick Share sends.
  @$pb.TagNumber(1)
  $core.int get type => $_getIZ(0);
  @$pb.TagNumber(1)
  set type($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get version => $_getIZ(1);
  @$pb.TagNumber(2)
  set version($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);
}

class DeviceToDeviceMessage extends $pb.GeneratedMessage {
  factory DeviceToDeviceMessage({
    $core.List<$core.int>? message,
    $core.int? sequenceNumber,
  }) {
    final result = DeviceToDeviceMessage._();
    if (message != null) result.message = message;
    if (sequenceNumber != null) result.sequenceNumber = sequenceNumber;
    return result;
  }

  DeviceToDeviceMessage._();

  factory DeviceToDeviceMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeviceToDeviceMessage()..mergeFromBuffer(data, registry);
  factory DeviceToDeviceMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeviceToDeviceMessage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceToDeviceMessage',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.securemessage'),
      createEmptyInstance: DeviceToDeviceMessage.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'message', $pb.PbFieldType.OY)
    ..aI(2, _omitFieldNames ? '' : 'sequenceNumber')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceToDeviceMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceToDeviceMessage copyWith(
          void Function(DeviceToDeviceMessage) updates) =>
      super.copyWith((message) => updates(message as DeviceToDeviceMessage))
          as DeviceToDeviceMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DeviceToDeviceMessage() / DeviceToDeviceMessage.new instead')
  static DeviceToDeviceMessage create() => DeviceToDeviceMessage._();
  static $pb.GeneratedMessage $_createMessage() => DeviceToDeviceMessage._();
  @$core.override
  DeviceToDeviceMessage createEmptyInstance() => DeviceToDeviceMessage._();
  @$core.pragma('dart2js:noInline')
  static DeviceToDeviceMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceToDeviceMessage>(
          DeviceToDeviceMessage.$_createMessage);
  static DeviceToDeviceMessage? _defaultInstance;

  /// A serialized OfflineFrame.
  @$pb.TagNumber(1)
  $core.List<$core.int> get message => $_getN(0);
  @$pb.TagNumber(1)
  set message($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get sequenceNumber => $_getIZ(1);
  @$pb.TagNumber(2)
  set sequenceNumber($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSequenceNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearSequenceNumber() => $_clearField(2);
}

class EcP256PublicKey extends $pb.GeneratedMessage {
  factory EcP256PublicKey({
    $core.List<$core.int>? x,
    $core.List<$core.int>? y,
  }) {
    final result = EcP256PublicKey._();
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    return result;
  }

  EcP256PublicKey._();

  factory EcP256PublicKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EcP256PublicKey()..mergeFromBuffer(data, registry);
  factory EcP256PublicKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EcP256PublicKey()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EcP256PublicKey',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.securemessage'),
      createEmptyInstance: EcP256PublicKey.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'x', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'y', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EcP256PublicKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EcP256PublicKey copyWith(void Function(EcP256PublicKey) updates) =>
      super.copyWith((message) => updates(message as EcP256PublicKey))
          as EcP256PublicKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EcP256PublicKey() / EcP256PublicKey.new instead')
  static EcP256PublicKey create() => EcP256PublicKey._();
  static $pb.GeneratedMessage $_createMessage() => EcP256PublicKey._();
  @$core.override
  EcP256PublicKey createEmptyInstance() => EcP256PublicKey._();
  @$core.pragma('dart2js:noInline')
  static EcP256PublicKey getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EcP256PublicKey>(
          EcP256PublicKey.$_createMessage);
  static EcP256PublicKey? _defaultInstance;

  /// Big-endian two's complement, so a leading zero byte may be present.
  @$pb.TagNumber(1)
  $core.List<$core.int> get x => $_getN(0);
  @$pb.TagNumber(1)
  set x($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasX() => $_has(0);
  @$pb.TagNumber(1)
  void clearX() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get y => $_getN(1);
  @$pb.TagNumber(2)
  set y($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasY() => $_has(1);
  @$pb.TagNumber(2)
  void clearY() => $_clearField(2);
}

class GenericPublicKey extends $pb.GeneratedMessage {
  factory GenericPublicKey({
    PublicKeyType? type,
    EcP256PublicKey? ecP256PublicKey,
  }) {
    final result = GenericPublicKey._();
    if (type != null) result.type = type;
    if (ecP256PublicKey != null) result.ecP256PublicKey = ecP256PublicKey;
    return result;
  }

  GenericPublicKey._();

  factory GenericPublicKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GenericPublicKey()..mergeFromBuffer(data, registry);
  factory GenericPublicKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GenericPublicKey()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GenericPublicKey',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'quickshare.securemessage'),
      createEmptyInstance: GenericPublicKey.$_createMessage)
    ..aE<PublicKeyType>(1, _omitFieldNames ? '' : 'type',
        enumValues: PublicKeyType.values)
    ..aOM<EcP256PublicKey>(2, _omitFieldNames ? '' : 'ecP256PublicKey',
        subBuilder: EcP256PublicKey.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenericPublicKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GenericPublicKey copyWith(void Function(GenericPublicKey) updates) =>
      super.copyWith((message) => updates(message as GenericPublicKey))
          as GenericPublicKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GenericPublicKey() / GenericPublicKey.new instead')
  static GenericPublicKey create() => GenericPublicKey._();
  static $pb.GeneratedMessage $_createMessage() => GenericPublicKey._();
  @$core.override
  GenericPublicKey createEmptyInstance() => GenericPublicKey._();
  @$core.pragma('dart2js:noInline')
  static GenericPublicKey getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GenericPublicKey>(
          GenericPublicKey.$_createMessage);
  static GenericPublicKey? _defaultInstance;

  @$pb.TagNumber(1)
  PublicKeyType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(PublicKeyType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  EcP256PublicKey get ecP256PublicKey => $_getN(1);
  @$pb.TagNumber(2)
  set ecP256PublicKey(EcP256PublicKey value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEcP256PublicKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearEcP256PublicKey() => $_clearField(2);
  @$pb.TagNumber(2)
  EcP256PublicKey ensureEcP256PublicKey() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
