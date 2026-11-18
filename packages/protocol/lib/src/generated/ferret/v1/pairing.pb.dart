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
    $core.List<$core.int>? commitment,
    $core.Iterable<$core.String>? alsoDevices,
  }) {
    final result = PairingRequest._();
    if (device != null) result.device = device;
    if (proof != null) result.proof = proof;
    if (commitment != null) result.commitment = commitment;
    if (alsoDevices != null) result.alsoDevices.addAll(alsoDevices);
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
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'commitment', $pb.PbFieldType.OY)
    ..pPS(4, _omitFieldNames ? '' : 'alsoDevices')
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

  /// SHA-256 of the requester's nonce, when pairing by comparing codes. It
  /// fixes the nonce before the answerer picks its own, so neither side can
  /// steer the six digits (see PairingChallenge).
  @$pb.TagNumber(3)
  $core.List<$core.int> get commitment => $_getN(2);
  @$pb.TagNumber(3)
  set commitment($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCommitment() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommitment() => $_clearField(3);

  /// Names of the requester's other devices, which the answerer will be
  /// connected to as well (see Introduce). Shown on the answerer's prompt.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get alsoDevices => $_getList(3);
}

/// Pairing by comparing codes, step 2: the answerer's 16-byte nonce, sent once
/// it holds the requester's commitment (feature "pairing").
class PairingChallenge extends $pb.GeneratedMessage {
  factory PairingChallenge({
    $core.List<$core.int>? nonce,
  }) {
    final result = PairingChallenge._();
    if (nonce != null) result.nonce = nonce;
    return result;
  }

  PairingChallenge._();

  factory PairingChallenge.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingChallenge()..mergeFromBuffer(data, registry);
  factory PairingChallenge.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingChallenge()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingChallenge',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: PairingChallenge.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingChallenge clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingChallenge copyWith(void Function(PairingChallenge) updates) =>
      super.copyWith((message) => updates(message as PairingChallenge))
          as PairingChallenge;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairingChallenge() / PairingChallenge.new instead')
  static PairingChallenge create() => PairingChallenge._();
  static $pb.GeneratedMessage $_createMessage() => PairingChallenge._();
  @$core.override
  PairingChallenge createEmptyInstance() => PairingChallenge._();
  @$core.pragma('dart2js:noInline')
  static PairingChallenge getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairingChallenge>(
          PairingChallenge.$_createMessage);
  static PairingChallenge? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get nonce => $_getN(0);
  @$pb.TagNumber(1)
  set nonce($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNonce() => $_has(0);
  @$pb.TagNumber(1)
  void clearNonce() => $_clearField(1);
}

/// Pairing by comparing codes, step 3: the requester's 16-byte nonce, which
/// must hash to its commitment (feature "pairing"). Both sides then show
/// HMAC-SHA256(handshake hash, "ferret-compare" || requester nonce ||
/// answerer nonce) as six digits.
class PairingReveal extends $pb.GeneratedMessage {
  factory PairingReveal({
    $core.List<$core.int>? nonce,
  }) {
    final result = PairingReveal._();
    if (nonce != null) result.nonce = nonce;
    return result;
  }

  PairingReveal._();

  factory PairingReveal.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingReveal()..mergeFromBuffer(data, registry);
  factory PairingReveal.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingReveal()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingReveal',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: PairingReveal.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingReveal clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingReveal copyWith(void Function(PairingReveal) updates) =>
      super.copyWith((message) => updates(message as PairingReveal))
          as PairingReveal;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairingReveal() / PairingReveal.new instead')
  static PairingReveal create() => PairingReveal._();
  static $pb.GeneratedMessage $_createMessage() => PairingReveal._();
  @$core.override
  PairingReveal createEmptyInstance() => PairingReveal._();
  @$core.pragma('dart2js:noInline')
  static PairingReveal getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairingReveal>(
          PairingReveal.$_createMessage);
  static PairingReveal? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get nonce => $_getN(0);
  @$pb.TagNumber(1)
  set nonce($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNonce() => $_has(0);
  @$pb.TagNumber(1)
  void clearNonce() => $_clearField(1);
}

/// Pairing by comparing codes: what the requester's user said after seeing
/// the six digits (feature "pairing"). The answerer trusts the requester only
/// after its own user agreed and this arrived with accepted = true.
class PairingConfirm extends $pb.GeneratedMessage {
  factory PairingConfirm({
    $core.bool? accepted,
  }) {
    final result = PairingConfirm._();
    if (accepted != null) result.accepted = accepted;
    return result;
  }

  PairingConfirm._();

  factory PairingConfirm.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingConfirm()..mergeFromBuffer(data, registry);
  factory PairingConfirm.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingConfirm()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingConfirm',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: PairingConfirm.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'accepted')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingConfirm clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingConfirm copyWith(void Function(PairingConfirm) updates) =>
      super.copyWith((message) => updates(message as PairingConfirm))
          as PairingConfirm;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairingConfirm() / PairingConfirm.new instead')
  static PairingConfirm create() => PairingConfirm._();
  static $pb.GeneratedMessage $_createMessage() => PairingConfirm._();
  @$core.override
  PairingConfirm createEmptyInstance() => PairingConfirm._();
  @$core.pragma('dart2js:noInline')
  static PairingConfirm getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairingConfirm>(
          PairingConfirm.$_createMessage);
  static PairingConfirm? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get accepted => $_getBF(0);
  @$pb.TagNumber(1)
  set accepted($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAccepted() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccepted() => $_clearField(1);
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

/// Tells a paired device about the sender's other paired devices, so one
/// pairing joins them all (feature "pairing", on a trusted session only).
/// The session's Noise handshake proves who sends it; a device accepts it
/// only from a device it already trusts, and only while its user lets
/// pairings be shared. Devices that don't know the message ignore it.
class Introduce extends $pb.GeneratedMessage {
  factory Introduce({
    $core.Iterable<IntroducedDevice>? devices,
    $core.Iterable<ForgottenDevice>? forgotten,
  }) {
    final result = Introduce._();
    if (devices != null) result.devices.addAll(devices);
    if (forgotten != null) result.forgotten.addAll(forgotten);
    return result;
  }

  Introduce._();

  factory Introduce.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Introduce()..mergeFromBuffer(data, registry);
  factory Introduce.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Introduce()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Introduce',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: Introduce.$_createMessage)
    ..pPM<IntroducedDevice>(1, _omitFieldNames ? '' : 'devices',
        subBuilder: IntroducedDevice.$_createMessage)
    ..pPM<ForgottenDevice>(2, _omitFieldNames ? '' : 'forgotten',
        subBuilder: ForgottenDevice.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Introduce clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Introduce copyWith(void Function(Introduce) updates) =>
      super.copyWith((message) => updates(message as Introduce)) as Introduce;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Introduce() / Introduce.new instead')
  static Introduce create() => Introduce._();
  static $pb.GeneratedMessage $_createMessage() => Introduce._();
  @$core.override
  Introduce createEmptyInstance() => Introduce._();
  @$core.pragma('dart2js:noInline')
  static Introduce getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Introduce>(Introduce.$_createMessage);
  static Introduce? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<IntroducedDevice> get devices => $_getList(0);

  /// Devices the user removed from all their devices.
  @$pb.TagNumber(2)
  $pb.PbList<ForgottenDevice> get forgotten => $_getList(1);
}

/// One device the sender trusts.
class IntroducedDevice extends $pb.GeneratedMessage {
  factory IntroducedDevice({
    $core.String? id,
    $core.String? name,
    $0.Platform? platform,
    $0.FormFactor? formFactor,
    $core.List<$core.int>? staticPublicKey,
    $core.String? host,
    $core.int? port,
    $fixnum.Int64? pairedAtMs,
  }) {
    final result = IntroducedDevice._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (platform != null) result.platform = platform;
    if (formFactor != null) result.formFactor = formFactor;
    if (staticPublicKey != null) result.staticPublicKey = staticPublicKey;
    if (host != null) result.host = host;
    if (port != null) result.port = port;
    if (pairedAtMs != null) result.pairedAtMs = pairedAtMs;
    return result;
  }

  IntroducedDevice._();

  factory IntroducedDevice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IntroducedDevice()..mergeFromBuffer(data, registry);
  factory IntroducedDevice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IntroducedDevice()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IntroducedDevice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: IntroducedDevice.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aE<$0.Platform>(3, _omitFieldNames ? '' : 'platform',
        enumValues: $0.Platform.values)
    ..aE<$0.FormFactor>(4, _omitFieldNames ? '' : 'formFactor',
        enumValues: $0.FormFactor.values)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'staticPublicKey', $pb.PbFieldType.OY)
    ..aOS(6, _omitFieldNames ? '' : 'host')
    ..aI(7, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        8, _omitFieldNames ? '' : 'pairedAtMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntroducedDevice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntroducedDevice copyWith(void Function(IntroducedDevice) updates) =>
      super.copyWith((message) => updates(message as IntroducedDevice))
          as IntroducedDevice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use IntroducedDevice() / IntroducedDevice.new instead')
  static IntroducedDevice create() => IntroducedDevice._();
  static $pb.GeneratedMessage $_createMessage() => IntroducedDevice._();
  @$core.override
  IntroducedDevice createEmptyInstance() => IntroducedDevice._();
  @$core.pragma('dart2js:noInline')
  static IntroducedDevice getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IntroducedDevice>(
          IntroducedDevice.$_createMessage);
  static IntroducedDevice? _defaultInstance;

  /// Must be the id derived from static_public_key, or the entry is dropped.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Platform get platform => $_getN(2);
  @$pb.TagNumber(3)
  set platform($0.Platform value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPlatform() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlatform() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.FormFactor get formFactor => $_getN(3);
  @$pb.TagNumber(4)
  set formFactor($0.FormFactor value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasFormFactor() => $_has(3);
  @$pb.TagNumber(4)
  void clearFormFactor() => $_clearField(4);

  /// X25519 static public key, 32 bytes. The receiver trusts exactly this key.
  @$pb.TagNumber(5)
  $core.List<$core.int> get staticPublicKey => $_getN(4);
  @$pb.TagNumber(5)
  set staticPublicKey($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStaticPublicKey() => $_has(4);
  @$pb.TagNumber(5)
  void clearStaticPublicKey() => $_clearField(5);

  /// Where the sender last reached the device, to connect without waiting
  /// for discovery. May be empty.
  @$pb.TagNumber(6)
  $core.String get host => $_getSZ(5);
  @$pb.TagNumber(6)
  set host($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHost() => $_has(5);
  @$pb.TagNumber(6)
  void clearHost() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get port => $_getIZ(6);
  @$pb.TagNumber(7)
  set port($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPort() => $_has(6);
  @$pb.TagNumber(7)
  void clearPort() => $_clearField(7);

  /// When the user paired the device, passed along unchanged. An entry older
  /// than the receiver's record of forgetting the device is dropped.
  @$pb.TagNumber(8)
  $fixnum.Int64 get pairedAtMs => $_getI64(7);
  @$pb.TagNumber(8)
  set pairedAtMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPairedAtMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearPairedAtMs() => $_clearField(8);
}

/// A device to stop trusting, with when the user removed it.
class ForgottenDevice extends $pb.GeneratedMessage {
  factory ForgottenDevice({
    $core.String? id,
    $fixnum.Int64? forgottenAtMs,
  }) {
    final result = ForgottenDevice._();
    if (id != null) result.id = id;
    if (forgottenAtMs != null) result.forgottenAtMs = forgottenAtMs;
    return result;
  }

  ForgottenDevice._();

  factory ForgottenDevice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ForgottenDevice()..mergeFromBuffer(data, registry);
  factory ForgottenDevice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ForgottenDevice()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ForgottenDevice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: ForgottenDevice.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'forgottenAtMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForgottenDevice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForgottenDevice copyWith(void Function(ForgottenDevice) updates) =>
      super.copyWith((message) => updates(message as ForgottenDevice))
          as ForgottenDevice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ForgottenDevice() / ForgottenDevice.new instead')
  static ForgottenDevice create() => ForgottenDevice._();
  static $pb.GeneratedMessage $_createMessage() => ForgottenDevice._();
  @$core.override
  ForgottenDevice createEmptyInstance() => ForgottenDevice._();
  @$core.pragma('dart2js:noInline')
  static ForgottenDevice getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ForgottenDevice>(
          ForgottenDevice.$_createMessage);
  static ForgottenDevice? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get forgottenAtMs => $_getI64(1);
  @$pb.TagNumber(2)
  set forgottenAtMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasForgottenAtMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearForgottenAtMs() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
