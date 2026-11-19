// This is a generated file - do not edit.
//
// Generated from ferret/notifications/v1/notifications.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'notifications.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'notifications.pbenum.dart';

/// A button on a notification, such as "Reply" or "Mark as read".
class NotificationAction extends $pb.GeneratedMessage {
  factory NotificationAction({
    $core.String? id,
    $core.String? title,
    $core.bool? isReply,
  }) {
    final result = NotificationAction._();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (isReply != null) result.isReply = isReply;
    return result;
  }

  NotificationAction._();

  factory NotificationAction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotificationAction()..mergeFromBuffer(data, registry);
  factory NotificationAction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotificationAction()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NotificationAction',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: NotificationAction.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOB(3, _omitFieldNames ? '' : 'isReply')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotificationAction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotificationAction copyWith(void Function(NotificationAction) updates) =>
      super.copyWith((message) => updates(message as NotificationAction))
          as NotificationAction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NotificationAction() / NotificationAction.new instead')
  static NotificationAction create() => NotificationAction._();
  static $pb.GeneratedMessage $_createMessage() => NotificationAction._();
  @$core.override
  NotificationAction createEmptyInstance() => NotificationAction._();
  @$core.pragma('dart2js:noInline')
  static NotificationAction getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NotificationAction>(
          NotificationAction.$_createMessage);
  static NotificationAction? _defaultInstance;

  /// Chosen by the source device; send it back in `InvokeAction`.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  /// The action takes typed text, such as a message reply.
  @$pb.TagNumber(3)
  $core.bool get isReply => $_getBF(2);
  @$pb.TagNumber(3)
  set isReply($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsReply() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsReply() => $_clearField(3);
}

/// One notification shown on the source device (a phone).
class NotificationItem extends $pb.GeneratedMessage {
  factory NotificationItem({
    $core.String? key,
    $core.String? appPackage,
    $core.String? appName,
    $core.String? title,
    $core.String? text,
    $fixnum.Int64? postedAtMs,
    $core.List<$core.int>? appIconPng,
    $core.bool? isConversation,
    $core.Iterable<NotificationAction>? actions,
    $core.bool? textHidden,
  }) {
    final result = NotificationItem._();
    if (key != null) result.key = key;
    if (appPackage != null) result.appPackage = appPackage;
    if (appName != null) result.appName = appName;
    if (title != null) result.title = title;
    if (text != null) result.text = text;
    if (postedAtMs != null) result.postedAtMs = postedAtMs;
    if (appIconPng != null) result.appIconPng = appIconPng;
    if (isConversation != null) result.isConversation = isConversation;
    if (actions != null) result.actions.addAll(actions);
    if (textHidden != null) result.textHidden = textHidden;
    return result;
  }

  NotificationItem._();

  factory NotificationItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotificationItem()..mergeFromBuffer(data, registry);
  factory NotificationItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotificationItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NotificationItem',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: NotificationItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'appPackage')
    ..aOS(3, _omitFieldNames ? '' : 'appName')
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..aOS(5, _omitFieldNames ? '' : 'text')
    ..aInt64(6, _omitFieldNames ? '' : 'postedAtMs')
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'appIconPng', $pb.PbFieldType.OY)
    ..aOB(8, _omitFieldNames ? '' : 'isConversation')
    ..pPM<NotificationAction>(9, _omitFieldNames ? '' : 'actions',
        subBuilder: NotificationAction.$_createMessage)
    ..aOB(10, _omitFieldNames ? '' : 'textHidden')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotificationItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotificationItem copyWith(void Function(NotificationItem) updates) =>
      super.copyWith((message) => updates(message as NotificationItem))
          as NotificationItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NotificationItem() / NotificationItem.new instead')
  static NotificationItem create() => NotificationItem._();
  static $pb.GeneratedMessage $_createMessage() => NotificationItem._();
  @$core.override
  NotificationItem createEmptyInstance() => NotificationItem._();
  @$core.pragma('dart2js:noInline')
  static NotificationItem getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NotificationItem>(
          NotificationItem.$_createMessage);
  static NotificationItem? _defaultInstance;

  /// The source's own key for it. Posting the same key again updates it.
  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  /// The app that posted it, such as "org.thoughtcrime.securesms".
  @$pb.TagNumber(2)
  $core.String get appPackage => $_getSZ(1);
  @$pb.TagNumber(2)
  set appPackage($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAppPackage() => $_has(1);
  @$pb.TagNumber(2)
  void clearAppPackage() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get appName => $_getSZ(2);
  @$pb.TagNumber(3)
  set appName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAppName() => $_has(2);
  @$pb.TagNumber(3)
  void clearAppName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get text => $_getSZ(4);
  @$pb.TagNumber(5)
  set text($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasText() => $_has(4);
  @$pb.TagNumber(5)
  void clearText() => $_clearField(5);

  /// When the source posted it, in the source device's clock.
  @$pb.TagNumber(6)
  $fixnum.Int64 get postedAtMs => $_getI64(5);
  @$pb.TagNumber(6)
  set postedAtMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPostedAtMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearPostedAtMs() => $_clearField(6);

  /// A small PNG of the app's icon. Empty when it was already sent for this
  /// app during the current session; receivers keep the last one per app.
  @$pb.TagNumber(7)
  $core.List<$core.int> get appIconPng => $_getN(6);
  @$pb.TagNumber(7)
  set appIconPng($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAppIconPng() => $_has(6);
  @$pb.TagNumber(7)
  void clearAppIconPng() => $_clearField(7);

  /// A message in a conversation, such as a chat.
  @$pb.TagNumber(8)
  $core.bool get isConversation => $_getBF(7);
  @$pb.TagNumber(8)
  set isConversation($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIsConversation() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsConversation() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<NotificationAction> get actions => $_getList(8);

  /// The source held back the text (and a title that carried it) because it
  /// looks like a one-time code, such as a sign-in or bank code. Receivers
  /// say so instead of showing an empty line.
  @$pb.TagNumber(10)
  $core.bool get textHidden => $_getBF(9);
  @$pb.TagNumber(10)
  set textHidden($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasTextHidden() => $_has(9);
  @$pb.TagNumber(10)
  void clearTextHidden() => $_clearField(10);
}

/// A new or updated notification. Sent without expecting a reply, only for
/// notifications posted after the session opened.
class NotificationPosted extends $pb.GeneratedMessage {
  factory NotificationPosted({
    NotificationItem? notification,
  }) {
    final result = NotificationPosted._();
    if (notification != null) result.notification = notification;
    return result;
  }

  NotificationPosted._();

  factory NotificationPosted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotificationPosted()..mergeFromBuffer(data, registry);
  factory NotificationPosted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotificationPosted()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NotificationPosted',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: NotificationPosted.$_createMessage)
    ..aOM<NotificationItem>(1, _omitFieldNames ? '' : 'notification',
        subBuilder: NotificationItem.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotificationPosted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotificationPosted copyWith(void Function(NotificationPosted) updates) =>
      super.copyWith((message) => updates(message as NotificationPosted))
          as NotificationPosted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NotificationPosted() / NotificationPosted.new instead')
  static NotificationPosted create() => NotificationPosted._();
  static $pb.GeneratedMessage $_createMessage() => NotificationPosted._();
  @$core.override
  NotificationPosted createEmptyInstance() => NotificationPosted._();
  @$core.pragma('dart2js:noInline')
  static NotificationPosted getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NotificationPosted>(
          NotificationPosted.$_createMessage);
  static NotificationPosted? _defaultInstance;

  @$pb.TagNumber(1)
  NotificationItem get notification => $_getN(0);
  @$pb.TagNumber(1)
  set notification(NotificationItem value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasNotification() => $_has(0);
  @$pb.TagNumber(1)
  void clearNotification() => $_clearField(1);
  @$pb.TagNumber(1)
  NotificationItem ensureNotification() => $_ensure(0);
}

/// The notification with `key` is gone on the source. Sent without expecting a
/// reply.
class NotificationRemoved extends $pb.GeneratedMessage {
  factory NotificationRemoved({
    $core.String? key,
  }) {
    final result = NotificationRemoved._();
    if (key != null) result.key = key;
    return result;
  }

  NotificationRemoved._();

  factory NotificationRemoved.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotificationRemoved()..mergeFromBuffer(data, registry);
  factory NotificationRemoved.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotificationRemoved()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NotificationRemoved',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: NotificationRemoved.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotificationRemoved clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotificationRemoved copyWith(void Function(NotificationRemoved) updates) =>
      super.copyWith((message) => updates(message as NotificationRemoved))
          as NotificationRemoved;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use NotificationRemoved() / NotificationRemoved.new instead')
  static NotificationRemoved create() => NotificationRemoved._();
  static $pb.GeneratedMessage $_createMessage() => NotificationRemoved._();
  @$core.override
  NotificationRemoved createEmptyInstance() => NotificationRemoved._();
  @$core.pragma('dart2js:noInline')
  static NotificationRemoved getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NotificationRemoved>(
          NotificationRemoved.$_createMessage);
  static NotificationRemoved? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);
}

/// Sent by the source right after a session opens, instead of replaying what
/// happened while the receiver was away.
class CatchUp extends $pb.GeneratedMessage {
  factory CatchUp({
    $core.int? missedCount,
    $core.Iterable<$core.String>? activeKeys,
    $core.Iterable<$core.String>? missedAppNames,
  }) {
    final result = CatchUp._();
    if (missedCount != null) result.missedCount = missedCount;
    if (activeKeys != null) result.activeKeys.addAll(activeKeys);
    if (missedAppNames != null) result.missedAppNames.addAll(missedAppNames);
    return result;
  }

  CatchUp._();

  factory CatchUp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CatchUp()..mergeFromBuffer(data, registry);
  factory CatchUp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CatchUp()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CatchUp',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: CatchUp.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'missedCount',
        fieldType: $pb.PbFieldType.OU3)
    ..pPS(2, _omitFieldNames ? '' : 'activeKeys')
    ..pPS(3, _omitFieldNames ? '' : 'missedAppNames')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CatchUp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CatchUp copyWith(void Function(CatchUp) updates) =>
      super.copyWith((message) => updates(message as CatchUp)) as CatchUp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CatchUp() / CatchUp.new instead')
  static CatchUp create() => CatchUp._();
  static $pb.GeneratedMessage $_createMessage() => CatchUp._();
  @$core.override
  CatchUp createEmptyInstance() => CatchUp._();
  @$core.pragma('dart2js:noInline')
  static CatchUp getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CatchUp>(CatchUp.$_createMessage);
  static CatchUp? _defaultInstance;

  /// Notifications posted while the receiver was away and still showing.
  @$pb.TagNumber(1)
  $core.int get missedCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set missedCount($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMissedCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearMissedCount() => $_clearField(1);

  /// Keys of notifications sent earlier that are still showing on the source.
  /// Receivers drop the ones not listed.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get activeKeys => $_getList(1);

  /// Names of the apps the missed notifications came from, without repeats.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get missedAppNames => $_getList(2);
}

/// Asks the source to run an action of a notification. Expects an
/// `InvokeActionResult` reply.
class InvokeAction extends $pb.GeneratedMessage {
  factory InvokeAction({
    $core.String? key,
    $core.String? actionId,
    $core.String? replyText,
  }) {
    final result = InvokeAction._();
    if (key != null) result.key = key;
    if (actionId != null) result.actionId = actionId;
    if (replyText != null) result.replyText = replyText;
    return result;
  }

  InvokeAction._();

  factory InvokeAction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InvokeAction()..mergeFromBuffer(data, registry);
  factory InvokeAction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InvokeAction()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InvokeAction',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: InvokeAction.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'actionId')
    ..aOS(3, _omitFieldNames ? '' : 'replyText')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvokeAction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvokeAction copyWith(void Function(InvokeAction) updates) =>
      super.copyWith((message) => updates(message as InvokeAction))
          as InvokeAction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use InvokeAction() / InvokeAction.new instead')
  static InvokeAction create() => InvokeAction._();
  static $pb.GeneratedMessage $_createMessage() => InvokeAction._();
  @$core.override
  InvokeAction createEmptyInstance() => InvokeAction._();
  @$core.pragma('dart2js:noInline')
  static InvokeAction getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InvokeAction>(
          InvokeAction.$_createMessage);
  static InvokeAction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get actionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set actionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasActionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearActionId() => $_clearField(2);

  /// The typed text for a reply action.
  @$pb.TagNumber(3)
  $core.String get replyText => $_getSZ(2);
  @$pb.TagNumber(3)
  set replyText($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReplyText() => $_has(2);
  @$pb.TagNumber(3)
  void clearReplyText() => $_clearField(3);
}

class InvokeActionResult extends $pb.GeneratedMessage {
  factory InvokeActionResult({
    $core.bool? ok,
  }) {
    final result = InvokeActionResult._();
    if (ok != null) result.ok = ok;
    return result;
  }

  InvokeActionResult._();

  factory InvokeActionResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InvokeActionResult()..mergeFromBuffer(data, registry);
  factory InvokeActionResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InvokeActionResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InvokeActionResult',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: InvokeActionResult.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvokeActionResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvokeActionResult copyWith(void Function(InvokeActionResult) updates) =>
      super.copyWith((message) => updates(message as InvokeActionResult))
          as InvokeActionResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use InvokeActionResult() / InvokeActionResult.new instead')
  static InvokeActionResult create() => InvokeActionResult._();
  static $pb.GeneratedMessage $_createMessage() => InvokeActionResult._();
  @$core.override
  InvokeActionResult createEmptyInstance() => InvokeActionResult._();
  @$core.pragma('dart2js:noInline')
  static InvokeActionResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InvokeActionResult>(
          InvokeActionResult.$_createMessage);
  static InvokeActionResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);
}

/// Dismisses the notification with `key` on the source. Sent without expecting
/// a reply; the source answers with `NotificationRemoved` once it is gone.
class DismissNotification extends $pb.GeneratedMessage {
  factory DismissNotification({
    $core.String? key,
  }) {
    final result = DismissNotification._();
    if (key != null) result.key = key;
    return result;
  }

  DismissNotification._();

  factory DismissNotification.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DismissNotification()..mergeFromBuffer(data, registry);
  factory DismissNotification.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DismissNotification()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DismissNotification',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: DismissNotification.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DismissNotification clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DismissNotification copyWith(void Function(DismissNotification) updates) =>
      super.copyWith((message) => updates(message as DismissNotification))
          as DismissNotification;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use DismissNotification() / DismissNotification.new instead')
  static DismissNotification create() => DismissNotification._();
  static $pb.GeneratedMessage $_createMessage() => DismissNotification._();
  @$core.override
  DismissNotification createEmptyInstance() => DismissNotification._();
  @$core.pragma('dart2js:noInline')
  static DismissNotification getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DismissNotification>(
          DismissNotification.$_createMessage);
  static DismissNotification? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);
}

/// How the source mirrors notifications.
class MirrorSettings extends $pb.GeneratedMessage {
  factory MirrorSettings({
    $core.bool? enabled,
    $core.bool? accessGranted,
    $core.bool? skipWhileUsing,
    $core.Iterable<$core.String>? allowedPackages,
    AppFilter? appFilter,
    $core.Iterable<$core.String>? excludedPackages,
  }) {
    final result = MirrorSettings._();
    if (enabled != null) result.enabled = enabled;
    if (accessGranted != null) result.accessGranted = accessGranted;
    if (skipWhileUsing != null) result.skipWhileUsing = skipWhileUsing;
    if (allowedPackages != null) result.allowedPackages.addAll(allowedPackages);
    if (appFilter != null) result.appFilter = appFilter;
    if (excludedPackages != null)
      result.excludedPackages.addAll(excludedPackages);
    return result;
  }

  MirrorSettings._();

  factory MirrorSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MirrorSettings()..mergeFromBuffer(data, registry);
  factory MirrorSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MirrorSettings()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MirrorSettings',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: MirrorSettings.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOB(2, _omitFieldNames ? '' : 'accessGranted')
    ..aOB(3, _omitFieldNames ? '' : 'skipWhileUsing')
    ..pPS(4, _omitFieldNames ? '' : 'allowedPackages')
    ..aE<AppFilter>(5, _omitFieldNames ? '' : 'appFilter',
        enumValues: AppFilter.values)
    ..pPS(6, _omitFieldNames ? '' : 'excludedPackages')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MirrorSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MirrorSettings copyWith(void Function(MirrorSettings) updates) =>
      super.copyWith((message) => updates(message as MirrorSettings))
          as MirrorSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MirrorSettings() / MirrorSettings.new instead')
  static MirrorSettings create() => MirrorSettings._();
  static $pb.GeneratedMessage $_createMessage() => MirrorSettings._();
  @$core.override
  MirrorSettings createEmptyInstance() => MirrorSettings._();
  @$core.pragma('dart2js:noInline')
  static MirrorSettings getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MirrorSettings>(
          MirrorSettings.$_createMessage);
  static MirrorSettings? _defaultInstance;

  /// The person turned mirroring on.
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  /// The platform lets the source read notifications.
  @$pb.TagNumber(2)
  $core.bool get accessGranted => $_getBF(1);
  @$pb.TagNumber(2)
  set accessGranted($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccessGranted() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccessGranted() => $_clearField(2);

  /// Mirroring pauses while the source is in use (screen on and unlocked).
  @$pb.TagNumber(3)
  $core.bool get skipWhileUsing => $_getBF(2);
  @$pb.TagNumber(3)
  set skipWhileUsing($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSkipWhileUsing() => $_has(2);
  @$pb.TagNumber(3)
  void clearSkipWhileUsing() => $_clearField(3);

  /// The apps picked for `APP_FILTER_ONLY`. Kept while another filter is
  /// active, so switching back restores them.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get allowedPackages => $_getList(3);

  /// Which apps are mirrored.
  @$pb.TagNumber(5)
  AppFilter get appFilter => $_getN(4);
  @$pb.TagNumber(5)
  set appFilter(AppFilter value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAppFilter() => $_has(4);
  @$pb.TagNumber(5)
  void clearAppFilter() => $_clearField(5);

  /// The apps muted for `APP_FILTER_ALL_EXCEPT`. Kept while another filter is
  /// active.
  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get excludedPackages => $_getList(5);
}

/// Asks the source for its `MirrorSettings`. Expects a `MirrorSettings` reply.
class MirrorSettingsRequest extends $pb.GeneratedMessage {
  factory MirrorSettingsRequest() => MirrorSettingsRequest._();

  MirrorSettingsRequest._();

  factory MirrorSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MirrorSettingsRequest()..mergeFromBuffer(data, registry);
  factory MirrorSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MirrorSettingsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MirrorSettingsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: MirrorSettingsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MirrorSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MirrorSettingsRequest copyWith(
          void Function(MirrorSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as MirrorSettingsRequest))
          as MirrorSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use MirrorSettingsRequest() / MirrorSettingsRequest.new instead')
  static MirrorSettingsRequest create() => MirrorSettingsRequest._();
  static $pb.GeneratedMessage $_createMessage() => MirrorSettingsRequest._();
  @$core.override
  MirrorSettingsRequest createEmptyInstance() => MirrorSettingsRequest._();
  @$core.pragma('dart2js:noInline')
  static MirrorSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MirrorSettingsRequest>(
          MirrorSettingsRequest.$_createMessage);
  static MirrorSettingsRequest? _defaultInstance;
}

/// An app the person can pick in the app list.
class AppEntry extends $pb.GeneratedMessage {
  factory AppEntry({
    $core.String? package,
    $core.String? name,
    $core.List<$core.int>? iconPng,
    $core.bool? allowed,
    $core.bool? isMessaging,
    $fixnum.Int64? lastPostedMs,
  }) {
    final result = AppEntry._();
    if (package != null) result.package = package;
    if (name != null) result.name = name;
    if (iconPng != null) result.iconPng = iconPng;
    if (allowed != null) result.allowed = allowed;
    if (isMessaging != null) result.isMessaging = isMessaging;
    if (lastPostedMs != null) result.lastPostedMs = lastPostedMs;
    return result;
  }

  AppEntry._();

  factory AppEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AppEntry()..mergeFromBuffer(data, registry);
  factory AppEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AppEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AppEntry',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: AppEntry.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'package')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'iconPng', $pb.PbFieldType.OY)
    ..aOB(4, _omitFieldNames ? '' : 'allowed')
    ..aOB(5, _omitFieldNames ? '' : 'isMessaging')
    ..aInt64(6, _omitFieldNames ? '' : 'lastPostedMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppEntry copyWith(void Function(AppEntry) updates) =>
      super.copyWith((message) => updates(message as AppEntry)) as AppEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AppEntry() / AppEntry.new instead')
  static AppEntry create() => AppEntry._();
  static $pb.GeneratedMessage $_createMessage() => AppEntry._();
  @$core.override
  AppEntry createEmptyInstance() => AppEntry._();
  @$core.pragma('dart2js:noInline')
  static AppEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AppEntry>(AppEntry.$_createMessage);
  static AppEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get package => $_getSZ(0);
  @$pb.TagNumber(1)
  set package($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackage() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  /// A small PNG of the app's icon.
  @$pb.TagNumber(3)
  $core.List<$core.int> get iconPng => $_getN(2);
  @$pb.TagNumber(3)
  set iconPng($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIconPng() => $_has(2);
  @$pb.TagNumber(3)
  void clearIconPng() => $_clearField(3);

  /// Its notifications are mirrored under the current filter.
  @$pb.TagNumber(4)
  $core.bool get allowed => $_getBF(3);
  @$pb.TagNumber(4)
  set allowed($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAllowed() => $_has(3);
  @$pb.TagNumber(4)
  void clearAllowed() => $_clearField(4);

  /// A messaging app, such as Signal or WhatsApp.
  @$pb.TagNumber(5)
  $core.bool get isMessaging => $_getBF(4);
  @$pb.TagNumber(5)
  set isMessaging($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsMessaging() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsMessaging() => $_clearField(5);

  /// When the app last posted a notification the source saw, in the source
  /// device's clock. 0 when unknown.
  @$pb.TagNumber(6)
  $fixnum.Int64 get lastPostedMs => $_getI64(5);
  @$pb.TagNumber(6)
  set lastPostedMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLastPostedMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastPostedMs() => $_clearField(6);
}

/// Asks the source for its apps. Expects an `AppListResponse` reply.
class AppListRequest extends $pb.GeneratedMessage {
  factory AppListRequest() => AppListRequest._();

  AppListRequest._();

  factory AppListRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AppListRequest()..mergeFromBuffer(data, registry);
  factory AppListRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AppListRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AppListRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: AppListRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppListRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppListRequest copyWith(void Function(AppListRequest) updates) =>
      super.copyWith((message) => updates(message as AppListRequest))
          as AppListRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AppListRequest() / AppListRequest.new instead')
  static AppListRequest create() => AppListRequest._();
  static $pb.GeneratedMessage $_createMessage() => AppListRequest._();
  @$core.override
  AppListRequest createEmptyInstance() => AppListRequest._();
  @$core.pragma('dart2js:noInline')
  static AppListRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AppListRequest>(
          AppListRequest.$_createMessage);
  static AppListRequest? _defaultInstance;
}

class AppListResponse extends $pb.GeneratedMessage {
  factory AppListResponse({
    $core.Iterable<AppEntry>? apps,
  }) {
    final result = AppListResponse._();
    if (apps != null) result.apps.addAll(apps);
    return result;
  }

  AppListResponse._();

  factory AppListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AppListResponse()..mergeFromBuffer(data, registry);
  factory AppListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AppListResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AppListResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: AppListResponse.$_createMessage)
    ..pPM<AppEntry>(1, _omitFieldNames ? '' : 'apps',
        subBuilder: AppEntry.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppListResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppListResponse copyWith(void Function(AppListResponse) updates) =>
      super.copyWith((message) => updates(message as AppListResponse))
          as AppListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AppListResponse() / AppListResponse.new instead')
  static AppListResponse create() => AppListResponse._();
  static $pb.GeneratedMessage $_createMessage() => AppListResponse._();
  @$core.override
  AppListResponse createEmptyInstance() => AppListResponse._();
  @$core.pragma('dart2js:noInline')
  static AppListResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AppListResponse>(
          AppListResponse.$_createMessage);
  static AppListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<AppEntry> get apps => $_getList(0);
}

/// Turns one app on or off: under `APP_FILTER_ALL_EXCEPT` it changes
/// `excluded_packages`, under `APP_FILTER_ONLY` `allowed_packages`. Turning an
/// app off under `APP_FILTER_ALL` switches to `APP_FILTER_ALL_EXCEPT`.
class AppChoice extends $pb.GeneratedMessage {
  factory AppChoice({
    $core.String? package,
    $core.bool? allowed,
  }) {
    final result = AppChoice._();
    if (package != null) result.package = package;
    if (allowed != null) result.allowed = allowed;
    return result;
  }

  AppChoice._();

  factory AppChoice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AppChoice()..mergeFromBuffer(data, registry);
  factory AppChoice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AppChoice()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AppChoice',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: AppChoice.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'package')
    ..aOB(2, _omitFieldNames ? '' : 'allowed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppChoice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppChoice copyWith(void Function(AppChoice) updates) =>
      super.copyWith((message) => updates(message as AppChoice)) as AppChoice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AppChoice() / AppChoice.new instead')
  static AppChoice create() => AppChoice._();
  static $pb.GeneratedMessage $_createMessage() => AppChoice._();
  @$core.override
  AppChoice createEmptyInstance() => AppChoice._();
  @$core.pragma('dart2js:noInline')
  static AppChoice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AppChoice>(AppChoice.$_createMessage);
  static AppChoice? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get package => $_getSZ(0);
  @$pb.TagNumber(1)
  set package($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackage() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get allowed => $_getBF(1);
  @$pb.TagNumber(2)
  set allowed($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAllowed() => $_has(1);
  @$pb.TagNumber(2)
  void clearAllowed() => $_clearField(2);
}

/// Changes the source's settings. Expects a `MirrorSettings` reply.
class UpdateMirrorSettings extends $pb.GeneratedMessage {
  factory UpdateMirrorSettings({
    $core.Iterable<AppChoice>? apps,
    $core.bool? skipWhileUsing,
    AppFilter? appFilter,
  }) {
    final result = UpdateMirrorSettings._();
    if (apps != null) result.apps.addAll(apps);
    if (skipWhileUsing != null) result.skipWhileUsing = skipWhileUsing;
    if (appFilter != null) result.appFilter = appFilter;
    return result;
  }

  UpdateMirrorSettings._();

  factory UpdateMirrorSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateMirrorSettings()..mergeFromBuffer(data, registry);
  factory UpdateMirrorSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateMirrorSettings()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateMirrorSettings',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.notifications.v1'),
      createEmptyInstance: UpdateMirrorSettings.$_createMessage)
    ..pPM<AppChoice>(1, _omitFieldNames ? '' : 'apps',
        subBuilder: AppChoice.$_createMessage)
    ..aOB(2, _omitFieldNames ? '' : 'skipWhileUsing')
    ..aE<AppFilter>(3, _omitFieldNames ? '' : 'appFilter',
        enumValues: AppFilter.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateMirrorSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateMirrorSettings copyWith(void Function(UpdateMirrorSettings) updates) =>
      super.copyWith((message) => updates(message as UpdateMirrorSettings))
          as UpdateMirrorSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UpdateMirrorSettings() / UpdateMirrorSettings.new instead')
  static UpdateMirrorSettings create() => UpdateMirrorSettings._();
  static $pb.GeneratedMessage $_createMessage() => UpdateMirrorSettings._();
  @$core.override
  UpdateMirrorSettings createEmptyInstance() => UpdateMirrorSettings._();
  @$core.pragma('dart2js:noInline')
  static UpdateMirrorSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateMirrorSettings>(
          UpdateMirrorSettings.$_createMessage);
  static UpdateMirrorSettings? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<AppChoice> get apps => $_getList(0);

  /// Left out to keep the current value.
  @$pb.TagNumber(2)
  $core.bool get skipWhileUsing => $_getBF(1);
  @$pb.TagNumber(2)
  set skipWhileUsing($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSkipWhileUsing() => $_has(1);
  @$pb.TagNumber(2)
  void clearSkipWhileUsing() => $_clearField(2);

  /// Applied before `apps`. Left out to keep the current filter.
  @$pb.TagNumber(3)
  AppFilter get appFilter => $_getN(2);
  @$pb.TagNumber(3)
  set appFilter(AppFilter value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAppFilter() => $_has(2);
  @$pb.TagNumber(3)
  void clearAppFilter() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
