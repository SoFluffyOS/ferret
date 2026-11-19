// This is a generated file - do not edit.
//
// Generated from ferret/v1/wake.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'wake.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'wake.pbenum.dart';

/// How to wake a computer from sleep with a Wake-on-LAN magic packet. A
/// computer shares it only with its paired devices (feature "wake"), when a
/// session opens and again when its network cards change. A MAC address
/// identifies the computer, so it never goes anywhere else.
class WakeInfo extends $pb.GeneratedMessage {
  factory WakeInfo({
    $core.Iterable<WakeInterface>? interfaces,
  }) {
    final result = WakeInfo._();
    if (interfaces != null) result.interfaces.addAll(interfaces);
    return result;
  }

  WakeInfo._();

  factory WakeInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WakeInfo()..mergeFromBuffer(data, registry);
  factory WakeInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WakeInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WakeInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: WakeInfo.$_createMessage)
    ..pPM<WakeInterface>(1, _omitFieldNames ? '' : 'interfaces',
        subBuilder: WakeInterface.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WakeInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WakeInfo copyWith(void Function(WakeInfo) updates) =>
      super.copyWith((message) => updates(message as WakeInfo)) as WakeInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WakeInfo() / WakeInfo.new instead')
  static WakeInfo create() => WakeInfo._();
  static $pb.GeneratedMessage $_createMessage() => WakeInfo._();
  @$core.override
  WakeInfo createEmptyInstance() => WakeInfo._();
  @$core.pragma('dart2js:noInline')
  static WakeInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WakeInfo>(WakeInfo.$_createMessage);
  static WakeInfo? _defaultInstance;

  /// Its wired and Wi-Fi network cards that have an IPv4 address, wired
  /// first. Virtual cards (VPNs, bridges, containers) are left out.
  @$pb.TagNumber(1)
  $pb.PbList<WakeInterface> get interfaces => $_getList(0);
}

/// One network card a computer can be woken through.
class WakeInterface extends $pb.GeneratedMessage {
  factory WakeInterface({
    $core.List<$core.int>? mac,
    $core.String? address,
    $core.String? broadcast,
    WakeLink? link,
    WakeSetting? setting,
  }) {
    final result = WakeInterface._();
    if (mac != null) result.mac = mac;
    if (address != null) result.address = address;
    if (broadcast != null) result.broadcast = broadcast;
    if (link != null) result.link = link;
    if (setting != null) result.setting = setting;
    return result;
  }

  WakeInterface._();

  factory WakeInterface.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WakeInterface()..mergeFromBuffer(data, registry);
  factory WakeInterface.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WakeInterface()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WakeInterface',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ferret.v1'),
      createEmptyInstance: WakeInterface.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'mac', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'address')
    ..aOS(3, _omitFieldNames ? '' : 'broadcast')
    ..aE<WakeLink>(4, _omitFieldNames ? '' : 'link',
        enumValues: WakeLink.values)
    ..aE<WakeSetting>(5, _omitFieldNames ? '' : 'setting',
        enumValues: WakeSetting.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WakeInterface clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WakeInterface copyWith(void Function(WakeInterface) updates) =>
      super.copyWith((message) => updates(message as WakeInterface))
          as WakeInterface;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WakeInterface() / WakeInterface.new instead')
  static WakeInterface create() => WakeInterface._();
  static $pb.GeneratedMessage $_createMessage() => WakeInterface._();
  @$core.override
  WakeInterface createEmptyInstance() => WakeInterface._();
  @$core.pragma('dart2js:noInline')
  static WakeInterface getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WakeInterface>(
          WakeInterface.$_createMessage);
  static WakeInterface? _defaultInstance;

  /// Hardware (MAC) address, 6 bytes.
  @$pb.TagNumber(1)
  $core.List<$core.int> get mac => $_getN(0);
  @$pb.TagNumber(1)
  set mac($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMac() => $_has(0);
  @$pb.TagNumber(1)
  void clearMac() => $_clearField(1);

  /// Its IPv4 address on that network, such as "192.168.1.20".
  @$pb.TagNumber(2)
  $core.String get address => $_getSZ(1);
  @$pb.TagNumber(2)
  set address($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAddress() => $_has(1);
  @$pb.TagNumber(2)
  void clearAddress() => $_clearField(2);

  /// That network's broadcast address, such as "192.168.1.255".
  @$pb.TagNumber(3)
  $core.String get broadcast => $_getSZ(2);
  @$pb.TagNumber(3)
  set broadcast($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBroadcast() => $_has(2);
  @$pb.TagNumber(3)
  void clearBroadcast() => $_clearField(3);

  @$pb.TagNumber(4)
  WakeLink get link => $_getN(3);
  @$pb.TagNumber(4)
  set link(WakeLink value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLink() => $_has(3);
  @$pb.TagNumber(4)
  void clearLink() => $_clearField(4);

  /// Whether the card is set to wake on a magic packet, when the computer
  /// can tell.
  @$pb.TagNumber(5)
  WakeSetting get setting => $_getN(4);
  @$pb.TagNumber(5)
  set setting(WakeSetting value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSetting() => $_has(4);
  @$pb.TagNumber(5)
  void clearSetting() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
