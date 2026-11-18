// This is a generated file - do not edit.
//
// Generated from ferret/calls/v1/calls.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'calls.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'calls.pbenum.dart';

/// One call on a phone.
class Call extends $pb.GeneratedMessage {
  factory Call({
    $core.String? id,
    $core.String? number,
    $core.String? contactName,
    $core.List<$core.int>? photoJpeg,
    CallDirection? direction,
    CallState? state,
    $fixnum.Int64? startedAtMs,
    $fixnum.Int64? connectedAtMs,
    CallOutcome? outcome,
  }) {
    final result = Call._();
    if (id != null) result.id = id;
    if (number != null) result.number = number;
    if (contactName != null) result.contactName = contactName;
    if (photoJpeg != null) result.photoJpeg = photoJpeg;
    if (direction != null) result.direction = direction;
    if (state != null) result.state = state;
    if (startedAtMs != null) result.startedAtMs = startedAtMs;
    if (connectedAtMs != null) result.connectedAtMs = connectedAtMs;
    if (outcome != null) result.outcome = outcome;
    return result;
  }

  Call._();

  factory Call.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Call()..mergeFromBuffer(data, registry);
  factory Call.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Call()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Call',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.calls.v1'),
      createEmptyInstance: Call.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'number')
    ..aOS(3, _omitFieldNames ? '' : 'contactName')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'photoJpeg', $pb.PbFieldType.OY)
    ..aE<CallDirection>(5, _omitFieldNames ? '' : 'direction',
        enumValues: CallDirection.values)
    ..aE<CallState>(6, _omitFieldNames ? '' : 'state',
        enumValues: CallState.values)
    ..aInt64(7, _omitFieldNames ? '' : 'startedAtMs')
    ..aInt64(8, _omitFieldNames ? '' : 'connectedAtMs')
    ..aE<CallOutcome>(9, _omitFieldNames ? '' : 'outcome',
        enumValues: CallOutcome.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Call clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Call copyWith(void Function(Call) updates) =>
      super.copyWith((message) => updates(message as Call)) as Call;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Call() / Call.new instead')
  static Call create() => Call._();
  static $pb.GeneratedMessage $_createMessage() => Call._();
  @$core.override
  Call createEmptyInstance() => Call._();
  @$core.pragma('dart2js:noInline')
  static Call getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Call>(Call.$_createMessage);
  static Call? _defaultInstance;

  /// Random id chosen by the phone, the same in every update for this call.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// The other side's number as the phone reports it. Empty when it is
  /// hidden or the phone may not read it.
  @$pb.TagNumber(2)
  $core.String get number => $_getSZ(1);
  @$pb.TagNumber(2)
  set number($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearNumber() => $_clearField(2);

  /// The contact's name, empty when the number is not in the contacts.
  @$pb.TagNumber(3)
  $core.String get contactName => $_getSZ(2);
  @$pb.TagNumber(3)
  set contactName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContactName() => $_has(2);
  @$pb.TagNumber(3)
  void clearContactName() => $_clearField(3);

  /// The contact's photo as a small JPEG, at most 96 pixels a side.
  @$pb.TagNumber(4)
  $core.List<$core.int> get photoJpeg => $_getN(3);
  @$pb.TagNumber(4)
  set photoJpeg($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPhotoJpeg() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhotoJpeg() => $_clearField(4);

  @$pb.TagNumber(5)
  CallDirection get direction => $_getN(4);
  @$pb.TagNumber(5)
  set direction(CallDirection value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDirection() => $_has(4);
  @$pb.TagNumber(5)
  void clearDirection() => $_clearField(5);

  @$pb.TagNumber(6)
  CallState get state => $_getN(5);
  @$pb.TagNumber(6)
  set state(CallState value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasState() => $_has(5);
  @$pb.TagNumber(6)
  void clearState() => $_clearField(6);

  /// When the call started ringing or dialing, in the phone's clock.
  @$pb.TagNumber(7)
  $fixnum.Int64 get startedAtMs => $_getI64(6);
  @$pb.TagNumber(7)
  set startedAtMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasStartedAtMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearStartedAtMs() => $_clearField(7);

  /// When the call was picked up, in the phone's clock. Zero until then.
  @$pb.TagNumber(8)
  $fixnum.Int64 get connectedAtMs => $_getI64(7);
  @$pb.TagNumber(8)
  set connectedAtMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasConnectedAtMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearConnectedAtMs() => $_clearField(8);

  /// Set with CALL_STATE_ENDED.
  @$pb.TagNumber(9)
  CallOutcome get outcome => $_getN(8);
  @$pb.TagNumber(9)
  set outcome(CallOutcome value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasOutcome() => $_has(8);
  @$pb.TagNumber(9)
  void clearOutcome() => $_clearField(9);
}

/// A call changed. Sent by the phone without expecting a reply, for every
/// change, and once for each ongoing call when a session opens. Calls that
/// already ended are never replayed.
class CallUpdate extends $pb.GeneratedMessage {
  factory CallUpdate({
    Call? call,
    $fixnum.Int64? sentAtMs,
  }) {
    final result = CallUpdate._();
    if (call != null) result.call = call;
    if (sentAtMs != null) result.sentAtMs = sentAtMs;
    return result;
  }

  CallUpdate._();

  factory CallUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallUpdate()..mergeFromBuffer(data, registry);
  factory CallUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CallUpdate',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.calls.v1'),
      createEmptyInstance: CallUpdate.$_createMessage)
    ..aOM<Call>(1, _omitFieldNames ? '' : 'call',
        subBuilder: Call.$_createMessage)
    ..aInt64(2, _omitFieldNames ? '' : 'sentAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallUpdate copyWith(void Function(CallUpdate) updates) =>
      super.copyWith((message) => updates(message as CallUpdate)) as CallUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CallUpdate() / CallUpdate.new instead')
  static CallUpdate create() => CallUpdate._();
  static $pb.GeneratedMessage $_createMessage() => CallUpdate._();
  @$core.override
  CallUpdate createEmptyInstance() => CallUpdate._();
  @$core.pragma('dart2js:noInline')
  static CallUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CallUpdate>(CallUpdate.$_createMessage);
  static CallUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  Call get call => $_getN(0);
  @$pb.TagNumber(1)
  set call(Call value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCall() => $_has(0);
  @$pb.TagNumber(1)
  void clearCall() => $_clearField(1);
  @$pb.TagNumber(1)
  Call ensureCall() => $_ensure(0);

  /// The phone's clock when it sent this, so receivers can show a call timer
  /// that does not depend on both clocks agreeing.
  @$pb.TagNumber(2)
  $fixnum.Int64 get sentAtMs => $_getI64(1);
  @$pb.TagNumber(2)
  set sentAtMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSentAtMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearSentAtMs() => $_clearField(2);
}

/// Request. The phone replies with CallCommandResult.
class CallCommand extends $pb.GeneratedMessage {
  factory CallCommand({
    CallAction? action,
    $core.String? callId,
    $core.String? number,
  }) {
    final result = CallCommand._();
    if (action != null) result.action = action;
    if (callId != null) result.callId = callId;
    if (number != null) result.number = number;
    return result;
  }

  CallCommand._();

  factory CallCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallCommand()..mergeFromBuffer(data, registry);
  factory CallCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallCommand()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CallCommand',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.calls.v1'),
      createEmptyInstance: CallCommand.$_createMessage)
    ..aE<CallAction>(1, _omitFieldNames ? '' : 'action',
        enumValues: CallAction.values)
    ..aOS(2, _omitFieldNames ? '' : 'callId')
    ..aOS(3, _omitFieldNames ? '' : 'number')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallCommand copyWith(void Function(CallCommand) updates) =>
      super.copyWith((message) => updates(message as CallCommand))
          as CallCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CallCommand() / CallCommand.new instead')
  static CallCommand create() => CallCommand._();
  static $pb.GeneratedMessage $_createMessage() => CallCommand._();
  @$core.override
  CallCommand createEmptyInstance() => CallCommand._();
  @$core.pragma('dart2js:noInline')
  static CallCommand getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CallCommand>(
          CallCommand.$_createMessage);
  static CallCommand? _defaultInstance;

  @$pb.TagNumber(1)
  CallAction get action => $_getN(0);
  @$pb.TagNumber(1)
  set action(CallAction value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  /// The call the command is for. The phone refuses a command for a call that
  /// is gone. Unused for CALL_ACTION_DIAL.
  @$pb.TagNumber(2)
  $core.String get callId => $_getSZ(1);
  @$pb.TagNumber(2)
  set callId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCallId() => $_has(1);
  @$pb.TagNumber(2)
  void clearCallId() => $_clearField(2);

  /// The number to call, for CALL_ACTION_DIAL.
  @$pb.TagNumber(3)
  $core.String get number => $_getSZ(2);
  @$pb.TagNumber(3)
  set number($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearNumber() => $_clearField(3);
}

class CallCommandResult extends $pb.GeneratedMessage {
  factory CallCommandResult({
    CallCommandStatus? status,
  }) {
    final result = CallCommandResult._();
    if (status != null) result.status = status;
    return result;
  }

  CallCommandResult._();

  factory CallCommandResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallCommandResult()..mergeFromBuffer(data, registry);
  factory CallCommandResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallCommandResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CallCommandResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.calls.v1'),
      createEmptyInstance: CallCommandResult.$_createMessage)
    ..aE<CallCommandStatus>(1, _omitFieldNames ? '' : 'status',
        enumValues: CallCommandStatus.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallCommandResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallCommandResult copyWith(void Function(CallCommandResult) updates) =>
      super.copyWith((message) => updates(message as CallCommandResult))
          as CallCommandResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CallCommandResult() / CallCommandResult.new instead')
  static CallCommandResult create() => CallCommandResult._();
  static $pb.GeneratedMessage $_createMessage() => CallCommandResult._();
  @$core.override
  CallCommandResult createEmptyInstance() => CallCommandResult._();
  @$core.pragma('dart2js:noInline')
  static CallCommandResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CallCommandResult>(
          CallCommandResult.$_createMessage);
  static CallCommandResult? _defaultInstance;

  @$pb.TagNumber(1)
  CallCommandStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(CallCommandStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
}

/// Request. The phone replies with CallsStatus.
class GetCallsStatus extends $pb.GeneratedMessage {
  factory GetCallsStatus() => GetCallsStatus._();

  GetCallsStatus._();

  factory GetCallsStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCallsStatus()..mergeFromBuffer(data, registry);
  factory GetCallsStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCallsStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetCallsStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.calls.v1'),
      createEmptyInstance: GetCallsStatus.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCallsStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCallsStatus copyWith(void Function(GetCallsStatus) updates) =>
      super.copyWith((message) => updates(message as GetCallsStatus))
          as GetCallsStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetCallsStatus() / GetCallsStatus.new instead')
  static GetCallsStatus create() => GetCallsStatus._();
  static $pb.GeneratedMessage $_createMessage() => GetCallsStatus._();
  @$core.override
  GetCallsStatus createEmptyInstance() => GetCallsStatus._();
  @$core.pragma('dart2js:noInline')
  static GetCallsStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetCallsStatus>(
          GetCallsStatus.$_createMessage);
  static GetCallsStatus? _defaultInstance;
}

/// What the phone can do right now. Also sent on its own when it changes.
class CallsStatus extends $pb.GeneratedMessage {
  factory CallsStatus({
    $core.bool? enabled,
    $core.bool? canSeeCalls,
    $core.bool? canSeeNumbers,
    $core.bool? canAnswer,
    $core.bool? canDial,
    $core.bool? canReadLog,
    $core.bool? canReadContacts,
  }) {
    final result = CallsStatus._();
    if (enabled != null) result.enabled = enabled;
    if (canSeeCalls != null) result.canSeeCalls = canSeeCalls;
    if (canSeeNumbers != null) result.canSeeNumbers = canSeeNumbers;
    if (canAnswer != null) result.canAnswer = canAnswer;
    if (canDial != null) result.canDial = canDial;
    if (canReadLog != null) result.canReadLog = canReadLog;
    if (canReadContacts != null) result.canReadContacts = canReadContacts;
    return result;
  }

  CallsStatus._();

  factory CallsStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallsStatus()..mergeFromBuffer(data, registry);
  factory CallsStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallsStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CallsStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.calls.v1'),
      createEmptyInstance: CallsStatus.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOB(2, _omitFieldNames ? '' : 'canSeeCalls')
    ..aOB(3, _omitFieldNames ? '' : 'canSeeNumbers')
    ..aOB(4, _omitFieldNames ? '' : 'canAnswer')
    ..aOB(5, _omitFieldNames ? '' : 'canDial')
    ..aOB(6, _omitFieldNames ? '' : 'canReadLog')
    ..aOB(7, _omitFieldNames ? '' : 'canReadContacts')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallsStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallsStatus copyWith(void Function(CallsStatus) updates) =>
      super.copyWith((message) => updates(message as CallsStatus))
          as CallsStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CallsStatus() / CallsStatus.new instead')
  static CallsStatus create() => CallsStatus._();
  static $pb.GeneratedMessage $_createMessage() => CallsStatus._();
  @$core.override
  CallsStatus createEmptyInstance() => CallsStatus._();
  @$core.pragma('dart2js:noInline')
  static CallsStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CallsStatus>(
          CallsStatus.$_createMessage);
  static CallsStatus? _defaultInstance;

  /// The phone's owner turned calls on.
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  /// The phone may watch its call state.
  @$pb.TagNumber(2)
  $core.bool get canSeeCalls => $_getBF(1);
  @$pb.TagNumber(2)
  set canSeeCalls($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCanSeeCalls() => $_has(1);
  @$pb.TagNumber(2)
  void clearCanSeeCalls() => $_clearField(2);

  /// The phone may read who is calling.
  @$pb.TagNumber(3)
  $core.bool get canSeeNumbers => $_getBF(2);
  @$pb.TagNumber(3)
  set canSeeNumbers($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCanSeeNumbers() => $_has(2);
  @$pb.TagNumber(3)
  void clearCanSeeNumbers() => $_clearField(3);

  /// The phone may answer and end calls.
  @$pb.TagNumber(4)
  $core.bool get canAnswer => $_getBF(3);
  @$pb.TagNumber(4)
  set canAnswer($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCanAnswer() => $_has(3);
  @$pb.TagNumber(4)
  void clearCanAnswer() => $_clearField(4);

  /// The phone may place calls.
  @$pb.TagNumber(5)
  $core.bool get canDial => $_getBF(4);
  @$pb.TagNumber(5)
  set canDial($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCanDial() => $_has(4);
  @$pb.TagNumber(5)
  void clearCanDial() => $_clearField(5);

  /// The phone may read its call history.
  @$pb.TagNumber(6)
  $core.bool get canReadLog => $_getBF(5);
  @$pb.TagNumber(6)
  set canReadLog($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCanReadLog() => $_has(5);
  @$pb.TagNumber(6)
  void clearCanReadLog() => $_clearField(6);

  /// The phone may look numbers up in its contacts.
  @$pb.TagNumber(7)
  $core.bool get canReadContacts => $_getBF(6);
  @$pb.TagNumber(7)
  set canReadContacts($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCanReadContacts() => $_has(6);
  @$pb.TagNumber(7)
  void clearCanReadContacts() => $_clearField(7);
}

/// One past call.
class CallLogEntry extends $pb.GeneratedMessage {
  factory CallLogEntry({
    $core.String? id,
    $core.String? number,
    $core.String? name,
    CallLogType? type,
    $fixnum.Int64? dateMs,
    $fixnum.Int64? durationS,
  }) {
    final result = CallLogEntry._();
    if (id != null) result.id = id;
    if (number != null) result.number = number;
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (dateMs != null) result.dateMs = dateMs;
    if (durationS != null) result.durationS = durationS;
    return result;
  }

  CallLogEntry._();

  factory CallLogEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallLogEntry()..mergeFromBuffer(data, registry);
  factory CallLogEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallLogEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CallLogEntry',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.calls.v1'),
      createEmptyInstance: CallLogEntry.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'number')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aE<CallLogType>(4, _omitFieldNames ? '' : 'type',
        enumValues: CallLogType.values)
    ..aInt64(5, _omitFieldNames ? '' : 'dateMs')
    ..aInt64(6, _omitFieldNames ? '' : 'durationS')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallLogEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallLogEntry copyWith(void Function(CallLogEntry) updates) =>
      super.copyWith((message) => updates(message as CallLogEntry))
          as CallLogEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CallLogEntry() / CallLogEntry.new instead')
  static CallLogEntry create() => CallLogEntry._();
  static $pb.GeneratedMessage $_createMessage() => CallLogEntry._();
  @$core.override
  CallLogEntry createEmptyInstance() => CallLogEntry._();
  @$core.pragma('dart2js:noInline')
  static CallLogEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CallLogEntry>(
          CallLogEntry.$_createMessage);
  static CallLogEntry? _defaultInstance;

  /// The phone's own id for the entry.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get number => $_getSZ(1);
  @$pb.TagNumber(2)
  set number($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearNumber() => $_clearField(2);

  /// The contact's name, empty when unknown.
  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  CallLogType get type => $_getN(3);
  @$pb.TagNumber(4)
  set type(CallLogType value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasType() => $_has(3);
  @$pb.TagNumber(4)
  void clearType() => $_clearField(4);

  /// When the call happened, in the phone's clock.
  @$pb.TagNumber(5)
  $fixnum.Int64 get dateMs => $_getI64(4);
  @$pb.TagNumber(5)
  set dateMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDateMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearDateMs() => $_clearField(5);

  /// How long the call lasted, zero when it was not picked up.
  @$pb.TagNumber(6)
  $fixnum.Int64 get durationS => $_getI64(5);
  @$pb.TagNumber(6)
  set durationS($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDurationS() => $_has(5);
  @$pb.TagNumber(6)
  void clearDurationS() => $_clearField(6);
}

/// Request. The phone replies with CallLog.
class GetCallLog extends $pb.GeneratedMessage {
  factory GetCallLog({
    $core.int? limit,
  }) {
    final result = GetCallLog._();
    if (limit != null) result.limit = limit;
    return result;
  }

  GetCallLog._();

  factory GetCallLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCallLog()..mergeFromBuffer(data, registry);
  factory GetCallLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCallLog()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetCallLog',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.calls.v1'),
      createEmptyInstance: GetCallLog.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCallLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCallLog copyWith(void Function(GetCallLog) updates) =>
      super.copyWith((message) => updates(message as GetCallLog)) as GetCallLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetCallLog() / GetCallLog.new instead')
  static GetCallLog create() => GetCallLog._();
  static $pb.GeneratedMessage $_createMessage() => GetCallLog._();
  @$core.override
  GetCallLog createEmptyInstance() => GetCallLog._();
  @$core.pragma('dart2js:noInline')
  static GetCallLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetCallLog>(GetCallLog.$_createMessage);
  static GetCallLog? _defaultInstance;

  /// The most entries to send back, newest first. Zero means 50; the phone
  /// never sends more than 200.
  @$pb.TagNumber(1)
  $core.int get limit => $_getIZ(0);
  @$pb.TagNumber(1)
  set limit($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLimit() => $_has(0);
  @$pb.TagNumber(1)
  void clearLimit() => $_clearField(1);
}

class CallLog extends $pb.GeneratedMessage {
  factory CallLog({
    $core.Iterable<CallLogEntry>? entries,
    $core.bool? permissionMissing,
    $core.bool? disabled,
  }) {
    final result = CallLog._();
    if (entries != null) result.entries.addAll(entries);
    if (permissionMissing != null) result.permissionMissing = permissionMissing;
    if (disabled != null) result.disabled = disabled;
    return result;
  }

  CallLog._();

  factory CallLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallLog()..mergeFromBuffer(data, registry);
  factory CallLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallLog()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CallLog',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.calls.v1'),
      createEmptyInstance: CallLog.$_createMessage)
    ..pPM<CallLogEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: CallLogEntry.$_createMessage)
    ..aOB(2, _omitFieldNames ? '' : 'permissionMissing')
    ..aOB(3, _omitFieldNames ? '' : 'disabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallLog copyWith(void Function(CallLog) updates) =>
      super.copyWith((message) => updates(message as CallLog)) as CallLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CallLog() / CallLog.new instead')
  static CallLog create() => CallLog._();
  static $pb.GeneratedMessage $_createMessage() => CallLog._();
  @$core.override
  CallLog createEmptyInstance() => CallLog._();
  @$core.pragma('dart2js:noInline')
  static CallLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CallLog>(CallLog.$_createMessage);
  static CallLog? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CallLogEntry> get entries => $_getList(0);

  /// The phone may not read its call history, so `entries` is empty.
  @$pb.TagNumber(2)
  $core.bool get permissionMissing => $_getBF(1);
  @$pb.TagNumber(2)
  set permissionMissing($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPermissionMissing() => $_has(1);
  @$pb.TagNumber(2)
  void clearPermissionMissing() => $_clearField(2);

  /// Calls are turned off on the phone, so `entries` is empty.
  @$pb.TagNumber(3)
  $core.bool get disabled => $_getBF(2);
  @$pb.TagNumber(3)
  set disabled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisabled() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisabled() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
