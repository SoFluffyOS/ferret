// This is a generated file - do not edit.
//
// Generated from ferret/handoff/v1/handoff.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'handoff.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'handoff.pbenum.dart';

/// The app that can continue an activity, per platform. Empty when unknown.
class AppIdentifiers extends $pb.GeneratedMessage {
  factory AppIdentifiers({
    $core.String? androidPackage,
    $core.String? appleBundleId,
    $core.String? linuxDesktopId,
    $core.String? windowsAppId,
  }) {
    final result = AppIdentifiers._();
    if (androidPackage != null) result.androidPackage = androidPackage;
    if (appleBundleId != null) result.appleBundleId = appleBundleId;
    if (linuxDesktopId != null) result.linuxDesktopId = linuxDesktopId;
    if (windowsAppId != null) result.windowsAppId = windowsAppId;
    return result;
  }

  AppIdentifiers._();

  factory AppIdentifiers.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AppIdentifiers()..mergeFromBuffer(data, registry);
  factory AppIdentifiers.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AppIdentifiers()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AppIdentifiers',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.handoff.v1'),
      createEmptyInstance: AppIdentifiers.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'androidPackage')
    ..aOS(2, _omitFieldNames ? '' : 'appleBundleId')
    ..aOS(3, _omitFieldNames ? '' : 'linuxDesktopId')
    ..aOS(4, _omitFieldNames ? '' : 'windowsAppId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppIdentifiers clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppIdentifiers copyWith(void Function(AppIdentifiers) updates) =>
      super.copyWith((message) => updates(message as AppIdentifiers))
          as AppIdentifiers;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AppIdentifiers() / AppIdentifiers.new instead')
  static AppIdentifiers create() => AppIdentifiers._();
  static $pb.GeneratedMessage $_createMessage() => AppIdentifiers._();
  @$core.override
  AppIdentifiers createEmptyInstance() => AppIdentifiers._();
  @$core.pragma('dart2js:noInline')
  static AppIdentifiers getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AppIdentifiers>(
          AppIdentifiers.$_createMessage);
  static AppIdentifiers? _defaultInstance;

  /// Android package name, such as "org.wikipedia".
  @$pb.TagNumber(1)
  $core.String get androidPackage => $_getSZ(0);
  @$pb.TagNumber(1)
  set androidPackage($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAndroidPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearAndroidPackage() => $_clearField(1);

  /// Bundle id on macOS and iOS, such as "com.apple.Safari".
  @$pb.TagNumber(2)
  $core.String get appleBundleId => $_getSZ(1);
  @$pb.TagNumber(2)
  set appleBundleId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAppleBundleId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAppleBundleId() => $_clearField(2);

  /// Desktop entry id on Linux, such as "org.gnome.Maps.desktop".
  @$pb.TagNumber(3)
  $core.String get linuxDesktopId => $_getSZ(2);
  @$pb.TagNumber(3)
  set linuxDesktopId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLinuxDesktopId() => $_has(2);
  @$pb.TagNumber(3)
  void clearLinuxDesktopId() => $_clearField(3);

  /// AppUserModelID on Windows.
  @$pb.TagNumber(4)
  $core.String get windowsAppId => $_getSZ(3);
  @$pb.TagNumber(4)
  set windowsAppId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasWindowsAppId() => $_has(3);
  @$pb.TagNumber(4)
  void clearWindowsAppId() => $_clearField(4);
}

/// Something the user is doing that another device can continue. Shaped like
/// Android's HandoffActivityData: the activity itself, plus a web URI to fall
/// back to when the app isn't there.
class Activity extends $pb.GeneratedMessage {
  factory Activity({
    $core.String? id,
    ActivityKind? kind,
    $core.String? title,
    $core.String? uri,
    $core.String? deepLink,
    AppIdentifiers? apps,
    $core.String? fallbackWebUri,
    $core.String? text,
    $core.List<$core.int>? state,
    $core.String? stateType,
    $fixnum.Int64? createdAtMs,
    $fixnum.Int64? expiresAtMs,
    $core.String? sourceDeviceId,
    $core.String? sourceAppName,
  }) {
    final result = Activity._();
    if (id != null) result.id = id;
    if (kind != null) result.kind = kind;
    if (title != null) result.title = title;
    if (uri != null) result.uri = uri;
    if (deepLink != null) result.deepLink = deepLink;
    if (apps != null) result.apps = apps;
    if (fallbackWebUri != null) result.fallbackWebUri = fallbackWebUri;
    if (text != null) result.text = text;
    if (state != null) result.state = state;
    if (stateType != null) result.stateType = stateType;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    if (expiresAtMs != null) result.expiresAtMs = expiresAtMs;
    if (sourceDeviceId != null) result.sourceDeviceId = sourceDeviceId;
    if (sourceAppName != null) result.sourceAppName = sourceAppName;
    return result;
  }

  Activity._();

  factory Activity.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Activity()..mergeFromBuffer(data, registry);
  factory Activity.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Activity()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Activity',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.handoff.v1'),
      createEmptyInstance: Activity.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aE<ActivityKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: ActivityKind.values)
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'uri')
    ..aOS(5, _omitFieldNames ? '' : 'deepLink')
    ..aOM<AppIdentifiers>(6, _omitFieldNames ? '' : 'apps',
        subBuilder: AppIdentifiers.$_createMessage)
    ..aOS(7, _omitFieldNames ? '' : 'fallbackWebUri')
    ..aOS(8, _omitFieldNames ? '' : 'text')
    ..a<$core.List<$core.int>>(
        9, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OY)
    ..aOS(10, _omitFieldNames ? '' : 'stateType')
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'createdAtMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        12, _omitFieldNames ? '' : 'expiresAtMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(13, _omitFieldNames ? '' : 'sourceDeviceId')
    ..aOS(14, _omitFieldNames ? '' : 'sourceAppName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Activity clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Activity copyWith(void Function(Activity) updates) =>
      super.copyWith((message) => updates(message as Activity)) as Activity;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Activity() / Activity.new instead')
  static Activity create() => Activity._();
  static $pb.GeneratedMessage $_createMessage() => Activity._();
  @$core.override
  Activity createEmptyInstance() => Activity._();
  @$core.pragma('dart2js:noInline')
  static Activity getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Activity>(Activity.$_createMessage);
  static Activity? _defaultInstance;

  /// Unique per activity, chosen by the source device.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ActivityKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(ActivityKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  /// Short, human title, such as the page title.
  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  /// The main URI: http(s), geo: or mailto:.
  @$pb.TagNumber(4)
  $core.String get uri => $_getSZ(3);
  @$pb.TagNumber(4)
  set uri($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUri() => $_has(3);
  @$pb.TagNumber(4)
  void clearUri() => $_clearField(4);

  /// A URI only the app understands, opened in the app named by `apps`.
  @$pb.TagNumber(5)
  $core.String get deepLink => $_getSZ(4);
  @$pb.TagNumber(5)
  set deepLink($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeepLink() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeepLink() => $_clearField(5);

  @$pb.TagNumber(6)
  AppIdentifiers get apps => $_getN(5);
  @$pb.TagNumber(6)
  set apps(AppIdentifiers value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasApps() => $_has(5);
  @$pb.TagNumber(6)
  void clearApps() => $_clearField(6);
  @$pb.TagNumber(6)
  AppIdentifiers ensureApps() => $_ensure(5);

  /// Opened when no app can take `deep_link`.
  @$pb.TagNumber(7)
  $core.String get fallbackWebUri => $_getSZ(6);
  @$pb.TagNumber(7)
  set fallbackWebUri($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFallbackWebUri() => $_has(6);
  @$pb.TagNumber(7)
  void clearFallbackWebUri() => $_clearField(7);

  /// The text of an ACTIVITY_KIND_TEXT activity.
  @$pb.TagNumber(8)
  $core.String get text => $_getSZ(7);
  @$pb.TagNumber(8)
  set text($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasText() => $_has(7);
  @$pb.TagNumber(8)
  void clearText() => $_clearField(8);

  /// Opaque state for apps that opted in, such as scroll position. Ferret
  /// never reads it; it is handed to the app as is.
  @$pb.TagNumber(9)
  $core.List<$core.int> get state => $_getN(8);
  @$pb.TagNumber(9)
  set state($core.List<$core.int> value) => $_setBytes(8, value);
  @$pb.TagNumber(9)
  $core.bool hasState() => $_has(8);
  @$pb.TagNumber(9)
  void clearState() => $_clearField(9);

  /// What `state` holds, such as "application/ld+json" for AssistContent
  /// structured data, or a reverse-DNS name chosen by the app.
  @$pb.TagNumber(10)
  $core.String get stateType => $_getSZ(9);
  @$pb.TagNumber(10)
  set stateType($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasStateType() => $_has(9);
  @$pb.TagNumber(10)
  void clearStateType() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get createdAtMs => $_getI64(10);
  @$pb.TagNumber(11)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCreatedAtMs() => $_has(10);
  @$pb.TagNumber(11)
  void clearCreatedAtMs() => $_clearField(11);

  /// After this time the activity is stale and is not suggested any more.
  @$pb.TagNumber(12)
  $fixnum.Int64 get expiresAtMs => $_getI64(11);
  @$pb.TagNumber(12)
  set expiresAtMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasExpiresAtMs() => $_has(11);
  @$pb.TagNumber(12)
  void clearExpiresAtMs() => $_clearField(12);

  /// Device id of the device the activity comes from.
  @$pb.TagNumber(13)
  $core.String get sourceDeviceId => $_getSZ(12);
  @$pb.TagNumber(13)
  set sourceDeviceId($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasSourceDeviceId() => $_has(12);
  @$pb.TagNumber(13)
  void clearSourceDeviceId() => $_clearField(13);

  /// Name of the app it comes from, such as "Firefox", for display only.
  @$pb.TagNumber(14)
  $core.String get sourceAppName => $_getSZ(13);
  @$pb.TagNumber(14)
  set sourceAppName($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasSourceAppName() => $_has(13);
  @$pb.TagNumber(14)
  void clearSourceAppName() => $_clearField(14);
}

/// Passive: "this is what I'm doing now". Receivers keep it as a quiet
/// suggestion that expires and is replaced by the next one from the same
/// device. Sent without expecting a reply.
class PublishActivity extends $pb.GeneratedMessage {
  factory PublishActivity({
    Activity? activity,
  }) {
    final result = PublishActivity._();
    if (activity != null) result.activity = activity;
    return result;
  }

  PublishActivity._();

  factory PublishActivity.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PublishActivity()..mergeFromBuffer(data, registry);
  factory PublishActivity.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PublishActivity()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublishActivity',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.handoff.v1'),
      createEmptyInstance: PublishActivity.$_createMessage)
    ..aOM<Activity>(1, _omitFieldNames ? '' : 'activity',
        subBuilder: Activity.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishActivity clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishActivity copyWith(void Function(PublishActivity) updates) =>
      super.copyWith((message) => updates(message as PublishActivity))
          as PublishActivity;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PublishActivity() / PublishActivity.new instead')
  static PublishActivity create() => PublishActivity._();
  static $pb.GeneratedMessage $_createMessage() => PublishActivity._();
  @$core.override
  PublishActivity createEmptyInstance() => PublishActivity._();
  @$core.pragma('dart2js:noInline')
  static PublishActivity getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PublishActivity>(
          PublishActivity.$_createMessage);
  static PublishActivity? _defaultInstance;

  @$pb.TagNumber(1)
  Activity get activity => $_getN(0);
  @$pb.TagNumber(1)
  set activity(Activity value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasActivity() => $_has(0);
  @$pb.TagNumber(1)
  void clearActivity() => $_clearField(1);
  @$pb.TagNumber(1)
  Activity ensureActivity() => $_ensure(0);
}

/// Explicit: "continue this on your side now". Sent as a request; the receiver
/// answers with ContinueResult.
class ContinueActivity extends $pb.GeneratedMessage {
  factory ContinueActivity({
    Activity? activity,
  }) {
    final result = ContinueActivity._();
    if (activity != null) result.activity = activity;
    return result;
  }

  ContinueActivity._();

  factory ContinueActivity.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContinueActivity()..mergeFromBuffer(data, registry);
  factory ContinueActivity.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContinueActivity()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContinueActivity',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.handoff.v1'),
      createEmptyInstance: ContinueActivity.$_createMessage)
    ..aOM<Activity>(1, _omitFieldNames ? '' : 'activity',
        subBuilder: Activity.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContinueActivity clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContinueActivity copyWith(void Function(ContinueActivity) updates) =>
      super.copyWith((message) => updates(message as ContinueActivity))
          as ContinueActivity;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ContinueActivity() / ContinueActivity.new instead')
  static ContinueActivity create() => ContinueActivity._();
  static $pb.GeneratedMessage $_createMessage() => ContinueActivity._();
  @$core.override
  ContinueActivity createEmptyInstance() => ContinueActivity._();
  @$core.pragma('dart2js:noInline')
  static ContinueActivity getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ContinueActivity>(
          ContinueActivity.$_createMessage);
  static ContinueActivity? _defaultInstance;

  @$pb.TagNumber(1)
  Activity get activity => $_getN(0);
  @$pb.TagNumber(1)
  set activity(Activity value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasActivity() => $_has(0);
  @$pb.TagNumber(1)
  void clearActivity() => $_clearField(1);
  @$pb.TagNumber(1)
  Activity ensureActivity() => $_ensure(0);
}

class ContinueResult extends $pb.GeneratedMessage {
  factory ContinueResult({
    ContinueOutcome? outcome,
  }) {
    final result = ContinueResult._();
    if (outcome != null) result.outcome = outcome;
    return result;
  }

  ContinueResult._();

  factory ContinueResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContinueResult()..mergeFromBuffer(data, registry);
  factory ContinueResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContinueResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContinueResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.handoff.v1'),
      createEmptyInstance: ContinueResult.$_createMessage)
    ..aE<ContinueOutcome>(1, _omitFieldNames ? '' : 'outcome',
        enumValues: ContinueOutcome.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContinueResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContinueResult copyWith(void Function(ContinueResult) updates) =>
      super.copyWith((message) => updates(message as ContinueResult))
          as ContinueResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ContinueResult() / ContinueResult.new instead')
  static ContinueResult create() => ContinueResult._();
  static $pb.GeneratedMessage $_createMessage() => ContinueResult._();
  @$core.override
  ContinueResult createEmptyInstance() => ContinueResult._();
  @$core.pragma('dart2js:noInline')
  static ContinueResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ContinueResult>(
          ContinueResult.$_createMessage);
  static ContinueResult? _defaultInstance;

  @$pb.TagNumber(1)
  ContinueOutcome get outcome => $_getN(0);
  @$pb.TagNumber(1)
  set outcome(ContinueOutcome value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOutcome() => $_has(0);
  @$pb.TagNumber(1)
  void clearOutcome() => $_clearField(1);
}

/// Withdraws suggestions from the sender, such as when the page was closed.
class ClearActivity extends $pb.GeneratedMessage {
  factory ClearActivity({
    $core.String? activityId,
  }) {
    final result = ClearActivity._();
    if (activityId != null) result.activityId = activityId;
    return result;
  }

  ClearActivity._();

  factory ClearActivity.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClearActivity()..mergeFromBuffer(data, registry);
  factory ClearActivity.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClearActivity()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClearActivity',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.handoff.v1'),
      createEmptyInstance: ClearActivity.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'activityId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClearActivity clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClearActivity copyWith(void Function(ClearActivity) updates) =>
      super.copyWith((message) => updates(message as ClearActivity))
          as ClearActivity;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ClearActivity() / ClearActivity.new instead')
  static ClearActivity create() => ClearActivity._();
  static $pb.GeneratedMessage $_createMessage() => ClearActivity._();
  @$core.override
  ClearActivity createEmptyInstance() => ClearActivity._();
  @$core.pragma('dart2js:noInline')
  static ClearActivity getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClearActivity>(
          ClearActivity.$_createMessage);
  static ClearActivity? _defaultInstance;

  /// The activity to withdraw, or empty for every one from the sender.
  @$pb.TagNumber(1)
  $core.String get activityId => $_getSZ(0);
  @$pb.TagNumber(1)
  set activityId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasActivityId() => $_has(0);
  @$pb.TagNumber(1)
  void clearActivityId() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
