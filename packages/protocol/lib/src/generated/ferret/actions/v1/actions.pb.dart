// This is a generated file - do not edit.
//
// Generated from ferret/actions/v1/actions.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'actions.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'actions.pbenum.dart';

/// Something a computer can do when a paired device asks.
class Action extends $pb.GeneratedMessage {
  factory Action({
    $core.String? id,
    ActionKind? kind,
    $core.String? title,
    $core.bool? confirm,
  }) {
    final result = Action._();
    if (id != null) result.id = id;
    if (kind != null) result.kind = kind;
    if (title != null) result.title = title;
    if (confirm != null) result.confirm = confirm;
    return result;
  }

  Action._();

  factory Action.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Action()..mergeFromBuffer(data, registry);
  factory Action.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Action()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Action',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.actions.v1'),
      createEmptyInstance: Action.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aE<ActionKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: ActionKind.values)
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOB(4, _omitFieldNames ? '' : 'confirm')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Action clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Action copyWith(void Function(Action) updates) =>
      super.copyWith((message) => updates(message as Action)) as Action;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Action() / Action.new instead')
  static Action create() => Action._();
  static $pb.GeneratedMessage $_createMessage() => Action._();
  @$core.override
  Action createEmptyInstance() => Action._();
  @$core.pragma('dart2js:noInline')
  static Action getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Action>(Action.$_createMessage);
  static Action? _defaultInstance;

  /// Stays the same for as long as the action exists: `sleep`, `restart`,
  /// `shut_down`, `mute`, `volume_up`, `volume_down`, or `custom.<random>`
  /// for the owner's own.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ActionKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(ActionKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  /// The owner's name for a custom action. Empty for the others: the asking
  /// device words those itself, in its own language.
  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  /// The asking device should confirm with its user before sending
  /// `RunAction`, because the computer is out of reach afterwards.
  @$pb.TagNumber(4)
  $core.bool get confirm => $_getBF(3);
  @$pb.TagNumber(4)
  set confirm($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasConfirm() => $_has(3);
  @$pb.TagNumber(4)
  void clearConfirm() => $_clearField(4);
}

/// Every action a computer offers the receiver right now. Sent without
/// expecting a reply when a session opens and whenever the list changes. A
/// device that never got one shows no actions.
class ActionList extends $pb.GeneratedMessage {
  factory ActionList({
    $core.Iterable<Action>? actions,
  }) {
    final result = ActionList._();
    if (actions != null) result.actions.addAll(actions);
    return result;
  }

  ActionList._();

  factory ActionList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ActionList()..mergeFromBuffer(data, registry);
  factory ActionList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ActionList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActionList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.actions.v1'),
      createEmptyInstance: ActionList.$_createMessage)
    ..pPM<Action>(1, _omitFieldNames ? '' : 'actions',
        subBuilder: Action.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActionList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActionList copyWith(void Function(ActionList) updates) =>
      super.copyWith((message) => updates(message as ActionList)) as ActionList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ActionList() / ActionList.new instead')
  static ActionList create() => ActionList._();
  static $pb.GeneratedMessage $_createMessage() => ActionList._();
  @$core.override
  ActionList createEmptyInstance() => ActionList._();
  @$core.pragma('dart2js:noInline')
  static ActionList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActionList>(ActionList.$_createMessage);
  static ActionList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Action> get actions => $_getList(0);
}

/// Asks the computer to run one of its actions. Expects a `RunActionReply`,
/// which can take a minute: the computer may ask its owner first, and counts
/// down before it restarts or shuts down.
class RunAction extends $pb.GeneratedMessage {
  factory RunAction({
    $core.String? id,
  }) {
    final result = RunAction._();
    if (id != null) result.id = id;
    return result;
  }

  RunAction._();

  factory RunAction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunAction()..mergeFromBuffer(data, registry);
  factory RunAction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunAction()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RunAction',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.actions.v1'),
      createEmptyInstance: RunAction.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunAction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunAction copyWith(void Function(RunAction) updates) =>
      super.copyWith((message) => updates(message as RunAction)) as RunAction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RunAction() / RunAction.new instead')
  static RunAction create() => RunAction._();
  static $pb.GeneratedMessage $_createMessage() => RunAction._();
  @$core.override
  RunAction createEmptyInstance() => RunAction._();
  @$core.pragma('dart2js:noInline')
  static RunAction getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RunAction>(RunAction.$_createMessage);
  static RunAction? _defaultInstance;

  /// An `Action.id` from the computer's `ActionList`. Never a command line.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

/// The reply to `RunAction`. What a custom action printed stays on the
/// computer.
class RunActionReply extends $pb.GeneratedMessage {
  factory RunActionReply({
    RunResult? result,
    $core.int? exitCode,
  }) {
    final result$ = RunActionReply._();
    if (result != null) result$.result = result;
    if (exitCode != null) result$.exitCode = exitCode;
    return result$;
  }

  RunActionReply._();

  factory RunActionReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunActionReply()..mergeFromBuffer(data, registry);
  factory RunActionReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunActionReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RunActionReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.actions.v1'),
      createEmptyInstance: RunActionReply.$_createMessage)
    ..aE<RunResult>(1, _omitFieldNames ? '' : 'result',
        enumValues: RunResult.values)
    ..aI(2, _omitFieldNames ? '' : 'exitCode', fieldType: $pb.PbFieldType.OS3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunActionReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunActionReply copyWith(void Function(RunActionReply) updates) =>
      super.copyWith((message) => updates(message as RunActionReply))
          as RunActionReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RunActionReply() / RunActionReply.new instead')
  static RunActionReply create() => RunActionReply._();
  static $pb.GeneratedMessage $_createMessage() => RunActionReply._();
  @$core.override
  RunActionReply createEmptyInstance() => RunActionReply._();
  @$core.pragma('dart2js:noInline')
  static RunActionReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RunActionReply>(
          RunActionReply.$_createMessage);
  static RunActionReply? _defaultInstance;

  @$pb.TagNumber(1)
  RunResult get result => $_getN(0);
  @$pb.TagNumber(1)
  set result(RunResult value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => $_clearField(1);

  /// How a custom action's command ended. Only set when it ran to its end.
  @$pb.TagNumber(2)
  $core.int get exitCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set exitCode($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExitCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearExitCode() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
