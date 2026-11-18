// This is a generated file - do not edit.
//
// Generated from ferret/remote_input/v1/remote_input.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'remote_input.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'remote_input.pbenum.dart';

/// Asks the computer for control. Expects a `ControlPending`, `ControlGrant`
/// or `ControlDeny` reply. After `ControlPending`, the computer sends the
/// `ControlGrant` or `ControlDeny` later, without expecting a reply.
class ControlRequest extends $pb.GeneratedMessage {
  factory ControlRequest({
    $core.int? version,
  }) {
    final result = ControlRequest._();
    if (version != null) result.version = version;
    return result;
  }

  ControlRequest._();

  factory ControlRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlRequest()..mergeFromBuffer(data, registry);
  factory ControlRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControlRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.remote_input.v1'),
      createEmptyInstance: ControlRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'version', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlRequest copyWith(void Function(ControlRequest) updates) =>
      super.copyWith((message) => updates(message as ControlRequest))
          as ControlRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ControlRequest() / ControlRequest.new instead')
  static ControlRequest create() => ControlRequest._();
  static $pb.GeneratedMessage $_createMessage() => ControlRequest._();
  @$core.override
  ControlRequest createEmptyInstance() => ControlRequest._();
  @$core.pragma('dart2js:noInline')
  static ControlRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ControlRequest>(
          ControlRequest.$_createMessage);
  static ControlRequest? _defaultInstance;

  /// The version of these messages the controller speaks.
  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);
}

/// The computer is asking its owner. The answer follows as `ControlGrant` or
/// `ControlDeny`.
class ControlPending extends $pb.GeneratedMessage {
  factory ControlPending({
    $core.int? timeoutSeconds,
  }) {
    final result = ControlPending._();
    if (timeoutSeconds != null) result.timeoutSeconds = timeoutSeconds;
    return result;
  }

  ControlPending._();

  factory ControlPending.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlPending()..mergeFromBuffer(data, registry);
  factory ControlPending.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlPending()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControlPending',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.remote_input.v1'),
      createEmptyInstance: ControlPending.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'timeoutSeconds',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlPending clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlPending copyWith(void Function(ControlPending) updates) =>
      super.copyWith((message) => updates(message as ControlPending))
          as ControlPending;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ControlPending() / ControlPending.new instead')
  static ControlPending create() => ControlPending._();
  static $pb.GeneratedMessage $_createMessage() => ControlPending._();
  @$core.override
  ControlPending createEmptyInstance() => ControlPending._();
  @$core.pragma('dart2js:noInline')
  static ControlPending getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ControlPending>(
          ControlPending.$_createMessage);
  static ControlPending? _defaultInstance;

  /// How long the computer waits for its owner before it denies with
  /// `DENY_REASON_TIMEOUT`.
  @$pb.TagNumber(1)
  $core.int get timeoutSeconds => $_getIZ(0);
  @$pb.TagNumber(1)
  set timeoutSeconds($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimeoutSeconds() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimeoutSeconds() => $_clearField(1);
}

/// The controller may send `InputBatch`es until either side sends
/// `ControlStop`.
class ControlGrant extends $pb.GeneratedMessage {
  factory ControlGrant({
    $core.int? version,
    $core.bool? always,
  }) {
    final result = ControlGrant._();
    if (version != null) result.version = version;
    if (always != null) result.always = always;
    return result;
  }

  ControlGrant._();

  factory ControlGrant.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlGrant()..mergeFromBuffer(data, registry);
  factory ControlGrant.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlGrant()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControlGrant',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.remote_input.v1'),
      createEmptyInstance: ControlGrant.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'version', fieldType: $pb.PbFieldType.OU3)
    ..aOB(2, _omitFieldNames ? '' : 'always')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlGrant clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlGrant copyWith(void Function(ControlGrant) updates) =>
      super.copyWith((message) => updates(message as ControlGrant))
          as ControlGrant;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ControlGrant() / ControlGrant.new instead')
  static ControlGrant create() => ControlGrant._();
  static $pb.GeneratedMessage $_createMessage() => ControlGrant._();
  @$core.override
  ControlGrant createEmptyInstance() => ControlGrant._();
  @$core.pragma('dart2js:noInline')
  static ControlGrant getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ControlGrant>(
          ControlGrant.$_createMessage);
  static ControlGrant? _defaultInstance;

  /// The version of these messages the computer speaks.
  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  /// The computer's owner allowed this device for good, not just this once.
  @$pb.TagNumber(2)
  $core.bool get always => $_getBF(1);
  @$pb.TagNumber(2)
  set always($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAlways() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlways() => $_clearField(2);
}

class ControlDeny extends $pb.GeneratedMessage {
  factory ControlDeny({
    DenyReason? reason,
  }) {
    final result = ControlDeny._();
    if (reason != null) result.reason = reason;
    return result;
  }

  ControlDeny._();

  factory ControlDeny.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlDeny()..mergeFromBuffer(data, registry);
  factory ControlDeny.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlDeny()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControlDeny',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.remote_input.v1'),
      createEmptyInstance: ControlDeny.$_createMessage)
    ..aE<DenyReason>(1, _omitFieldNames ? '' : 'reason',
        enumValues: DenyReason.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlDeny clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlDeny copyWith(void Function(ControlDeny) updates) =>
      super.copyWith((message) => updates(message as ControlDeny))
          as ControlDeny;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ControlDeny() / ControlDeny.new instead')
  static ControlDeny create() => ControlDeny._();
  static $pb.GeneratedMessage $_createMessage() => ControlDeny._();
  @$core.override
  ControlDeny createEmptyInstance() => ControlDeny._();
  @$core.pragma('dart2js:noInline')
  static ControlDeny getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ControlDeny>(
          ControlDeny.$_createMessage);
  static ControlDeny? _defaultInstance;

  @$pb.TagNumber(1)
  DenyReason get reason => $_getN(0);
  @$pb.TagNumber(1)
  set reason(DenyReason value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReason() => $_has(0);
  @$pb.TagNumber(1)
  void clearReason() => $_clearField(1);
}

/// Ends control. Either side sends it, without expecting a reply. The
/// computer releases every button and key still held.
class ControlStop extends $pb.GeneratedMessage {
  factory ControlStop({
    StopReason? reason,
  }) {
    final result = ControlStop._();
    if (reason != null) result.reason = reason;
    return result;
  }

  ControlStop._();

  factory ControlStop.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlStop()..mergeFromBuffer(data, registry);
  factory ControlStop.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ControlStop()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ControlStop',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.remote_input.v1'),
      createEmptyInstance: ControlStop.$_createMessage)
    ..aE<StopReason>(1, _omitFieldNames ? '' : 'reason',
        enumValues: StopReason.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlStop clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ControlStop copyWith(void Function(ControlStop) updates) =>
      super.copyWith((message) => updates(message as ControlStop))
          as ControlStop;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ControlStop() / ControlStop.new instead')
  static ControlStop create() => ControlStop._();
  static $pb.GeneratedMessage $_createMessage() => ControlStop._();
  @$core.override
  ControlStop createEmptyInstance() => ControlStop._();
  @$core.pragma('dart2js:noInline')
  static ControlStop getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ControlStop>(
          ControlStop.$_createMessage);
  static ControlStop? _defaultInstance;

  @$pb.TagNumber(1)
  StopReason get reason => $_getN(0);
  @$pb.TagNumber(1)
  set reason(StopReason value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReason() => $_has(0);
  @$pb.TagNumber(1)
  void clearReason() => $_clearField(1);
}

/// Moves the pointer by a distance in logical pixels of the computer's
/// screen, after the controller applied its speed and acceleration.
class PointerMove extends $pb.GeneratedMessage {
  factory PointerMove({
    $core.int? dx,
    $core.int? dy,
  }) {
    final result = PointerMove._();
    if (dx != null) result.dx = dx;
    if (dy != null) result.dy = dy;
    return result;
  }

  PointerMove._();

  factory PointerMove.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PointerMove()..mergeFromBuffer(data, registry);
  factory PointerMove.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PointerMove()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PointerMove',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.remote_input.v1'),
      createEmptyInstance: PointerMove.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'dx', fieldType: $pb.PbFieldType.OS3)
    ..aI(2, _omitFieldNames ? '' : 'dy', fieldType: $pb.PbFieldType.OS3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PointerMove clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PointerMove copyWith(void Function(PointerMove) updates) =>
      super.copyWith((message) => updates(message as PointerMove))
          as PointerMove;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PointerMove() / PointerMove.new instead')
  static PointerMove create() => PointerMove._();
  static $pb.GeneratedMessage $_createMessage() => PointerMove._();
  @$core.override
  PointerMove createEmptyInstance() => PointerMove._();
  @$core.pragma('dart2js:noInline')
  static PointerMove getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PointerMove>(
          PointerMove.$_createMessage);
  static PointerMove? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get dx => $_getIZ(0);
  @$pb.TagNumber(1)
  set dx($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDx() => $_has(0);
  @$pb.TagNumber(1)
  void clearDx() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get dy => $_getIZ(1);
  @$pb.TagNumber(2)
  set dy($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDy() => $_has(1);
  @$pb.TagNumber(2)
  void clearDy() => $_clearField(2);
}

/// Presses (`pressed`) or releases a pointer button. A click is a press and
/// a release; a drag is a press, moves, then a release.
class ButtonEvent extends $pb.GeneratedMessage {
  factory ButtonEvent({
    MouseButton? button,
    $core.bool? pressed,
  }) {
    final result = ButtonEvent._();
    if (button != null) result.button = button;
    if (pressed != null) result.pressed = pressed;
    return result;
  }

  ButtonEvent._();

  factory ButtonEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ButtonEvent()..mergeFromBuffer(data, registry);
  factory ButtonEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ButtonEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ButtonEvent',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.remote_input.v1'),
      createEmptyInstance: ButtonEvent.$_createMessage)
    ..aE<MouseButton>(1, _omitFieldNames ? '' : 'button',
        enumValues: MouseButton.values)
    ..aOB(2, _omitFieldNames ? '' : 'pressed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ButtonEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ButtonEvent copyWith(void Function(ButtonEvent) updates) =>
      super.copyWith((message) => updates(message as ButtonEvent))
          as ButtonEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ButtonEvent() / ButtonEvent.new instead')
  static ButtonEvent create() => ButtonEvent._();
  static $pb.GeneratedMessage $_createMessage() => ButtonEvent._();
  @$core.override
  ButtonEvent createEmptyInstance() => ButtonEvent._();
  @$core.pragma('dart2js:noInline')
  static ButtonEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ButtonEvent>(
          ButtonEvent.$_createMessage);
  static ButtonEvent? _defaultInstance;

  @$pb.TagNumber(1)
  MouseButton get button => $_getN(0);
  @$pb.TagNumber(1)
  set button(MouseButton value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasButton() => $_has(0);
  @$pb.TagNumber(1)
  void clearButton() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get pressed => $_getBF(1);
  @$pb.TagNumber(2)
  set pressed($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPressed() => $_has(1);
  @$pb.TagNumber(2)
  void clearPressed() => $_clearField(2);
}

/// Scrolls by a distance in logical pixels. Positive `dy` scrolls toward the
/// end of the page (down), positive `dx` to the right.
class Scroll extends $pb.GeneratedMessage {
  factory Scroll({
    $core.int? dx,
    $core.int? dy,
  }) {
    final result = Scroll._();
    if (dx != null) result.dx = dx;
    if (dy != null) result.dy = dy;
    return result;
  }

  Scroll._();

  factory Scroll.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Scroll()..mergeFromBuffer(data, registry);
  factory Scroll.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Scroll()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Scroll',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.remote_input.v1'),
      createEmptyInstance: Scroll.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'dx', fieldType: $pb.PbFieldType.OS3)
    ..aI(2, _omitFieldNames ? '' : 'dy', fieldType: $pb.PbFieldType.OS3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Scroll clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Scroll copyWith(void Function(Scroll) updates) =>
      super.copyWith((message) => updates(message as Scroll)) as Scroll;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Scroll() / Scroll.new instead')
  static Scroll create() => Scroll._();
  static $pb.GeneratedMessage $_createMessage() => Scroll._();
  @$core.override
  Scroll createEmptyInstance() => Scroll._();
  @$core.pragma('dart2js:noInline')
  static Scroll getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Scroll>(Scroll.$_createMessage);
  static Scroll? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get dx => $_getIZ(0);
  @$pb.TagNumber(1)
  set dx($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDx() => $_has(0);
  @$pb.TagNumber(1)
  void clearDx() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get dy => $_getIZ(1);
  @$pb.TagNumber(2)
  set dy($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDy() => $_has(1);
  @$pb.TagNumber(2)
  void clearDy() => $_clearField(2);
}

/// Presses (`pressed`) or releases a key, with the modifiers held for it.
class KeyEvent extends $pb.GeneratedMessage {
  factory KeyEvent({
    Key? key,
    $core.bool? pressed,
    $core.Iterable<Modifier>? modifiers,
  }) {
    final result = KeyEvent._();
    if (key != null) result.key = key;
    if (pressed != null) result.pressed = pressed;
    if (modifiers != null) result.modifiers.addAll(modifiers);
    return result;
  }

  KeyEvent._();

  factory KeyEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeyEvent()..mergeFromBuffer(data, registry);
  factory KeyEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeyEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KeyEvent',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.remote_input.v1'),
      createEmptyInstance: KeyEvent.$_createMessage)
    ..aE<Key>(1, _omitFieldNames ? '' : 'key', enumValues: Key.values)
    ..aOB(2, _omitFieldNames ? '' : 'pressed')
    ..pc<Modifier>(3, _omitFieldNames ? '' : 'modifiers', $pb.PbFieldType.KE,
        valueOf: Modifier.valueOf,
        enumValues: Modifier.values,
        defaultEnumValue: Modifier.MODIFIER_UNSPECIFIED)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyEvent copyWith(void Function(KeyEvent) updates) =>
      super.copyWith((message) => updates(message as KeyEvent)) as KeyEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use KeyEvent() / KeyEvent.new instead')
  static KeyEvent create() => KeyEvent._();
  static $pb.GeneratedMessage $_createMessage() => KeyEvent._();
  @$core.override
  KeyEvent createEmptyInstance() => KeyEvent._();
  @$core.pragma('dart2js:noInline')
  static KeyEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KeyEvent>(KeyEvent.$_createMessage);
  static KeyEvent? _defaultInstance;

  @$pb.TagNumber(1)
  Key get key => $_getN(0);
  @$pb.TagNumber(1)
  set key(Key value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get pressed => $_getBF(1);
  @$pb.TagNumber(2)
  set pressed($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPressed() => $_has(1);
  @$pb.TagNumber(2)
  void clearPressed() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Modifier> get modifiers => $_getList(2);
}

/// Types text as it is, whatever the computer's keyboard layout.
class TextInput extends $pb.GeneratedMessage {
  factory TextInput({
    $core.String? text,
  }) {
    final result = TextInput._();
    if (text != null) result.text = text;
    return result;
  }

  TextInput._();

  factory TextInput.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TextInput()..mergeFromBuffer(data, registry);
  factory TextInput.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TextInput()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TextInput',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.remote_input.v1'),
      createEmptyInstance: TextInput.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextInput clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextInput copyWith(void Function(TextInput) updates) =>
      super.copyWith((message) => updates(message as TextInput)) as TextInput;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TextInput() / TextInput.new instead')
  static TextInput create() => TextInput._();
  static $pb.GeneratedMessage $_createMessage() => TextInput._();
  @$core.override
  TextInput createEmptyInstance() => TextInput._();
  @$core.pragma('dart2js:noInline')
  static TextInput getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TextInput>(TextInput.$_createMessage);
  static TextInput? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);
}

enum InputEvent_Kind { move, button, scroll, key, text, notSet }

/// One input action.
class InputEvent extends $pb.GeneratedMessage {
  factory InputEvent({
    PointerMove? move,
    ButtonEvent? button,
    Scroll? scroll,
    KeyEvent? key,
    TextInput? text,
  }) {
    final result = InputEvent._();
    if (move != null) result.move = move;
    if (button != null) result.button = button;
    if (scroll != null) result.scroll = scroll;
    if (key != null) result.key = key;
    if (text != null) result.text = text;
    return result;
  }

  InputEvent._();

  factory InputEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InputEvent()..mergeFromBuffer(data, registry);
  factory InputEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InputEvent()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, InputEvent_Kind> _InputEvent_KindByTag = {
    1: InputEvent_Kind.move,
    2: InputEvent_Kind.button,
    3: InputEvent_Kind.scroll,
    4: InputEvent_Kind.key,
    5: InputEvent_Kind.text,
    0: InputEvent_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InputEvent',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.remote_input.v1'),
      createEmptyInstance: InputEvent.$_createMessage)
    ..oo(0, [1, 2, 3, 4, 5])
    ..aOM<PointerMove>(1, _omitFieldNames ? '' : 'move',
        subBuilder: PointerMove.$_createMessage)
    ..aOM<ButtonEvent>(2, _omitFieldNames ? '' : 'button',
        subBuilder: ButtonEvent.$_createMessage)
    ..aOM<Scroll>(3, _omitFieldNames ? '' : 'scroll',
        subBuilder: Scroll.$_createMessage)
    ..aOM<KeyEvent>(4, _omitFieldNames ? '' : 'key',
        subBuilder: KeyEvent.$_createMessage)
    ..aOM<TextInput>(5, _omitFieldNames ? '' : 'text',
        subBuilder: TextInput.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InputEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InputEvent copyWith(void Function(InputEvent) updates) =>
      super.copyWith((message) => updates(message as InputEvent)) as InputEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use InputEvent() / InputEvent.new instead')
  static InputEvent create() => InputEvent._();
  static $pb.GeneratedMessage $_createMessage() => InputEvent._();
  @$core.override
  InputEvent createEmptyInstance() => InputEvent._();
  @$core.pragma('dart2js:noInline')
  static InputEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InputEvent>(InputEvent.$_createMessage);
  static InputEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  InputEvent_Kind whichKind() => _InputEvent_KindByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  void clearKind() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  PointerMove get move => $_getN(0);
  @$pb.TagNumber(1)
  set move(PointerMove value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMove() => $_has(0);
  @$pb.TagNumber(1)
  void clearMove() => $_clearField(1);
  @$pb.TagNumber(1)
  PointerMove ensureMove() => $_ensure(0);

  @$pb.TagNumber(2)
  ButtonEvent get button => $_getN(1);
  @$pb.TagNumber(2)
  set button(ButtonEvent value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasButton() => $_has(1);
  @$pb.TagNumber(2)
  void clearButton() => $_clearField(2);
  @$pb.TagNumber(2)
  ButtonEvent ensureButton() => $_ensure(1);

  @$pb.TagNumber(3)
  Scroll get scroll => $_getN(2);
  @$pb.TagNumber(3)
  set scroll(Scroll value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasScroll() => $_has(2);
  @$pb.TagNumber(3)
  void clearScroll() => $_clearField(3);
  @$pb.TagNumber(3)
  Scroll ensureScroll() => $_ensure(2);

  @$pb.TagNumber(4)
  KeyEvent get key => $_getN(3);
  @$pb.TagNumber(4)
  set key(KeyEvent value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearKey() => $_clearField(4);
  @$pb.TagNumber(4)
  KeyEvent ensureKey() => $_ensure(3);

  @$pb.TagNumber(5)
  TextInput get text => $_getN(4);
  @$pb.TagNumber(5)
  set text(TextInput value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasText() => $_has(4);
  @$pb.TagNumber(5)
  void clearText() => $_clearField(5);
  @$pb.TagNumber(5)
  TextInput ensureText() => $_ensure(4);
}

/// Input from the controller, in order, without expecting a reply. The
/// controller sends at most about 60 a second and merges pointer moves in
/// between, so a batch holds what happened since the last one.
class InputBatch extends $pb.GeneratedMessage {
  factory InputBatch({
    $core.Iterable<InputEvent>? events,
  }) {
    final result = InputBatch._();
    if (events != null) result.events.addAll(events);
    return result;
  }

  InputBatch._();

  factory InputBatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InputBatch()..mergeFromBuffer(data, registry);
  factory InputBatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InputBatch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InputBatch',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'ferret.remote_input.v1'),
      createEmptyInstance: InputBatch.$_createMessage)
    ..pPM<InputEvent>(1, _omitFieldNames ? '' : 'events',
        subBuilder: InputEvent.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InputBatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InputBatch copyWith(void Function(InputBatch) updates) =>
      super.copyWith((message) => updates(message as InputBatch)) as InputBatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use InputBatch() / InputBatch.new instead')
  static InputBatch create() => InputBatch._();
  static $pb.GeneratedMessage $_createMessage() => InputBatch._();
  @$core.override
  InputBatch createEmptyInstance() => InputBatch._();
  @$core.pragma('dart2js:noInline')
  static InputBatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InputBatch>(InputBatch.$_createMessage);
  static InputBatch? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<InputEvent> get events => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
