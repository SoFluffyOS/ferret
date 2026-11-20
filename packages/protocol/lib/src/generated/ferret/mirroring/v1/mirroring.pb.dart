// This is a generated file - do not edit.
//
// Generated from ferret/mirroring/v1/mirroring.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'mirroring.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'mirroring.pbenum.dart';

/// What a viewer wants from the camera. The size and frame rate come from
/// `StartRequest.max_width`, `max_height` and `max_fps` like a screen's; a
/// source left to itself sends 1280 by 720 at 30 frames per second.
class CameraOptions extends $pb.GeneratedMessage {
  factory CameraOptions({
    CameraLens? lens,
  }) {
    final result = CameraOptions._();
    if (lens != null) result.lens = lens;
    return result;
  }

  CameraOptions._();

  factory CameraOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CameraOptions()..mergeFromBuffer(data, registry);
  factory CameraOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CameraOptions()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CameraOptions',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: CameraOptions.$_createMessage)
    ..aE<CameraLens>(1, _omitFieldNames ? '' : 'lens',
        enumValues: CameraLens.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraOptions copyWith(void Function(CameraOptions) updates) =>
      super.copyWith((message) => updates(message as CameraOptions))
          as CameraOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CameraOptions() / CameraOptions.new instead')
  static CameraOptions create() => CameraOptions._();
  static $pb.GeneratedMessage $_createMessage() => CameraOptions._();
  @$core.override
  CameraOptions createEmptyInstance() => CameraOptions._();
  @$core.pragma('dart2js:noInline')
  static CameraOptions getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CameraOptions>(
          CameraOptions.$_createMessage);
  static CameraOptions? _defaultInstance;

  /// The camera to start with. A source that doesn't have it uses another.
  @$pb.TagNumber(1)
  CameraLens get lens => $_getN(0);
  @$pb.TagNumber(1)
  set lens(CameraLens value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLens() => $_has(0);
  @$pb.TagNumber(1)
  void clearLens() => $_clearField(1);
}

/// Asks the source to show its screen, its camera, or the display it
/// offered. Expects a
/// `StartPending` or `StartDeny` reply. After `StartPending`, the source sends `StartAccept`
/// or `StartDeny` later, without expecting a reply.
class StartRequest extends $pb.GeneratedMessage {
  factory StartRequest({
    $core.int? version,
    $core.Iterable<Codec>? codecs,
    $core.int? maxWidth,
    $core.int? maxHeight,
    $core.int? maxFps,
    $core.Iterable<AudioCodec>? audioCodecs,
    Source? source,
    CameraOptions? camera,
    DisplayPanel? display,
  }) {
    final result = StartRequest._();
    if (version != null) result.version = version;
    if (codecs != null) result.codecs.addAll(codecs);
    if (maxWidth != null) result.maxWidth = maxWidth;
    if (maxHeight != null) result.maxHeight = maxHeight;
    if (maxFps != null) result.maxFps = maxFps;
    if (audioCodecs != null) result.audioCodecs.addAll(audioCodecs);
    if (source != null) result.source = source;
    if (camera != null) result.camera = camera;
    if (display != null) result.display = display;
    return result;
  }

  StartRequest._();

  factory StartRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartRequest()..mergeFromBuffer(data, registry);
  factory StartRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: StartRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'version', fieldType: $pb.PbFieldType.OU3)
    ..pc<Codec>(2, _omitFieldNames ? '' : 'codecs', $pb.PbFieldType.KE,
        valueOf: Codec.valueOf,
        enumValues: Codec.values,
        defaultEnumValue: Codec.CODEC_UNSPECIFIED)
    ..aI(3, _omitFieldNames ? '' : 'maxWidth', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'maxHeight', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'maxFps', fieldType: $pb.PbFieldType.OU3)
    ..pc<AudioCodec>(
        6, _omitFieldNames ? '' : 'audioCodecs', $pb.PbFieldType.KE,
        valueOf: AudioCodec.valueOf,
        enumValues: AudioCodec.values,
        defaultEnumValue: AudioCodec.AUDIO_CODEC_UNSPECIFIED)
    ..aE<Source>(7, _omitFieldNames ? '' : 'source', enumValues: Source.values)
    ..aOM<CameraOptions>(8, _omitFieldNames ? '' : 'camera',
        subBuilder: CameraOptions.$_createMessage)
    ..aOM<DisplayPanel>(9, _omitFieldNames ? '' : 'display',
        subBuilder: DisplayPanel.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartRequest copyWith(void Function(StartRequest) updates) =>
      super.copyWith((message) => updates(message as StartRequest))
          as StartRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StartRequest() / StartRequest.new instead')
  static StartRequest create() => StartRequest._();
  static $pb.GeneratedMessage $_createMessage() => StartRequest._();
  @$core.override
  StartRequest createEmptyInstance() => StartRequest._();
  @$core.pragma('dart2js:noInline')
  static StartRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartRequest>(
          StartRequest.$_createMessage);
  static StartRequest? _defaultInstance;

  /// The version of these messages the viewer speaks.
  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  /// What the viewer can decode, best first.
  @$pb.TagNumber(2)
  $pb.PbList<Codec> get codecs => $_getList(1);

  /// The largest picture the viewer wants, in pixels. 0 leaves it to the
  /// source, which never sends more than 1920 on the long side.
  @$pb.TagNumber(3)
  $core.int get maxWidth => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxWidth($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxWidth() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxWidth() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get maxHeight => $_getIZ(3);
  @$pb.TagNumber(4)
  set maxHeight($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMaxHeight() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaxHeight() => $_clearField(4);

  /// 0 leaves it to the source.
  @$pb.TagNumber(5)
  $core.int get maxFps => $_getIZ(4);
  @$pb.TagNumber(5)
  set maxFps($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMaxFps() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxFps() => $_clearField(5);

  /// What the viewer can play of the source's sound, best first. Empty asks
  /// for pictures only.
  @$pb.TagNumber(6)
  $pb.PbList<AudioCodec> get audioCodecs => $_getList(5);

  /// What to send. Only set to `SOURCE_CAMERA` for a source whose feature
  /// support has the `camera` flag.
  @$pb.TagNumber(7)
  Source get source => $_getN(6);
  @$pb.TagNumber(7)
  set source(Source value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasSource() => $_has(6);
  @$pb.TagNumber(7)
  void clearSource() => $_clearField(7);

  /// With `SOURCE_CAMERA` only.
  @$pb.TagNumber(8)
  CameraOptions get camera => $_getN(7);
  @$pb.TagNumber(8)
  set camera(CameraOptions value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasCamera() => $_has(7);
  @$pb.TagNumber(8)
  void clearCamera() => $_clearField(8);
  @$pb.TagNumber(8)
  CameraOptions ensureCamera() => $_ensure(7);

  /// With `SOURCE_DISPLAY` only.
  @$pb.TagNumber(9)
  DisplayPanel get display => $_getN(8);
  @$pb.TagNumber(9)
  set display(DisplayPanel value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasDisplay() => $_has(8);
  @$pb.TagNumber(9)
  void clearDisplay() => $_clearField(9);
  @$pb.TagNumber(9)
  DisplayPanel ensureDisplay() => $_ensure(8);
}

/// The viewer's screen, for a source that makes a display to fill it.
class DisplayPanel extends $pb.GeneratedMessage {
  factory DisplayPanel({
    $core.int? width,
    $core.int? height,
    $core.int? scale,
    $core.int? refreshHz,
  }) {
    final result = DisplayPanel._();
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (scale != null) result.scale = scale;
    if (refreshHz != null) result.refreshHz = refreshHz;
    return result;
  }

  DisplayPanel._();

  factory DisplayPanel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisplayPanel()..mergeFromBuffer(data, registry);
  factory DisplayPanel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisplayPanel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisplayPanel',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: DisplayPanel.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'width', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'height', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'scale', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'refreshHz', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisplayPanel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisplayPanel copyWith(void Function(DisplayPanel) updates) =>
      super.copyWith((message) => updates(message as DisplayPanel))
          as DisplayPanel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DisplayPanel() / DisplayPanel.new instead')
  static DisplayPanel create() => DisplayPanel._();
  static $pb.GeneratedMessage $_createMessage() => DisplayPanel._();
  @$core.override
  DisplayPanel createEmptyInstance() => DisplayPanel._();
  @$core.pragma('dart2js:noInline')
  static DisplayPanel getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DisplayPanel>(
          DisplayPanel.$_createMessage);
  static DisplayPanel? _defaultInstance;

  /// The screen's size in pixels, as it is held now.
  @$pb.TagNumber(1)
  $core.int get width => $_getIZ(0);
  @$pb.TagNumber(1)
  set width($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWidth() => $_has(0);
  @$pb.TagNumber(1)
  void clearWidth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get height => $_getIZ(1);
  @$pb.TagNumber(2)
  set height($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeight() => $_clearField(2);

  /// Pixels per point: 2 for a sharp (Retina) screen, 1 otherwise. 0
  /// counts as 1.
  @$pb.TagNumber(3)
  $core.int get scale => $_getIZ(2);
  @$pb.TagNumber(3)
  set scale($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasScale() => $_has(2);
  @$pb.TagNumber(3)
  void clearScale() => $_clearField(3);

  /// How many times a second the screen redraws. 0 leaves it to the
  /// source, which uses 60.
  @$pb.TagNumber(4)
  $core.int get refreshHz => $_getIZ(3);
  @$pb.TagNumber(4)
  set refreshHz($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRefreshHz() => $_has(3);
  @$pb.TagNumber(4)
  void clearRefreshHz() => $_clearField(4);
}

/// A computer offers to extend its desktop onto this device, which would
/// become its extra display. Expects a `StartPending` reply while this
/// device asks its owner, or a `StartDeny` at once. The owner's yes follows
/// as a `StartRequest` with `SOURCE_DISPLAY`, a no as a `DisplayDecline`.
/// The source takes back an offer nobody answered yet with `Stop`.
class DisplayOffer extends $pb.GeneratedMessage {
  factory DisplayOffer({
    $core.int? version,
  }) {
    final result = DisplayOffer._();
    if (version != null) result.version = version;
    return result;
  }

  DisplayOffer._();

  factory DisplayOffer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisplayOffer()..mergeFromBuffer(data, registry);
  factory DisplayOffer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisplayOffer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisplayOffer',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: DisplayOffer.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'version', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisplayOffer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisplayOffer copyWith(void Function(DisplayOffer) updates) =>
      super.copyWith((message) => updates(message as DisplayOffer))
          as DisplayOffer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DisplayOffer() / DisplayOffer.new instead')
  static DisplayOffer create() => DisplayOffer._();
  static $pb.GeneratedMessage $_createMessage() => DisplayOffer._();
  @$core.override
  DisplayOffer createEmptyInstance() => DisplayOffer._();
  @$core.pragma('dart2js:noInline')
  static DisplayOffer getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DisplayOffer>(
          DisplayOffer.$_createMessage);
  static DisplayOffer? _defaultInstance;

  /// The version of these messages the source speaks.
  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);
}

/// The viewer's owner said no to a `DisplayOffer`, or nobody answered in
/// time. Sent without expecting a reply.
class DisplayDecline extends $pb.GeneratedMessage {
  factory DisplayDecline({
    DenyReason? reason,
  }) {
    final result = DisplayDecline._();
    if (reason != null) result.reason = reason;
    return result;
  }

  DisplayDecline._();

  factory DisplayDecline.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisplayDecline()..mergeFromBuffer(data, registry);
  factory DisplayDecline.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisplayDecline()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisplayDecline',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: DisplayDecline.$_createMessage)
    ..aE<DenyReason>(1, _omitFieldNames ? '' : 'reason',
        enumValues: DenyReason.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisplayDecline clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisplayDecline copyWith(void Function(DisplayDecline) updates) =>
      super.copyWith((message) => updates(message as DisplayDecline))
          as DisplayDecline;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DisplayDecline() / DisplayDecline.new instead')
  static DisplayDecline create() => DisplayDecline._();
  static $pb.GeneratedMessage $_createMessage() => DisplayDecline._();
  @$core.override
  DisplayDecline createEmptyInstance() => DisplayDecline._();
  @$core.pragma('dart2js:noInline')
  static DisplayDecline getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DisplayDecline>(
          DisplayDecline.$_createMessage);
  static DisplayDecline? _defaultInstance;

  /// `DENY_REASON_DENIED` or `DENY_REASON_TIMEOUT`.
  @$pb.TagNumber(1)
  DenyReason get reason => $_getN(0);
  @$pb.TagNumber(1)
  set reason(DenyReason value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReason() => $_has(0);
  @$pb.TagNumber(1)
  void clearReason() => $_clearField(1);
}

/// The source is asking its owner. The answer follows as `StartAccept` or
/// `StartDeny`.
class StartPending extends $pb.GeneratedMessage {
  factory StartPending({
    $core.int? timeoutSeconds,
  }) {
    final result = StartPending._();
    if (timeoutSeconds != null) result.timeoutSeconds = timeoutSeconds;
    return result;
  }

  StartPending._();

  factory StartPending.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartPending()..mergeFromBuffer(data, registry);
  factory StartPending.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartPending()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartPending',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: StartPending.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'timeoutSeconds',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartPending clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartPending copyWith(void Function(StartPending) updates) =>
      super.copyWith((message) => updates(message as StartPending))
          as StartPending;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StartPending() / StartPending.new instead')
  static StartPending create() => StartPending._();
  static $pb.GeneratedMessage $_createMessage() => StartPending._();
  @$core.override
  StartPending createEmptyInstance() => StartPending._();
  @$core.pragma('dart2js:noInline')
  static StartPending getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartPending>(
          StartPending.$_createMessage);
  static StartPending? _defaultInstance;

  /// How long the source waits for its owner before it denies with
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

/// The owner said yes. A `StreamConfig` and `Frame`s follow until either
/// side sends `Stop`.
class StartAccept extends $pb.GeneratedMessage {
  factory StartAccept({
    $core.int? version,
    Codec? codec,
    AudioAnswer? audio,
    AudioCodec? audioCodec,
  }) {
    final result = StartAccept._();
    if (version != null) result.version = version;
    if (codec != null) result.codec = codec;
    if (audio != null) result.audio = audio;
    if (audioCodec != null) result.audioCodec = audioCodec;
    return result;
  }

  StartAccept._();

  factory StartAccept.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartAccept()..mergeFromBuffer(data, registry);
  factory StartAccept.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartAccept()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartAccept',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: StartAccept.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'version', fieldType: $pb.PbFieldType.OU3)
    ..aE<Codec>(2, _omitFieldNames ? '' : 'codec', enumValues: Codec.values)
    ..aE<AudioAnswer>(3, _omitFieldNames ? '' : 'audio',
        enumValues: AudioAnswer.values)
    ..aE<AudioCodec>(4, _omitFieldNames ? '' : 'audioCodec',
        enumValues: AudioCodec.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartAccept clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartAccept copyWith(void Function(StartAccept) updates) =>
      super.copyWith((message) => updates(message as StartAccept))
          as StartAccept;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StartAccept() / StartAccept.new instead')
  static StartAccept create() => StartAccept._();
  static $pb.GeneratedMessage $_createMessage() => StartAccept._();
  @$core.override
  StartAccept createEmptyInstance() => StartAccept._();
  @$core.pragma('dart2js:noInline')
  static StartAccept getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartAccept>(
          StartAccept.$_createMessage);
  static StartAccept? _defaultInstance;

  /// The version of these messages the source speaks.
  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  /// The codec the source picked from `StartRequest.codecs`.
  @$pb.TagNumber(2)
  Codec get codec => $_getN(1);
  @$pb.TagNumber(2)
  set codec(Codec value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCodec() => $_has(1);
  @$pb.TagNumber(2)
  void clearCodec() => $_clearField(2);

  /// Whether sound comes with the pictures, for a viewer that asked.
  @$pb.TagNumber(3)
  AudioAnswer get audio => $_getN(2);
  @$pb.TagNumber(3)
  set audio(AudioAnswer value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAudio() => $_has(2);
  @$pb.TagNumber(3)
  void clearAudio() => $_clearField(3);

  /// With `AUDIO_ANSWER_SENDING`: the codec the source picked from
  /// `StartRequest.audio_codecs`.
  @$pb.TagNumber(4)
  AudioCodec get audioCodec => $_getN(3);
  @$pb.TagNumber(4)
  set audioCodec(AudioCodec value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAudioCodec() => $_has(3);
  @$pb.TagNumber(4)
  void clearAudioCodec() => $_clearField(4);
}

class StartDeny extends $pb.GeneratedMessage {
  factory StartDeny({
    DenyReason? reason,
  }) {
    final result = StartDeny._();
    if (reason != null) result.reason = reason;
    return result;
  }

  StartDeny._();

  factory StartDeny.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartDeny()..mergeFromBuffer(data, registry);
  factory StartDeny.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartDeny()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartDeny',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: StartDeny.$_createMessage)
    ..aE<DenyReason>(1, _omitFieldNames ? '' : 'reason',
        enumValues: DenyReason.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartDeny clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartDeny copyWith(void Function(StartDeny) updates) =>
      super.copyWith((message) => updates(message as StartDeny)) as StartDeny;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StartDeny() / StartDeny.new instead')
  static StartDeny create() => StartDeny._();
  static $pb.GeneratedMessage $_createMessage() => StartDeny._();
  @$core.override
  StartDeny createEmptyInstance() => StartDeny._();
  @$core.pragma('dart2js:noInline')
  static StartDeny getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartDeny>(StartDeny.$_createMessage);
  static StartDeny? _defaultInstance;

  @$pb.TagNumber(1)
  DenyReason get reason => $_getN(0);
  @$pb.TagNumber(1)
  set reason(DenyReason value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReason() => $_has(0);
  @$pb.TagNumber(1)
  void clearReason() => $_clearField(1);
}

/// How to decode the frames that follow. The source sends it before the
/// first frame, and again with a new `config_id` when the picture changes,
/// such as when the phone is rotated.
class StreamConfig extends $pb.GeneratedMessage {
  factory StreamConfig({
    $core.int? configId,
    Codec? codec,
    $core.int? width,
    $core.int? height,
    $core.int? rotation,
    $core.int? fps,
    $core.List<$core.int>? sps,
    $core.List<$core.int>? pps,
    $core.int? turn,
  }) {
    final result = StreamConfig._();
    if (configId != null) result.configId = configId;
    if (codec != null) result.codec = codec;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (rotation != null) result.rotation = rotation;
    if (fps != null) result.fps = fps;
    if (sps != null) result.sps = sps;
    if (pps != null) result.pps = pps;
    if (turn != null) result.turn = turn;
    return result;
  }

  StreamConfig._();

  factory StreamConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamConfig()..mergeFromBuffer(data, registry);
  factory StreamConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamConfig()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamConfig',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: StreamConfig.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'configId', fieldType: $pb.PbFieldType.OU3)
    ..aE<Codec>(2, _omitFieldNames ? '' : 'codec', enumValues: Codec.values)
    ..aI(3, _omitFieldNames ? '' : 'width', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'height', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'rotation', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'fps', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'sps', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'pps', $pb.PbFieldType.OY)
    ..aI(9, _omitFieldNames ? '' : 'turn', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamConfig copyWith(void Function(StreamConfig) updates) =>
      super.copyWith((message) => updates(message as StreamConfig))
          as StreamConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StreamConfig() / StreamConfig.new instead')
  static StreamConfig create() => StreamConfig._();
  static $pb.GeneratedMessage $_createMessage() => StreamConfig._();
  @$core.override
  StreamConfig createEmptyInstance() => StreamConfig._();
  @$core.pragma('dart2js:noInline')
  static StreamConfig getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StreamConfig>(
          StreamConfig.$_createMessage);
  static StreamConfig? _defaultInstance;

  /// Goes up by one with every new config in a mirroring session.
  @$pb.TagNumber(1)
  $core.int get configId => $_getIZ(0);
  @$pb.TagNumber(1)
  set configId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConfigId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfigId() => $_clearField(1);

  @$pb.TagNumber(2)
  Codec get codec => $_getN(1);
  @$pb.TagNumber(2)
  set codec(Codec value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCodec() => $_has(1);
  @$pb.TagNumber(2)
  void clearCodec() => $_clearField(2);

  /// Size of the picture in pixels, as it should be shown.
  @$pb.TagNumber(3)
  $core.int get width => $_getIZ(2);
  @$pb.TagNumber(3)
  set width($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWidth() => $_has(2);
  @$pb.TagNumber(3)
  void clearWidth() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get height => $_getIZ(3);
  @$pb.TagNumber(4)
  set height($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHeight() => $_has(3);
  @$pb.TagNumber(4)
  void clearHeight() => $_clearField(4);

  /// How the source's screen is rotated, in degrees clockwise: 0, 90, 180 or
  /// 270. The picture is already upright; this is for information.
  @$pb.TagNumber(5)
  $core.int get rotation => $_getIZ(4);
  @$pb.TagNumber(5)
  set rotation($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRotation() => $_has(4);
  @$pb.TagNumber(5)
  void clearRotation() => $_clearField(5);

  /// The most frames per second the source sends.
  @$pb.TagNumber(6)
  $core.int get fps => $_getIZ(5);
  @$pb.TagNumber(6)
  set fps($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFps() => $_has(5);
  @$pb.TagNumber(6)
  void clearFps() => $_clearField(6);

  /// H.264 only: the sequence and picture parameter sets, each one NAL unit
  /// without a start code.
  @$pb.TagNumber(7)
  $core.List<$core.int> get sps => $_getN(6);
  @$pb.TagNumber(7)
  set sps($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSps() => $_has(6);
  @$pb.TagNumber(7)
  void clearSps() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.List<$core.int> get pps => $_getN(7);
  @$pb.TagNumber(8)
  set pps($core.List<$core.int> value) => $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPps() => $_has(7);
  @$pb.TagNumber(8)
  void clearPps() => $_clearField(8);

  /// A camera only: how far the viewer turns the picture clockwise to show
  /// it upright, in degrees: 0, 90, 180 or 270. `width` and `height` are
  /// the picture's before it is turned. A camera sends its pictures as its
  /// sensor sees them, and a new config when the phone is turned.
  @$pb.TagNumber(9)
  $core.int get turn => $_getIZ(8);
  @$pb.TagNumber(9)
  set turn($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTurn() => $_has(8);
  @$pb.TagNumber(9)
  void clearTurn() => $_clearField(9);
}

/// One picture. Sent without expecting a reply.
class Frame extends $pb.GeneratedMessage {
  factory Frame({
    $core.int? configId,
    $fixnum.Int64? sequence,
    $fixnum.Int64? ptsUs,
    $core.bool? keyframe,
    $core.List<$core.int>? data,
  }) {
    final result = Frame._();
    if (configId != null) result.configId = configId;
    if (sequence != null) result.sequence = sequence;
    if (ptsUs != null) result.ptsUs = ptsUs;
    if (keyframe != null) result.keyframe = keyframe;
    if (data != null) result.data = data;
    return result;
  }

  Frame._();

  factory Frame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Frame()..mergeFromBuffer(data, registry);
  factory Frame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Frame()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Frame',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: Frame.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'configId', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aInt64(3, _omitFieldNames ? '' : 'ptsUs')
    ..aOB(4, _omitFieldNames ? '' : 'keyframe')
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Frame clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Frame copyWith(void Function(Frame) updates) =>
      super.copyWith((message) => updates(message as Frame)) as Frame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Frame() / Frame.new instead')
  static Frame create() => Frame._();
  static $pb.GeneratedMessage $_createMessage() => Frame._();
  @$core.override
  Frame createEmptyInstance() => Frame._();
  @$core.pragma('dart2js:noInline')
  static Frame getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Frame>(Frame.$_createMessage);
  static Frame? _defaultInstance;

  /// The `StreamConfig` this frame belongs to. A viewer drops frames of a
  /// config it hasn't seen.
  @$pb.TagNumber(1)
  $core.int get configId => $_getIZ(0);
  @$pb.TagNumber(1)
  set configId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConfigId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfigId() => $_clearField(1);

  /// Goes up by one with every frame the source produced, including those
  /// it dropped, so a gap tells the viewer how many were dropped.
  @$pb.TagNumber(2)
  $fixnum.Int64 get sequence => $_getI64(1);
  @$pb.TagNumber(2)
  set sequence($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSequence() => $_has(1);
  @$pb.TagNumber(2)
  void clearSequence() => $_clearField(2);

  /// When the picture was captured, in microseconds on the source's own
  /// clock. Only differences mean something.
  @$pb.TagNumber(3)
  $fixnum.Int64 get ptsUs => $_getI64(2);
  @$pb.TagNumber(3)
  set ptsUs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPtsUs() => $_has(2);
  @$pb.TagNumber(3)
  void clearPtsUs() => $_clearField(3);

  /// The frame decodes on its own. After a gap, a viewer waits for one.
  @$pb.TagNumber(4)
  $core.bool get keyframe => $_getBF(3);
  @$pb.TagNumber(4)
  set keyframe($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasKeyframe() => $_has(3);
  @$pb.TagNumber(4)
  void clearKeyframe() => $_clearField(4);

  /// H.264: one access unit in Annex-B form. JPEG: the picture.
  @$pb.TagNumber(5)
  $core.List<$core.int> get data => $_getN(4);
  @$pb.TagNumber(5)
  set data($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasData() => $_has(4);
  @$pb.TagNumber(5)
  void clearData() => $_clearField(5);
}

/// How to play the sound that follows. The source sends it before the first
/// `AudioFrame`, and again after a viewer came back from a dropped
/// connection.
class AudioConfig extends $pb.GeneratedMessage {
  factory AudioConfig({
    AudioCodec? codec,
    $core.int? sampleRate,
    $core.int? channels,
  }) {
    final result = AudioConfig._();
    if (codec != null) result.codec = codec;
    if (sampleRate != null) result.sampleRate = sampleRate;
    if (channels != null) result.channels = channels;
    return result;
  }

  AudioConfig._();

  factory AudioConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioConfig()..mergeFromBuffer(data, registry);
  factory AudioConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioConfig()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioConfig',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: AudioConfig.$_createMessage)
    ..aE<AudioCodec>(1, _omitFieldNames ? '' : 'codec',
        enumValues: AudioCodec.values)
    ..aI(2, _omitFieldNames ? '' : 'sampleRate', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'channels', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioConfig copyWith(void Function(AudioConfig) updates) =>
      super.copyWith((message) => updates(message as AudioConfig))
          as AudioConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AudioConfig() / AudioConfig.new instead')
  static AudioConfig create() => AudioConfig._();
  static $pb.GeneratedMessage $_createMessage() => AudioConfig._();
  @$core.override
  AudioConfig createEmptyInstance() => AudioConfig._();
  @$core.pragma('dart2js:noInline')
  static AudioConfig getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AudioConfig>(
          AudioConfig.$_createMessage);
  static AudioConfig? _defaultInstance;

  @$pb.TagNumber(1)
  AudioCodec get codec => $_getN(0);
  @$pb.TagNumber(1)
  set codec(AudioCodec value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCodec() => $_has(0);
  @$pb.TagNumber(1)
  void clearCodec() => $_clearField(1);

  /// Samples per second of each channel.
  @$pb.TagNumber(2)
  $core.int get sampleRate => $_getIZ(1);
  @$pb.TagNumber(2)
  set sampleRate($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSampleRate() => $_has(1);
  @$pb.TagNumber(2)
  void clearSampleRate() => $_clearField(2);

  /// 1 or 2. With two, samples are interleaved left then right.
  @$pb.TagNumber(3)
  $core.int get channels => $_getIZ(2);
  @$pb.TagNumber(3)
  set channels($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChannels() => $_has(2);
  @$pb.TagNumber(3)
  void clearChannels() => $_clearField(3);
}

/// A few milliseconds of what plays on the source. Sent without expecting a
/// reply. Apps on the source that don't allow their sound to be captured are
/// simply not in it, and nothing is sent while the source is silent.
class AudioFrame extends $pb.GeneratedMessage {
  factory AudioFrame({
    $fixnum.Int64? sequence,
    $fixnum.Int64? ptsUs,
    $core.List<$core.int>? data,
  }) {
    final result = AudioFrame._();
    if (sequence != null) result.sequence = sequence;
    if (ptsUs != null) result.ptsUs = ptsUs;
    if (data != null) result.data = data;
    return result;
  }

  AudioFrame._();

  factory AudioFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioFrame()..mergeFromBuffer(data, registry);
  factory AudioFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioFrame()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioFrame',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: AudioFrame.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aInt64(2, _omitFieldNames ? '' : 'ptsUs')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioFrame clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioFrame copyWith(void Function(AudioFrame) updates) =>
      super.copyWith((message) => updates(message as AudioFrame)) as AudioFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AudioFrame() / AudioFrame.new instead')
  static AudioFrame create() => AudioFrame._();
  static $pb.GeneratedMessage $_createMessage() => AudioFrame._();
  @$core.override
  AudioFrame createEmptyInstance() => AudioFrame._();
  @$core.pragma('dart2js:noInline')
  static AudioFrame getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioFrame>(AudioFrame.$_createMessage);
  static AudioFrame? _defaultInstance;

  /// Goes up by one with every frame the source produced, including those it
  /// dropped because the connection backed up.
  @$pb.TagNumber(1)
  $fixnum.Int64 get sequence => $_getI64(0);
  @$pb.TagNumber(1)
  set sequence($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSequence() => $_has(0);
  @$pb.TagNumber(1)
  void clearSequence() => $_clearField(1);

  /// When the sound was captured, in microseconds on the same clock as
  /// `Frame.pts_us`, so a viewer can keep sound and picture together.
  @$pb.TagNumber(2)
  $fixnum.Int64 get ptsUs => $_getI64(1);
  @$pb.TagNumber(2)
  set ptsUs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPtsUs() => $_has(1);
  @$pb.TagNumber(2)
  void clearPtsUs() => $_clearField(2);

  /// Opus: one packet. PCM: whole samples for every channel.
  @$pb.TagNumber(3)
  $core.List<$core.int> get data => $_getN(2);
  @$pb.TagNumber(3)
  set data($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => $_clearField(3);
}

/// The source's sound stopped, such as when capturing it failed. The
/// pictures go on. Sent without expecting a reply.
class AudioEnded extends $pb.GeneratedMessage {
  factory AudioEnded() => AudioEnded._();

  AudioEnded._();

  factory AudioEnded.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioEnded()..mergeFromBuffer(data, registry);
  factory AudioEnded.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioEnded()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioEnded',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: AudioEnded.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioEnded clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioEnded copyWith(void Function(AudioEnded) updates) =>
      super.copyWith((message) => updates(message as AudioEnded)) as AudioEnded;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AudioEnded() / AudioEnded.new instead')
  static AudioEnded create() => AudioEnded._();
  static $pb.GeneratedMessage $_createMessage() => AudioEnded._();
  @$core.override
  AudioEnded createEmptyInstance() => AudioEnded._();
  @$core.pragma('dart2js:noInline')
  static AudioEnded getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioEnded>(AudioEnded.$_createMessage);
  static AudioEnded? _defaultInstance;
}

/// Sent by a source that sends its camera, after `StartAccept` and again
/// whenever the camera changes. Expects no reply.
class CameraState extends $pb.GeneratedMessage {
  factory CameraState({
    CameraLens? lens,
    $core.Iterable<CameraLens>? lenses,
  }) {
    final result = CameraState._();
    if (lens != null) result.lens = lens;
    if (lenses != null) result.lenses.addAll(lenses);
    return result;
  }

  CameraState._();

  factory CameraState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CameraState()..mergeFromBuffer(data, registry);
  factory CameraState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CameraState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CameraState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: CameraState.$_createMessage)
    ..aE<CameraLens>(1, _omitFieldNames ? '' : 'lens',
        enumValues: CameraLens.values)
    ..pc<CameraLens>(2, _omitFieldNames ? '' : 'lenses', $pb.PbFieldType.KE,
        valueOf: CameraLens.valueOf,
        enumValues: CameraLens.values,
        defaultEnumValue: CameraLens.CAMERA_LENS_UNSPECIFIED)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraState copyWith(void Function(CameraState) updates) =>
      super.copyWith((message) => updates(message as CameraState))
          as CameraState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CameraState() / CameraState.new instead')
  static CameraState create() => CameraState._();
  static $pb.GeneratedMessage $_createMessage() => CameraState._();
  @$core.override
  CameraState createEmptyInstance() => CameraState._();
  @$core.pragma('dart2js:noInline')
  static CameraState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CameraState>(
          CameraState.$_createMessage);
  static CameraState? _defaultInstance;

  /// The camera that is on.
  @$pb.TagNumber(1)
  CameraLens get lens => $_getN(0);
  @$pb.TagNumber(1)
  set lens(CameraLens value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLens() => $_has(0);
  @$pb.TagNumber(1)
  void clearLens() => $_clearField(1);

  /// Every camera a `CameraSwitch` can pick.
  @$pb.TagNumber(2)
  $pb.PbList<CameraLens> get lenses => $_getList(1);
}

/// The viewer picks another of the source's cameras. The source answers
/// with a `CameraState` and a new `StreamConfig`. Ignored unless the
/// source's camera is on for this viewer. Expects no reply.
class CameraSwitch extends $pb.GeneratedMessage {
  factory CameraSwitch({
    CameraLens? lens,
  }) {
    final result = CameraSwitch._();
    if (lens != null) result.lens = lens;
    return result;
  }

  CameraSwitch._();

  factory CameraSwitch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CameraSwitch()..mergeFromBuffer(data, registry);
  factory CameraSwitch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CameraSwitch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CameraSwitch',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: CameraSwitch.$_createMessage)
    ..aE<CameraLens>(1, _omitFieldNames ? '' : 'lens',
        enumValues: CameraLens.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraSwitch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CameraSwitch copyWith(void Function(CameraSwitch) updates) =>
      super.copyWith((message) => updates(message as CameraSwitch))
          as CameraSwitch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CameraSwitch() / CameraSwitch.new instead')
  static CameraSwitch create() => CameraSwitch._();
  static $pb.GeneratedMessage $_createMessage() => CameraSwitch._();
  @$core.override
  CameraSwitch createEmptyInstance() => CameraSwitch._();
  @$core.pragma('dart2js:noInline')
  static CameraSwitch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CameraSwitch>(
          CameraSwitch.$_createMessage);
  static CameraSwitch? _defaultInstance;

  @$pb.TagNumber(1)
  CameraLens get lens => $_getN(0);
  @$pb.TagNumber(1)
  set lens(CameraLens value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLens() => $_has(0);
  @$pb.TagNumber(1)
  void clearLens() => $_clearField(1);
}

/// The viewer lost its place, such as after a decoding error, and asks for a
/// frame that decodes on its own. Sent without expecting a reply.
class KeyframeRequest extends $pb.GeneratedMessage {
  factory KeyframeRequest() => KeyframeRequest._();

  KeyframeRequest._();

  factory KeyframeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeyframeRequest()..mergeFromBuffer(data, registry);
  factory KeyframeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeyframeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KeyframeRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: KeyframeRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyframeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyframeRequest copyWith(void Function(KeyframeRequest) updates) =>
      super.copyWith((message) => updates(message as KeyframeRequest))
          as KeyframeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use KeyframeRequest() / KeyframeRequest.new instead')
  static KeyframeRequest create() => KeyframeRequest._();
  static $pb.GeneratedMessage $_createMessage() => KeyframeRequest._();
  @$core.override
  KeyframeRequest createEmptyInstance() => KeyframeRequest._();
  @$core.pragma('dart2js:noInline')
  static KeyframeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<KeyframeRequest>(
          KeyframeRequest.$_createMessage);
  static KeyframeRequest? _defaultInstance;
}

/// Ends mirroring. Either side sends it, without expecting a reply. The
/// source stops capturing at once.
class Stop extends $pb.GeneratedMessage {
  factory Stop({
    StopReason? reason,
  }) {
    final result = Stop._();
    if (reason != null) result.reason = reason;
    return result;
  }

  Stop._();

  factory Stop.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Stop()..mergeFromBuffer(data, registry);
  factory Stop.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Stop()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Stop',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: Stop.$_createMessage)
    ..aE<StopReason>(1, _omitFieldNames ? '' : 'reason',
        enumValues: StopReason.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Stop clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Stop copyWith(void Function(Stop) updates) =>
      super.copyWith((message) => updates(message as Stop)) as Stop;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Stop() / Stop.new instead')
  static Stop create() => Stop._();
  static $pb.GeneratedMessage $_createMessage() => Stop._();
  @$core.override
  Stop createEmptyInstance() => Stop._();
  @$core.pragma('dart2js:noInline')
  static Stop getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Stop>(Stop.$_createMessage);
  static Stop? _defaultInstance;

  @$pb.TagNumber(1)
  StopReason get reason => $_getN(0);
  @$pb.TagNumber(1)
  set reason(StopReason value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReason() => $_has(0);
  @$pb.TagNumber(1)
  void clearReason() => $_clearField(1);
}

/// Something about the source's screen changed while it is shared.
class SourceState extends $pb.GeneratedMessage {
  factory SourceState({
    $core.bool? screenOff,
  }) {
    final result = SourceState._();
    if (screenOff != null) result.screenOff = screenOff;
    return result;
  }

  SourceState._();

  factory SourceState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SourceState()..mergeFromBuffer(data, registry);
  factory SourceState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SourceState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SourceState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: SourceState.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'screenOff')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SourceState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SourceState copyWith(void Function(SourceState) updates) =>
      super.copyWith((message) => updates(message as SourceState))
          as SourceState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SourceState() / SourceState.new instead')
  static SourceState create() => SourceState._();
  static $pb.GeneratedMessage $_createMessage() => SourceState._();
  @$core.override
  SourceState createEmptyInstance() => SourceState._();
  @$core.pragma('dart2js:noInline')
  static SourceState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SourceState>(
          SourceState.$_createMessage);
  static SourceState? _defaultInstance;

  /// The screen is off: no new frames until it is on again.
  @$pb.TagNumber(1)
  $core.bool get screenOff => $_getBF(0);
  @$pb.TagNumber(1)
  set screenOff($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasScreenOff() => $_has(0);
  @$pb.TagNumber(1)
  void clearScreenOff() => $_clearField(1);
}

/// How the stream is doing. The viewer sends one about every second; the
/// source answers each with its own, and uses them to pick the bitrate.
class Stats extends $pb.GeneratedMessage {
  factory Stats({
    $fixnum.Int64? sentAtMs,
    $fixnum.Int64? echoSentAtMs,
    $core.int? fps,
    $core.int? droppedFrames,
    $core.int? bitrateKbps,
  }) {
    final result = Stats._();
    if (sentAtMs != null) result.sentAtMs = sentAtMs;
    if (echoSentAtMs != null) result.echoSentAtMs = echoSentAtMs;
    if (fps != null) result.fps = fps;
    if (droppedFrames != null) result.droppedFrames = droppedFrames;
    if (bitrateKbps != null) result.bitrateKbps = bitrateKbps;
    return result;
  }

  Stats._();

  factory Stats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Stats()..mergeFromBuffer(data, registry);
  factory Stats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Stats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Stats',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.mirroring.v1'),
      createEmptyInstance: Stats.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'sentAtMs')
    ..aInt64(2, _omitFieldNames ? '' : 'echoSentAtMs')
    ..aI(3, _omitFieldNames ? '' : 'fps', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'droppedFrames',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'bitrateKbps',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Stats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Stats copyWith(void Function(Stats) updates) =>
      super.copyWith((message) => updates(message as Stats)) as Stats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Stats() / Stats.new instead')
  static Stats create() => Stats._();
  static $pb.GeneratedMessage $_createMessage() => Stats._();
  @$core.override
  Stats createEmptyInstance() => Stats._();
  @$core.pragma('dart2js:noInline')
  static Stats getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Stats>(Stats.$_createMessage);
  static Stats? _defaultInstance;

  /// When this was sent, in milliseconds on the sender's own clock.
  @$pb.TagNumber(1)
  $fixnum.Int64 get sentAtMs => $_getI64(0);
  @$pb.TagNumber(1)
  set sentAtMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSentAtMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearSentAtMs() => $_clearField(1);

  /// Source only: `sent_at_ms` of the viewer's `Stats` this answers, so the
  /// viewer can measure the round trip.
  @$pb.TagNumber(2)
  $fixnum.Int64 get echoSentAtMs => $_getI64(1);
  @$pb.TagNumber(2)
  set echoSentAtMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEchoSentAtMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearEchoSentAtMs() => $_clearField(2);

  /// Viewer: frames shown in the last second. Source: frames sent.
  @$pb.TagNumber(3)
  $core.int get fps => $_getIZ(2);
  @$pb.TagNumber(3)
  set fps($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFps() => $_has(2);
  @$pb.TagNumber(3)
  void clearFps() => $_clearField(3);

  /// Frames dropped in the last second: by the source because the
  /// connection backed up, or by the viewer because decoding fell behind.
  @$pb.TagNumber(4)
  $core.int get droppedFrames => $_getIZ(3);
  @$pb.TagNumber(4)
  set droppedFrames($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDroppedFrames() => $_has(3);
  @$pb.TagNumber(4)
  void clearDroppedFrames() => $_clearField(4);

  /// Source only: what the encoder aims for right now, in kilobits per
  /// second. 0 for JPEG.
  @$pb.TagNumber(5)
  $core.int get bitrateKbps => $_getIZ(4);
  @$pb.TagNumber(5)
  set bitrateKbps($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBitrateKbps() => $_has(4);
  @$pb.TagNumber(5)
  void clearBitrateKbps() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
