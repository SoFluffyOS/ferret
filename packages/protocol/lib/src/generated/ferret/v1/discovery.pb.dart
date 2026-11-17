// This is a generated file - do not edit.
//
// Generated from ferret/v1/discovery.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'device.pbenum.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Sent over UDP multicast so devices on the same network find each other.
/// It carries no secrets: anyone on the network can read it.
class Announce extends $pb.GeneratedMessage {
  factory Announce({
    $core.int? protocolVersion,
    $core.String? deviceId,
    $core.String? name,
    $0.Platform? platform,
    $0.FormFactor? formFactor,
    $core.int? port,
    $core.bool? reply,
  }) {
    final result = Announce._();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (deviceId != null) result.deviceId = deviceId;
    if (name != null) result.name = name;
    if (platform != null) result.platform = platform;
    if (formFactor != null) result.formFactor = formFactor;
    if (port != null) result.port = port;
    if (reply != null) result.reply = reply;
    return result;
  }

  Announce._();

  factory Announce.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Announce()..mergeFromBuffer(data, registry);
  factory Announce.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Announce()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Announce',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: Announce.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'protocolVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aE<$0.Platform>(4, _omitFieldNames ? '' : 'platform',
        enumValues: $0.Platform.values)
    ..aE<$0.FormFactor>(5, _omitFieldNames ? '' : 'formFactor',
        enumValues: $0.FormFactor.values)
    ..aI(6, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..aOB(7, _omitFieldNames ? '' : 'reply')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Announce clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Announce copyWith(void Function(Announce) updates) =>
      super.copyWith((message) => updates(message as Announce)) as Announce;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Announce() / Announce.new instead')
  static Announce create() => Announce._();
  static $pb.GeneratedMessage $_createMessage() => Announce._();
  @$core.override
  Announce createEmptyInstance() => Announce._();
  @$core.pragma('dart2js:noInline')
  static Announce getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Announce>(Announce.$_createMessage);
  static Announce? _defaultInstance;

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

  @$pb.TagNumber(5)
  $0.FormFactor get formFactor => $_getN(4);
  @$pb.TagNumber(5)
  set formFactor($0.FormFactor value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasFormFactor() => $_has(4);
  @$pb.TagNumber(5)
  void clearFormFactor() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get port => $_getIZ(5);
  @$pb.TagNumber(6)
  set port($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPort() => $_has(5);
  @$pb.TagNumber(6)
  void clearPort() => $_clearField(6);

  /// True when this is an answer to someone else's announce, so it is not
  /// answered again.
  @$pb.TagNumber(7)
  $core.bool get reply => $_getBF(6);
  @$pb.TagNumber(7)
  set reply($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReply() => $_has(6);
  @$pb.TagNumber(7)
  void clearReply() => $_clearField(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
