// This is a generated file - do not edit.
//
// Generated from ferret/scripting/v1/scripting.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'scripting.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'scripting.pbenum.dart';

/// A short notice a script on the sending computer wants shown on the
/// receiving device, from `ferret-cli notify`. Expects a `ScriptNoticeReply`.
/// The receiver shows it only when its owner allowed scripts from the
/// sending device (off by default), and drops floods.
class ScriptNotice extends $pb.GeneratedMessage {
  factory ScriptNotice({
    $core.String? title,
    $core.String? body,
  }) {
    final result = ScriptNotice._();
    if (title != null) result.title = title;
    if (body != null) result.body = body;
    return result;
  }

  ScriptNotice._();

  factory ScriptNotice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ScriptNotice()..mergeFromBuffer(data, registry);
  factory ScriptNotice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ScriptNotice()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScriptNotice',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.scripting.v1'),
      createEmptyInstance: ScriptNotice.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'body')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScriptNotice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScriptNotice copyWith(void Function(ScriptNotice) updates) =>
      super.copyWith((message) => updates(message as ScriptNotice))
          as ScriptNotice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ScriptNotice() / ScriptNotice.new instead')
  static ScriptNotice create() => ScriptNotice._();
  static $pb.GeneratedMessage $_createMessage() => ScriptNotice._();
  @$core.override
  ScriptNotice createEmptyInstance() => ScriptNotice._();
  @$core.pragma('dart2js:noInline')
  static ScriptNotice getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ScriptNotice>(
          ScriptNotice.$_createMessage);
  static ScriptNotice? _defaultInstance;

  /// At most 120 characters; longer is cut.
  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  /// At most 500 characters; longer is cut.
  @$pb.TagNumber(2)
  $core.String get body => $_getSZ(1);
  @$pb.TagNumber(2)
  set body($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearBody() => $_clearField(2);
}

/// What came of a `ScriptNotice`.
class ScriptNoticeReply extends $pb.GeneratedMessage {
  factory ScriptNoticeReply({
    ScriptNoticeResult? result,
  }) {
    final result$ = ScriptNoticeReply._();
    if (result != null) result$.result = result;
    return result$;
  }

  ScriptNoticeReply._();

  factory ScriptNoticeReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ScriptNoticeReply()..mergeFromBuffer(data, registry);
  factory ScriptNoticeReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ScriptNoticeReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScriptNoticeReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.scripting.v1'),
      createEmptyInstance: ScriptNoticeReply.$_createMessage)
    ..aE<ScriptNoticeResult>(1, _omitFieldNames ? '' : 'result',
        enumValues: ScriptNoticeResult.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScriptNoticeReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScriptNoticeReply copyWith(void Function(ScriptNoticeReply) updates) =>
      super.copyWith((message) => updates(message as ScriptNoticeReply))
          as ScriptNoticeReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ScriptNoticeReply() / ScriptNoticeReply.new instead')
  static ScriptNoticeReply create() => ScriptNoticeReply._();
  static $pb.GeneratedMessage $_createMessage() => ScriptNoticeReply._();
  @$core.override
  ScriptNoticeReply createEmptyInstance() => ScriptNoticeReply._();
  @$core.pragma('dart2js:noInline')
  static ScriptNoticeReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ScriptNoticeReply>(
          ScriptNoticeReply.$_createMessage);
  static ScriptNoticeReply? _defaultInstance;

  @$pb.TagNumber(1)
  ScriptNoticeResult get result => $_getN(0);
  @$pb.TagNumber(1)
  set result(ScriptNoticeResult value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
