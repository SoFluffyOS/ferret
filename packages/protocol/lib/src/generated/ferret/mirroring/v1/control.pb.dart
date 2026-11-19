// This is a generated file - do not edit.
//
// Generated from ferret/mirroring/v1/control.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../remote_input/v1/remote_input.pb.dart' as $0;
import 'control.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'control.pbenum.dart';

/// Sent by the source after `StartAccept`, and again whenever control
/// changes. Expects no reply.
class ControlState extends $pb.GeneratedMessage {
  factory ControlState({
    ControlStatus? status,
    $core.Iterable<ControlKind>? kinds,
    $core.int? timeoutSeconds,
    $core.Iterable<ControlButton>? buttons,
  }) {
    final result = ControlState._();
    if (status != null) result.status = status;
    if (kinds != null) result.kinds.addAll(kinds);
    if (timeoutSeconds != null) result.timeoutSeconds = timeoutSeconds;
    if (buttons != null) result.buttons.addAll(buttons);
    return result;
  }

  ControlState._();

  factory ControlState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlState()..mergeFromBuffer(data, registry);
  factory ControlState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControlState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: ControlState.$_createMessage)
    ..aE<ControlStatus>(1, _omitFieldNames ? '' : 'status',
        enumValues: ControlStatus.values)
    ..pc<ControlKind>(2, _omitFieldNames ? '' : 'kinds', $pb.PbFieldType.KE,
        valueOf: ControlKind.valueOf,
        enumValues: ControlKind.values,
        defaultEnumValue: ControlKind.CONTROL_KIND_UNSPECIFIED)
    ..aI(3, _omitFieldNames ? '' : 'timeoutSeconds',
        fieldType: $pb.PbFieldType.OU3)
    ..pc<ControlButton>(4, _omitFieldNames ? '' : 'buttons', $pb.PbFieldType.KE,
        valueOf: ControlButton.valueOf,
        enumValues: ControlButton.values,
        defaultEnumValue: ControlButton.CONTROL_BUTTON_UNSPECIFIED)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlState copyWith(void Function(ControlState) updates) =>
      super.copyWith((message) => updates(message as ControlState))
          as ControlState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ControlState() / ControlState.new instead')
  static ControlState create() => ControlState._();
  static $pb.GeneratedMessage $_createMessage() => ControlState._();
  @$core.override
  ControlState createEmptyInstance() => ControlState._();
  @$core.pragma('dart2js:noInline')
  static ControlState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ControlState>(
          ControlState.$_createMessage);
  static ControlState? _defaultInstance;

  @$pb.TagNumber(1)
  ControlStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(ControlStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  /// What the source takes right now, or would take once allowed.
  @$pb.TagNumber(2)
  $pb.PbList<ControlKind> get kinds => $_getList(1);

  /// With `CONTROL_STATUS_ASKING`: how long the owner has to answer.
  @$pb.TagNumber(3)
  $core.int get timeoutSeconds => $_getIZ(2);
  @$pb.TagNumber(3)
  set timeoutSeconds($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimeoutSeconds() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimeoutSeconds() => $_clearField(3);

  /// The buttons a `ButtonPress` can press. Empty without
  /// `CONTROL_KIND_BUTTONS`.
  @$pb.TagNumber(4)
  $pb.PbList<ControlButton> get buttons => $_getList(3);
}

/// The viewer wants control. The source answers with `ControlState`:
/// `ASKING` while its owner decides, then `ALLOWED`, `DENIED` or
/// `TIMED_OUT`; `ALLOWED` at once for a viewer its owner always allows.
/// Ignored while the source isn't showing its screen to this viewer.
class ControlAsk extends $pb.GeneratedMessage {
  factory ControlAsk() => ControlAsk._();

  ControlAsk._();

  factory ControlAsk.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlAsk()..mergeFromBuffer(data, registry);
  factory ControlAsk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlAsk()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControlAsk',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: ControlAsk.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlAsk clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlAsk copyWith(void Function(ControlAsk) updates) =>
      super.copyWith((message) => updates(message as ControlAsk)) as ControlAsk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ControlAsk() / ControlAsk.new instead')
  static ControlAsk create() => ControlAsk._();
  static $pb.GeneratedMessage $_createMessage() => ControlAsk._();
  @$core.override
  ControlAsk createEmptyInstance() => ControlAsk._();
  @$core.pragma('dart2js:noInline')
  static ControlAsk getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ControlAsk>(ControlAsk.$_createMessage);
  static ControlAsk? _defaultInstance;
}

/// The viewer gives control back and only watches. The source answers with
/// `ControlState` `CAN_ASK`.
class ControlRelease extends $pb.GeneratedMessage {
  factory ControlRelease() => ControlRelease._();

  ControlRelease._();

  factory ControlRelease.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlRelease()..mergeFromBuffer(data, registry);
  factory ControlRelease.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlRelease()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControlRelease',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: ControlRelease.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlRelease clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlRelease copyWith(void Function(ControlRelease) updates) =>
      super.copyWith((message) => updates(message as ControlRelease))
          as ControlRelease;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ControlRelease() / ControlRelease.new instead')
  static ControlRelease create() => ControlRelease._();
  static $pb.GeneratedMessage $_createMessage() => ControlRelease._();
  @$core.override
  ControlRelease createEmptyInstance() => ControlRelease._();
  @$core.pragma('dart2js:noInline')
  static ControlRelease getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ControlRelease>(
          ControlRelease.$_createMessage);
  static ControlRelease? _defaultInstance;
}

/// One step of a touch. Positions are fractions of the picture as the source
/// sends it, in its current rotation: (0, 0) is the top left corner and
/// (1, 1) the bottom right. The source clamps them to that range.
class PointerInput extends $pb.GeneratedMessage {
  factory PointerInput({
    TouchPhase? phase,
    $core.double? x,
    $core.double? y,
    $core.double? scrollX,
    $core.double? scrollY,
  }) {
    final result = PointerInput._();
    if (phase != null) result.phase = phase;
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (scrollX != null) result.scrollX = scrollX;
    if (scrollY != null) result.scrollY = scrollY;
    return result;
  }

  PointerInput._();

  factory PointerInput.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PointerInput()..mergeFromBuffer(data, registry);
  factory PointerInput.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PointerInput()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PointerInput',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: PointerInput.$_createMessage)
    ..aE<TouchPhase>(1, _omitFieldNames ? '' : 'phase',
        enumValues: TouchPhase.values)
    ..aD(2, _omitFieldNames ? '' : 'x', fieldType: $pb.PbFieldType.OF)
    ..aD(3, _omitFieldNames ? '' : 'y', fieldType: $pb.PbFieldType.OF)
    ..aD(4, _omitFieldNames ? '' : 'scrollX', fieldType: $pb.PbFieldType.OF)
    ..aD(5, _omitFieldNames ? '' : 'scrollY', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PointerInput clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PointerInput copyWith(void Function(PointerInput) updates) =>
      super.copyWith((message) => updates(message as PointerInput))
          as PointerInput;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PointerInput() / PointerInput.new instead')
  static PointerInput create() => PointerInput._();
  static $pb.GeneratedMessage $_createMessage() => PointerInput._();
  @$core.override
  PointerInput createEmptyInstance() => PointerInput._();
  @$core.pragma('dart2js:noInline')
  static PointerInput getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PointerInput>(
          PointerInput.$_createMessage);
  static PointerInput? _defaultInstance;

  @$pb.TagNumber(1)
  TouchPhase get phase => $_getN(0);
  @$pb.TagNumber(1)
  set phase(TouchPhase value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPhase() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhase() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get x => $_getN(1);
  @$pb.TagNumber(2)
  set x($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasX() => $_has(1);
  @$pb.TagNumber(2)
  void clearX() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get y => $_getN(2);
  @$pb.TagNumber(3)
  set y($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasY() => $_has(2);
  @$pb.TagNumber(3)
  void clearY() => $_clearField(3);

  /// `TOUCH_PHASE_SCROLL` only, in wheel notches: positive is right.
  @$pb.TagNumber(4)
  $core.double get scrollX => $_getN(3);
  @$pb.TagNumber(4)
  set scrollX($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasScrollX() => $_has(3);
  @$pb.TagNumber(4)
  void clearScrollX() => $_clearField(4);

  /// `TOUCH_PHASE_SCROLL` only, in wheel notches: positive is down.
  @$pb.TagNumber(5)
  $core.double get scrollY => $_getN(4);
  @$pb.TagNumber(5)
  set scrollY($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasScrollY() => $_has(4);
  @$pb.TagNumber(5)
  void clearScrollY() => $_clearField(5);
}

/// A press and release of one of the device's buttons.
class ButtonPress extends $pb.GeneratedMessage {
  factory ButtonPress({
    ControlButton? button,
  }) {
    final result = ButtonPress._();
    if (button != null) result.button = button;
    return result;
  }

  ButtonPress._();

  factory ButtonPress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ButtonPress()..mergeFromBuffer(data, registry);
  factory ButtonPress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ButtonPress()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ButtonPress',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: ButtonPress.$_createMessage)
    ..aE<ControlButton>(1, _omitFieldNames ? '' : 'button',
        enumValues: ControlButton.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ButtonPress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ButtonPress copyWith(void Function(ButtonPress) updates) =>
      super.copyWith((message) => updates(message as ButtonPress))
          as ButtonPress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ButtonPress() / ButtonPress.new instead')
  static ButtonPress create() => ButtonPress._();
  static $pb.GeneratedMessage $_createMessage() => ButtonPress._();
  @$core.override
  ButtonPress createEmptyInstance() => ButtonPress._();
  @$core.pragma('dart2js:noInline')
  static ButtonPress getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ButtonPress>(
          ButtonPress.$_createMessage);
  static ButtonPress? _defaultInstance;

  @$pb.TagNumber(1)
  ControlButton get button => $_getN(0);
  @$pb.TagNumber(1)
  set button(ControlButton value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasButton() => $_has(0);
  @$pb.TagNumber(1)
  void clearButton() => $_clearField(1);
}

enum ControlEvent_Kind { pointer, key, text, button, notSet }

/// One thing the viewer does.
class ControlEvent extends $pb.GeneratedMessage {
  factory ControlEvent({
    PointerInput? pointer,
    $0.KeyEvent? key,
    $0.TextInput? text,
    ButtonPress? button,
  }) {
    final result = ControlEvent._();
    if (pointer != null) result.pointer = pointer;
    if (key != null) result.key = key;
    if (text != null) result.text = text;
    if (button != null) result.button = button;
    return result;
  }

  ControlEvent._();

  factory ControlEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlEvent()..mergeFromBuffer(data, registry);
  factory ControlEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlEvent()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ControlEvent_Kind> _ControlEvent_KindByTag =
      {
    1: ControlEvent_Kind.pointer,
    2: ControlEvent_Kind.key,
    3: ControlEvent_Kind.text,
    4: ControlEvent_Kind.button,
    0: ControlEvent_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControlEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: ControlEvent.$_createMessage)
    ..oo(0, [1, 2, 3, 4])
    ..aOM<PointerInput>(1, _omitFieldNames ? '' : 'pointer',
        subBuilder: PointerInput.$_createMessage)
    ..aOM<$0.KeyEvent>(2, _omitFieldNames ? '' : 'key',
        subBuilder: $0.KeyEvent.$_createMessage)
    ..aOM<$0.TextInput>(3, _omitFieldNames ? '' : 'text',
        subBuilder: $0.TextInput.$_createMessage)
    ..aOM<ButtonPress>(4, _omitFieldNames ? '' : 'button',
        subBuilder: ButtonPress.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlEvent copyWith(void Function(ControlEvent) updates) =>
      super.copyWith((message) => updates(message as ControlEvent))
          as ControlEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ControlEvent() / ControlEvent.new instead')
  static ControlEvent create() => ControlEvent._();
  static $pb.GeneratedMessage $_createMessage() => ControlEvent._();
  @$core.override
  ControlEvent createEmptyInstance() => ControlEvent._();
  @$core.pragma('dart2js:noInline')
  static ControlEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ControlEvent>(
          ControlEvent.$_createMessage);
  static ControlEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  ControlEvent_Kind whichKind() => _ControlEvent_KindByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearKind() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  PointerInput get pointer => $_getN(0);
  @$pb.TagNumber(1)
  set pointer(PointerInput value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPointer() => $_has(0);
  @$pb.TagNumber(1)
  void clearPointer() => $_clearField(1);
  @$pb.TagNumber(1)
  PointerInput ensurePointer() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.KeyEvent get key => $_getN(1);
  @$pb.TagNumber(2)
  set key($0.KeyEvent value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.KeyEvent ensureKey() => $_ensure(1);

  @$pb.TagNumber(3)
  $0.TextInput get text => $_getN(2);
  @$pb.TagNumber(3)
  set text($0.TextInput value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.TextInput ensureText() => $_ensure(2);

  @$pb.TagNumber(4)
  ButtonPress get button => $_getN(3);
  @$pb.TagNumber(4)
  set button(ButtonPress value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasButton() => $_has(3);
  @$pb.TagNumber(4)
  void clearButton() => $_clearField(4);
  @$pb.TagNumber(4)
  ButtonPress ensureButton() => $_ensure(3);
}

/// Sent by the viewer while control is allowed, in order. Expects no reply.
/// The source drops it when control isn't allowed for this viewer, and
/// takes at most 512 events from one batch.
class ControlInput extends $pb.GeneratedMessage {
  factory ControlInput({
    $core.Iterable<ControlEvent>? events,
  }) {
    final result = ControlInput._();
    if (events != null) result.events.addAll(events);
    return result;
  }

  ControlInput._();

  factory ControlInput.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlInput()..mergeFromBuffer(data, registry);
  factory ControlInput.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlInput()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControlInput',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: ControlInput.$_createMessage)
    ..pPM<ControlEvent>(1, _omitFieldNames ? '' : 'events',
        subBuilder: ControlEvent.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlInput clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlInput copyWith(void Function(ControlInput) updates) =>
      super.copyWith((message) => updates(message as ControlInput))
          as ControlInput;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ControlInput() / ControlInput.new instead')
  static ControlInput create() => ControlInput._();
  static $pb.GeneratedMessage $_createMessage() => ControlInput._();
  @$core.override
  ControlInput createEmptyInstance() => ControlInput._();
  @$core.pragma('dart2js:noInline')
  static ControlInput getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ControlInput>(
          ControlInput.$_createMessage);
  static ControlInput? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ControlEvent> get events => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
