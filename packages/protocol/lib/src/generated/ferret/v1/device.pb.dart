// This is a generated file - do not edit.
//
// Generated from ferret/v1/device.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'device.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'device.pbenum.dart';

/// What a device says about itself after the secure channel is up.
class DeviceInfo extends $pb.GeneratedMessage {
  factory DeviceInfo({
    $core.String? id,
    $core.String? name,
    Platform? platform,
    FormFactor? formFactor,
    $core.String? model,
    $core.String? appVersion,
    $core.int? protocolVersion,
  }) {
    final result = DeviceInfo._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (platform != null) result.platform = platform;
    if (formFactor != null) result.formFactor = formFactor;
    if (model != null) result.model = model;
    if (appVersion != null) result.appVersion = appVersion;
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    return result;
  }

  DeviceInfo._();

  factory DeviceInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeviceInfo()..mergeFromBuffer(data, registry);
  factory DeviceInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeviceInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: DeviceInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aE<Platform>(3, _omitFieldNames ? '' : 'platform',
        enumValues: Platform.values)
    ..aE<FormFactor>(4, _omitFieldNames ? '' : 'formFactor',
        enumValues: FormFactor.values)
    ..aOS(5, _omitFieldNames ? '' : 'model')
    ..aOS(6, _omitFieldNames ? '' : 'appVersion')
    ..aI(7, _omitFieldNames ? '' : 'protocolVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceInfo copyWith(void Function(DeviceInfo) updates) =>
      super.copyWith((message) => updates(message as DeviceInfo)) as DeviceInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeviceInfo() / DeviceInfo.new instead')
  static DeviceInfo create() => DeviceInfo._();
  static $pb.GeneratedMessage $_createMessage() => DeviceInfo._();
  @$core.override
  DeviceInfo createEmptyInstance() => DeviceInfo._();
  @$core.pragma('dart2js:noInline')
  static DeviceInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceInfo>(DeviceInfo.$_createMessage);
  static DeviceInfo? _defaultInstance;

  /// Stable id derived from the device's static public key (see spec/identity.md).
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
  Platform get platform => $_getN(2);
  @$pb.TagNumber(3)
  set platform(Platform value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPlatform() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlatform() => $_clearField(3);

  @$pb.TagNumber(4)
  FormFactor get formFactor => $_getN(3);
  @$pb.TagNumber(4)
  set formFactor(FormFactor value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasFormFactor() => $_has(3);
  @$pb.TagNumber(4)
  void clearFormFactor() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get model => $_getSZ(4);
  @$pb.TagNumber(5)
  set model($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasModel() => $_has(4);
  @$pb.TagNumber(5)
  void clearModel() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get appVersion => $_getSZ(5);
  @$pb.TagNumber(6)
  set appVersion($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAppVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearAppVersion() => $_clearField(6);

  /// Highest protocol version the device speaks.
  @$pb.TagNumber(7)
  $core.int get protocolVersion => $_getIZ(6);
  @$pb.TagNumber(7)
  set protocolVersion($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProtocolVersion() => $_has(6);
  @$pb.TagNumber(7)
  void clearProtocolVersion() => $_clearField(7);
}

/// A feature a device offers, with the feature's own version.
class FeatureSupport extends $pb.GeneratedMessage {
  factory FeatureSupport({
    $core.String? id,
    $core.int? version,
    $core.Iterable<$core.String>? flags,
  }) {
    final result = FeatureSupport._();
    if (id != null) result.id = id;
    if (version != null) result.version = version;
    if (flags != null) result.flags.addAll(flags);
    return result;
  }

  FeatureSupport._();

  factory FeatureSupport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FeatureSupport()..mergeFromBuffer(data, registry);
  factory FeatureSupport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FeatureSupport()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FeatureSupport',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: FeatureSupport.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aI(2, _omitFieldNames ? '' : 'version', fieldType: $pb.PbFieldType.OU3)
    ..pPS(3, _omitFieldNames ? '' : 'flags')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeatureSupport clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeatureSupport copyWith(void Function(FeatureSupport) updates) =>
      super.copyWith((message) => updates(message as FeatureSupport))
          as FeatureSupport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FeatureSupport() / FeatureSupport.new instead')
  static FeatureSupport create() => FeatureSupport._();
  static $pb.GeneratedMessage $_createMessage() => FeatureSupport._();
  @$core.override
  FeatureSupport createEmptyInstance() => FeatureSupport._();
  @$core.pragma('dart2js:noInline')
  static FeatureSupport getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FeatureSupport>(
          FeatureSupport.$_createMessage);
  static FeatureSupport? _defaultInstance;

  /// Feature id, such as "handoff" or "clipboard".
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get version => $_getIZ(1);
  @$pb.TagNumber(2)
  set version($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  /// Feature-specific flags, such as "send" and "receive".
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get flags => $_getList(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
