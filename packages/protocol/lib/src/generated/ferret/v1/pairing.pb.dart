// This is a generated file - do not edit.
//
// Generated from ferret/v1/pairing.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'device.pb.dart' as $0;
import 'pairing.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'pairing.pbenum.dart';

/// What a pairing QR code or link carries. Encoded as base64url in
/// ferret://pair?o=<offer>.
class PairingOffer extends $pb.GeneratedMessage {
  factory PairingOffer({
    $core.int? protocolVersion,
    $core.String? deviceId,
    $core.String? name,
    $0.Platform? platform,
    $core.Iterable<$core.String>? hosts,
    $core.int? port,
    $core.List<$core.int>? staticPublicKey,
    $core.List<$core.int>? secret,
    $fixnum.Int64? expiresAtMs,
  }) {
    final result = PairingOffer._();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (deviceId != null) result.deviceId = deviceId;
    if (name != null) result.name = name;
    if (platform != null) result.platform = platform;
    if (hosts != null) result.hosts.addAll(hosts);
    if (port != null) result.port = port;
    if (staticPublicKey != null) result.staticPublicKey = staticPublicKey;
    if (secret != null) result.secret = secret;
    if (expiresAtMs != null) result.expiresAtMs = expiresAtMs;
    return result;
  }

  PairingOffer._();

  factory PairingOffer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingOffer()..mergeFromBuffer(data, registry);
  factory PairingOffer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingOffer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingOffer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: PairingOffer.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'protocolVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aE<$0.Platform>(4, _omitFieldNames ? '' : 'platform',
        enumValues: $0.Platform.values)
    ..pPS(5, _omitFieldNames ? '' : 'hosts')
    ..aI(6, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'staticPublicKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'secret', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        9, _omitFieldNames ? '' : 'expiresAtMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingOffer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingOffer copyWith(void Function(PairingOffer) updates) =>
      super.copyWith((message) => updates(message as PairingOffer))
          as PairingOffer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairingOffer() / PairingOffer.new instead')
  static PairingOffer create() => PairingOffer._();
  static $pb.GeneratedMessage $_createMessage() => PairingOffer._();
  @$core.override
  PairingOffer createEmptyInstance() => PairingOffer._();
  @$core.pragma('dart2js:noInline')
  static PairingOffer getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairingOffer>(
          PairingOffer.$_createMessage);
  static PairingOffer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get protocolVersion => $_getIZ(0);
  @$pb.TagNumber(1)
  set protocolVersion($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Platform get platform => $_getN(3);
  @$pb.TagNumber(4)
  set platform($0.Platform value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPlatform() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlatform() => $_clearField(4);

  /// Addresses the offering device listens on, such as "192.168.1.20".
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get hosts => $_getList(4);

  @$pb.TagNumber(6)
  $core.int get port => $_getIZ(5);
  @$pb.TagNumber(6)
  set port($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPort() => $_has(5);
  @$pb.TagNumber(6)
  void clearPort() => $_clearField(6);

  /// X25519 static public key, 32 bytes. The scanner checks the Noise
  /// handshake's remote static key against it.
  @$pb.TagNumber(7)
  $core.List<$core.int> get staticPublicKey => $_getN(6);
  @$pb.TagNumber(7)
  set staticPublicKey($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasStaticPublicKey() => $_has(6);
  @$pb.TagNumber(7)
  void clearStaticPublicKey() => $_clearField(7);

  /// One-time secret, 16 bytes, proving the scanner saw this offer.
  @$pb.TagNumber(8)
  $core.List<$core.int> get secret => $_getN(7);
  @$pb.TagNumber(8)
  set secret($core.List<$core.int> value) => $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSecret() => $_has(7);
  @$pb.TagNumber(8)
  void clearSecret() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get expiresAtMs => $_getI64(8);
  @$pb.TagNumber(9)
  set expiresAtMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasExpiresAtMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearExpiresAtMs() => $_clearField(9);
}

/// Sent by the device that wants to pair, first thing on a new channel
/// (feature "pairing").
class PairingRequest extends $pb.GeneratedMessage {
  factory PairingRequest({
    $0.DeviceInfo? device,
    $core.List<$core.int>? proof,
  }) {
    final result = PairingRequest._();
    if (device != null) result.device = device;
    if (proof != null) result.proof = proof;
    return result;
  }

  PairingRequest._();

  factory PairingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingRequest()..mergeFromBuffer(data, registry);
  factory PairingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: PairingRequest.$_createMessage)
    ..aOM<$0.DeviceInfo>(1, _omitFieldNames ? '' : 'device',
        subBuilder: $0.DeviceInfo.$_createMessage)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'proof', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingRequest copyWith(void Function(PairingRequest) updates) =>
      super.copyWith((message) => updates(message as PairingRequest))
          as PairingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairingRequest() / PairingRequest.new instead')
  static PairingRequest create() => PairingRequest._();
  static $pb.GeneratedMessage $_createMessage() => PairingRequest._();
  @$core.override
  PairingRequest createEmptyInstance() => PairingRequest._();
  @$core.pragma('dart2js:noInline')
  static PairingRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairingRequest>(
          PairingRequest.$_createMessage);
  static PairingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.DeviceInfo get device => $_getN(0);
  @$pb.TagNumber(1)
  set device($0.DeviceInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDevice() => $_has(0);
  @$pb.TagNumber(1)
  void clearDevice() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.DeviceInfo ensureDevice() => $_ensure(0);

  /// HMAC-SHA256(offer secret, handshake hash) when pairing from an offer.
  /// Empty when pairing by comparing codes.
  @$pb.TagNumber(2)
  $core.List<$core.int> get proof => $_getN(1);
  @$pb.TagNumber(2)
  set proof($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProof() => $_has(1);
  @$pb.TagNumber(2)
  void clearProof() => $_clearField(2);
}

/// The answer to a PairingRequest (feature "pairing").
class PairingResponse extends $pb.GeneratedMessage {
  factory PairingResponse({
    PairingResult? result,
    $0.DeviceInfo? device,
    $core.List<$core.int>? proof,
  }) {
    final result$ = PairingResponse._();
    if (result != null) result$.result = result;
    if (device != null) result$.device = device;
    if (proof != null) result$.proof = proof;
    return result$;
  }

  PairingResponse._();

  factory PairingResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingResponse()..mergeFromBuffer(data, registry);
  factory PairingResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: PairingResponse.$_createMessage)
    ..aE<PairingResult>(1, _omitFieldNames ? '' : 'result',
        enumValues: PairingResult.values)
    ..aOM<$0.DeviceInfo>(2, _omitFieldNames ? '' : 'device',
        subBuilder: $0.DeviceInfo.$_createMessage)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'proof', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingResponse copyWith(void Function(PairingResponse) updates) =>
      super.copyWith((message) => updates(message as PairingResponse))
          as PairingResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairingResponse() / PairingResponse.new instead')
  static PairingResponse create() => PairingResponse._();
  static $pb.GeneratedMessage $_createMessage() => PairingResponse._();
  @$core.override
  PairingResponse createEmptyInstance() => PairingResponse._();
  @$core.pragma('dart2js:noInline')
  static PairingResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairingResponse>(
          PairingResponse.$_createMessage);
  static PairingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  PairingResult get result => $_getN(0);
  @$pb.TagNumber(1)
  set result(PairingResult value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.DeviceInfo get device => $_getN(1);
  @$pb.TagNumber(2)
  set device($0.DeviceInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDevice() => $_has(1);
  @$pb.TagNumber(2)
  void clearDevice() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.DeviceInfo ensureDevice() => $_ensure(1);

  /// HMAC-SHA256(offer secret, handshake hash || "response") so the scanner
  /// knows the offerer still holds the secret.
  @$pb.TagNumber(3)
  $core.List<$core.int> get proof => $_getN(2);
  @$pb.TagNumber(3)
  set proof($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProof() => $_has(2);
  @$pb.TagNumber(3)
  void clearProof() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
