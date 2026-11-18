// This is a generated file - do not edit.
//
// Generated from quickshare/ukey2.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'ukey2.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'ukey2.pbenum.dart';

class Ukey2Message extends $pb.GeneratedMessage {
  factory Ukey2Message({
    Ukey2Message_Type? messageType,
    $core.List<$core.int>? messageData,
  }) {
    final result = Ukey2Message._();
    if (messageType != null) result.messageType = messageType;
    if (messageData != null) result.messageData = messageData;
    return result;
  }

  Ukey2Message._();

  factory Ukey2Message.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ukey2Message()..mergeFromBuffer(data, registry);
  factory Ukey2Message.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ukey2Message()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ukey2Message',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.ukey2'),
      createEmptyInstance: Ukey2Message.$_createMessage)
    ..aE<Ukey2Message_Type>(1, _omitFieldNames ? '' : 'messageType',
        enumValues: Ukey2Message_Type.values)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'messageData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ukey2Message clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ukey2Message copyWith(void Function(Ukey2Message) updates) =>
      super.copyWith((message) => updates(message as Ukey2Message))
          as Ukey2Message;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Ukey2Message() / Ukey2Message.new instead')
  static Ukey2Message create() => Ukey2Message._();
  static $pb.GeneratedMessage $_createMessage() => Ukey2Message._();
  @$core.override
  Ukey2Message createEmptyInstance() => Ukey2Message._();
  @$core.pragma('dart2js:noInline')
  static Ukey2Message getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Ukey2Message>(
          Ukey2Message.$_createMessage);
  static Ukey2Message? _defaultInstance;

  @$pb.TagNumber(1)
  Ukey2Message_Type get messageType => $_getN(0);
  @$pb.TagNumber(1)
  set messageType(Ukey2Message_Type value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageType() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageType() => $_clearField(1);

  /// One of the messages below, serialized, depending on message_type.
  @$pb.TagNumber(2)
  $core.List<$core.int> get messageData => $_getN(1);
  @$pb.TagNumber(2)
  set messageData($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageData() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageData() => $_clearField(2);
}

class Ukey2Alert extends $pb.GeneratedMessage {
  factory Ukey2Alert({
    Ukey2Alert_AlertType? type,
    $core.String? errorMessage,
  }) {
    final result = Ukey2Alert._();
    if (type != null) result.type = type;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  Ukey2Alert._();

  factory Ukey2Alert.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ukey2Alert()..mergeFromBuffer(data, registry);
  factory Ukey2Alert.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ukey2Alert()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ukey2Alert',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.ukey2'),
      createEmptyInstance: Ukey2Alert.$_createMessage)
    ..aE<Ukey2Alert_AlertType>(1, _omitFieldNames ? '' : 'type',
        enumValues: Ukey2Alert_AlertType.values)
    ..aOS(2, _omitFieldNames ? '' : 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ukey2Alert clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ukey2Alert copyWith(void Function(Ukey2Alert) updates) =>
      super.copyWith((message) => updates(message as Ukey2Alert)) as Ukey2Alert;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Ukey2Alert() / Ukey2Alert.new instead')
  static Ukey2Alert create() => Ukey2Alert._();
  static $pb.GeneratedMessage $_createMessage() => Ukey2Alert._();
  @$core.override
  Ukey2Alert createEmptyInstance() => Ukey2Alert._();
  @$core.pragma('dart2js:noInline')
  static Ukey2Alert getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Ukey2Alert>(Ukey2Alert.$_createMessage);
  static Ukey2Alert? _defaultInstance;

  @$pb.TagNumber(1)
  Ukey2Alert_AlertType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(Ukey2Alert_AlertType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errorMessage => $_getSZ(1);
  @$pb.TagNumber(2)
  set errorMessage($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrorMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrorMessage() => $_clearField(2);
}

class Ukey2ClientInit_CipherCommitment extends $pb.GeneratedMessage {
  factory Ukey2ClientInit_CipherCommitment({
    Ukey2HandshakeCipher? handshakeCipher,
    $core.List<$core.int>? commitment,
  }) {
    final result = Ukey2ClientInit_CipherCommitment._();
    if (handshakeCipher != null) result.handshakeCipher = handshakeCipher;
    if (commitment != null) result.commitment = commitment;
    return result;
  }

  Ukey2ClientInit_CipherCommitment._();

  factory Ukey2ClientInit_CipherCommitment.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ukey2ClientInit_CipherCommitment()..mergeFromBuffer(data, registry);
  factory Ukey2ClientInit_CipherCommitment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ukey2ClientInit_CipherCommitment()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ukey2ClientInit.CipherCommitment',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.ukey2'),
      createEmptyInstance: Ukey2ClientInit_CipherCommitment.$_createMessage)
    ..aE<Ukey2HandshakeCipher>(1, _omitFieldNames ? '' : 'handshakeCipher',
        enumValues: Ukey2HandshakeCipher.values)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'commitment', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ukey2ClientInit_CipherCommitment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ukey2ClientInit_CipherCommitment copyWith(
          void Function(Ukey2ClientInit_CipherCommitment) updates) =>
      super.copyWith(
              (message) => updates(message as Ukey2ClientInit_CipherCommitment))
          as Ukey2ClientInit_CipherCommitment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use Ukey2ClientInit_CipherCommitment() / Ukey2ClientInit_CipherCommitment.new instead')
  static Ukey2ClientInit_CipherCommitment create() =>
      Ukey2ClientInit_CipherCommitment._();
  static $pb.GeneratedMessage $_createMessage() =>
      Ukey2ClientInit_CipherCommitment._();
  @$core.override
  Ukey2ClientInit_CipherCommitment createEmptyInstance() =>
      Ukey2ClientInit_CipherCommitment._();
  @$core.pragma('dart2js:noInline')
  static Ukey2ClientInit_CipherCommitment getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Ukey2ClientInit_CipherCommitment>(
          Ukey2ClientInit_CipherCommitment.$_createMessage);
  static Ukey2ClientInit_CipherCommitment? _defaultInstance;

  @$pb.TagNumber(1)
  Ukey2HandshakeCipher get handshakeCipher => $_getN(0);
  @$pb.TagNumber(1)
  set handshakeCipher(Ukey2HandshakeCipher value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHandshakeCipher() => $_has(0);
  @$pb.TagNumber(1)
  void clearHandshakeCipher() => $_clearField(1);

  /// SHA-512 of the Ukey2Message that will carry the client's finish.
  @$pb.TagNumber(2)
  $core.List<$core.int> get commitment => $_getN(1);
  @$pb.TagNumber(2)
  set commitment($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommitment() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommitment() => $_clearField(2);
}

class Ukey2ClientInit extends $pb.GeneratedMessage {
  factory Ukey2ClientInit({
    $core.int? version,
    $core.List<$core.int>? random,
    $core.Iterable<Ukey2ClientInit_CipherCommitment>? cipherCommitments,
    $core.String? nextProtocol,
  }) {
    final result = Ukey2ClientInit._();
    if (version != null) result.version = version;
    if (random != null) result.random = random;
    if (cipherCommitments != null)
      result.cipherCommitments.addAll(cipherCommitments);
    if (nextProtocol != null) result.nextProtocol = nextProtocol;
    return result;
  }

  Ukey2ClientInit._();

  factory Ukey2ClientInit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ukey2ClientInit()..mergeFromBuffer(data, registry);
  factory Ukey2ClientInit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ukey2ClientInit()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ukey2ClientInit',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.ukey2'),
      createEmptyInstance: Ukey2ClientInit.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'version')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'random', $pb.PbFieldType.OY)
    ..pPM<Ukey2ClientInit_CipherCommitment>(
        3, _omitFieldNames ? '' : 'cipherCommitments',
        subBuilder: Ukey2ClientInit_CipherCommitment.$_createMessage)
    ..aOS(4, _omitFieldNames ? '' : 'nextProtocol')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ukey2ClientInit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ukey2ClientInit copyWith(void Function(Ukey2ClientInit) updates) =>
      super.copyWith((message) => updates(message as Ukey2ClientInit))
          as Ukey2ClientInit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Ukey2ClientInit() / Ukey2ClientInit.new instead')
  static Ukey2ClientInit create() => Ukey2ClientInit._();
  static $pb.GeneratedMessage $_createMessage() => Ukey2ClientInit._();
  @$core.override
  Ukey2ClientInit createEmptyInstance() => Ukey2ClientInit._();
  @$core.pragma('dart2js:noInline')
  static Ukey2ClientInit getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Ukey2ClientInit>(
          Ukey2ClientInit.$_createMessage);
  static Ukey2ClientInit? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get random => $_getN(1);
  @$pb.TagNumber(2)
  set random($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRandom() => $_has(1);
  @$pb.TagNumber(2)
  void clearRandom() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Ukey2ClientInit_CipherCommitment> get cipherCommitments =>
      $_getList(2);

  @$pb.TagNumber(4)
  $core.String get nextProtocol => $_getSZ(3);
  @$pb.TagNumber(4)
  set nextProtocol($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNextProtocol() => $_has(3);
  @$pb.TagNumber(4)
  void clearNextProtocol() => $_clearField(4);
}

class Ukey2ServerInit extends $pb.GeneratedMessage {
  factory Ukey2ServerInit({
    $core.int? version,
    $core.List<$core.int>? random,
    Ukey2HandshakeCipher? handshakeCipher,
    $core.List<$core.int>? publicKey,
  }) {
    final result = Ukey2ServerInit._();
    if (version != null) result.version = version;
    if (random != null) result.random = random;
    if (handshakeCipher != null) result.handshakeCipher = handshakeCipher;
    if (publicKey != null) result.publicKey = publicKey;
    return result;
  }

  Ukey2ServerInit._();

  factory Ukey2ServerInit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ukey2ServerInit()..mergeFromBuffer(data, registry);
  factory Ukey2ServerInit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ukey2ServerInit()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ukey2ServerInit',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.ukey2'),
      createEmptyInstance: Ukey2ServerInit.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'version')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'random', $pb.PbFieldType.OY)
    ..aE<Ukey2HandshakeCipher>(3, _omitFieldNames ? '' : 'handshakeCipher',
        enumValues: Ukey2HandshakeCipher.values)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'publicKey', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ukey2ServerInit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ukey2ServerInit copyWith(void Function(Ukey2ServerInit) updates) =>
      super.copyWith((message) => updates(message as Ukey2ServerInit))
          as Ukey2ServerInit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Ukey2ServerInit() / Ukey2ServerInit.new instead')
  static Ukey2ServerInit create() => Ukey2ServerInit._();
  static $pb.GeneratedMessage $_createMessage() => Ukey2ServerInit._();
  @$core.override
  Ukey2ServerInit createEmptyInstance() => Ukey2ServerInit._();
  @$core.pragma('dart2js:noInline')
  static Ukey2ServerInit getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Ukey2ServerInit>(
          Ukey2ServerInit.$_createMessage);
  static Ukey2ServerInit? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get random => $_getN(1);
  @$pb.TagNumber(2)
  set random($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRandom() => $_has(1);
  @$pb.TagNumber(2)
  void clearRandom() => $_clearField(2);

  @$pb.TagNumber(3)
  Ukey2HandshakeCipher get handshakeCipher => $_getN(2);
  @$pb.TagNumber(3)
  set handshakeCipher(Ukey2HandshakeCipher value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasHandshakeCipher() => $_has(2);
  @$pb.TagNumber(3)
  void clearHandshakeCipher() => $_clearField(3);

  /// A serialized GenericPublicKey.
  @$pb.TagNumber(4)
  $core.List<$core.int> get publicKey => $_getN(3);
  @$pb.TagNumber(4)
  set publicKey($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPublicKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearPublicKey() => $_clearField(4);
}

class Ukey2ClientFinished extends $pb.GeneratedMessage {
  factory Ukey2ClientFinished({
    $core.List<$core.int>? publicKey,
  }) {
    final result = Ukey2ClientFinished._();
    if (publicKey != null) result.publicKey = publicKey;
    return result;
  }

  Ukey2ClientFinished._();

  factory Ukey2ClientFinished.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ukey2ClientFinished()..mergeFromBuffer(data, registry);
  factory Ukey2ClientFinished.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ukey2ClientFinished()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ukey2ClientFinished',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'quickshare.ukey2'),
      createEmptyInstance: Ukey2ClientFinished.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'publicKey', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ukey2ClientFinished clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ukey2ClientFinished copyWith(void Function(Ukey2ClientFinished) updates) =>
      super.copyWith((message) => updates(message as Ukey2ClientFinished))
          as Ukey2ClientFinished;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use Ukey2ClientFinished() / Ukey2ClientFinished.new instead')
  static Ukey2ClientFinished create() => Ukey2ClientFinished._();
  static $pb.GeneratedMessage $_createMessage() => Ukey2ClientFinished._();
  @$core.override
  Ukey2ClientFinished createEmptyInstance() => Ukey2ClientFinished._();
  @$core.pragma('dart2js:noInline')
  static Ukey2ClientFinished getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Ukey2ClientFinished>(
          Ukey2ClientFinished.$_createMessage);
  static Ukey2ClientFinished? _defaultInstance;

  /// A serialized GenericPublicKey.
  @$pb.TagNumber(1)
  $core.List<$core.int> get publicKey => $_getN(0);
  @$pb.TagNumber(1)
  set publicKey($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPublicKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearPublicKey() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
