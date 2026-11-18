// This is a generated file - do not edit.
//
// Generated from ferret/media/v1/media.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'media.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'media.pbenum.dart';

/// What a device is playing right now: every media player it can see. Sent
/// when something changes (feature "media"), never on a timer: the receiver
/// extrapolates the position of a playing item itself. An empty list means the
/// device stopped sharing or nothing plays.
class MediaState extends $pb.GeneratedMessage {
  factory MediaState({
    $core.Iterable<MediaPlayer>? players,
    $fixnum.Int64? sentAtMs,
  }) {
    final result = MediaState._();
    if (players != null) result.players.addAll(players);
    if (sentAtMs != null) result.sentAtMs = sentAtMs;
    return result;
  }

  MediaState._();

  factory MediaState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaState()..mergeFromBuffer(data, registry);
  factory MediaState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MediaState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.media.v1'),
      createEmptyInstance: MediaState.$_createMessage)
    ..pPM<MediaPlayer>(1, _omitFieldNames ? '' : 'players',
        subBuilder: MediaPlayer.$_createMessage)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'sentAtMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaState copyWith(void Function(MediaState) updates) =>
      super.copyWith((message) => updates(message as MediaState)) as MediaState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MediaState() / MediaState.new instead')
  static MediaState create() => MediaState._();
  static $pb.GeneratedMessage $_createMessage() => MediaState._();
  @$core.override
  MediaState createEmptyInstance() => MediaState._();
  @$core.pragma('dart2js:noInline')
  static MediaState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MediaState>(MediaState.$_createMessage);
  static MediaState? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<MediaPlayer> get players => $_getList(0);

  /// The sender's clock when it sent this, so the receiver can map the
  /// players' timestamps onto its own clock.
  @$pb.TagNumber(2)
  $fixnum.Int64 get sentAtMs => $_getI64(1);
  @$pb.TagNumber(2)
  set sentAtMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSentAtMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearSentAtMs() => $_clearField(2);
}

/// Asks a device for its current MediaState (feature "media"). The reply is a
/// MediaState.
class MediaStateRequest extends $pb.GeneratedMessage {
  factory MediaStateRequest() => MediaStateRequest._();

  MediaStateRequest._();

  factory MediaStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaStateRequest()..mergeFromBuffer(data, registry);
  factory MediaStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaStateRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MediaStateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.media.v1'),
      createEmptyInstance: MediaStateRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaStateRequest copyWith(void Function(MediaStateRequest) updates) =>
      super.copyWith((message) => updates(message as MediaStateRequest))
          as MediaStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MediaStateRequest() / MediaStateRequest.new instead')
  static MediaStateRequest create() => MediaStateRequest._();
  static $pb.GeneratedMessage $_createMessage() => MediaStateRequest._();
  @$core.override
  MediaStateRequest createEmptyInstance() => MediaStateRequest._();
  @$core.pragma('dart2js:noInline')
  static MediaStateRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MediaStateRequest>(
          MediaStateRequest.$_createMessage);
  static MediaStateRequest? _defaultInstance;
}

/// One media player, such as Spotify or a browser tab, and what it plays.
class MediaPlayer extends $pb.GeneratedMessage {
  factory MediaPlayer({
    $core.String? playerId,
    $core.String? appId,
    $core.String? appName,
    $core.String? title,
    $core.String? artist,
    $core.String? album,
    $core.String? artworkId,
    $core.List<$core.int>? artwork,
    $fixnum.Int64? durationMs,
    $fixnum.Int64? positionMs,
    $fixnum.Int64? positionAtMs,
    MediaPlaybackStatus? status,
    $core.double? playbackRate,
    $core.String? contentUri,
    $fixnum.Int64? lastActiveAtMs,
    $core.Iterable<MediaAction>? actions,
    $core.double? volume,
  }) {
    final result = MediaPlayer._();
    if (playerId != null) result.playerId = playerId;
    if (appId != null) result.appId = appId;
    if (appName != null) result.appName = appName;
    if (title != null) result.title = title;
    if (artist != null) result.artist = artist;
    if (album != null) result.album = album;
    if (artworkId != null) result.artworkId = artworkId;
    if (artwork != null) result.artwork = artwork;
    if (durationMs != null) result.durationMs = durationMs;
    if (positionMs != null) result.positionMs = positionMs;
    if (positionAtMs != null) result.positionAtMs = positionAtMs;
    if (status != null) result.status = status;
    if (playbackRate != null) result.playbackRate = playbackRate;
    if (contentUri != null) result.contentUri = contentUri;
    if (lastActiveAtMs != null) result.lastActiveAtMs = lastActiveAtMs;
    if (actions != null) result.actions.addAll(actions);
    if (volume != null) result.volume = volume;
    return result;
  }

  MediaPlayer._();

  factory MediaPlayer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaPlayer()..mergeFromBuffer(data, registry);
  factory MediaPlayer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaPlayer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MediaPlayer',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.media.v1'),
      createEmptyInstance: MediaPlayer.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..aOS(2, _omitFieldNames ? '' : 'appId')
    ..aOS(3, _omitFieldNames ? '' : 'appName')
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..aOS(5, _omitFieldNames ? '' : 'artist')
    ..aOS(6, _omitFieldNames ? '' : 'album')
    ..aOS(7, _omitFieldNames ? '' : 'artworkId')
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'artwork', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        9, _omitFieldNames ? '' : 'durationMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        10, _omitFieldNames ? '' : 'positionMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'positionAtMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<MediaPlaybackStatus>(12, _omitFieldNames ? '' : 'status',
        enumValues: MediaPlaybackStatus.values)
    ..aD(13, _omitFieldNames ? '' : 'playbackRate',
        fieldType: $pb.PbFieldType.OF)
    ..aOS(14, _omitFieldNames ? '' : 'contentUri')
    ..a<$fixnum.Int64>(
        15, _omitFieldNames ? '' : 'lastActiveAtMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pc<MediaAction>(16, _omitFieldNames ? '' : 'actions', $pb.PbFieldType.KE,
        valueOf: MediaAction.valueOf,
        enumValues: MediaAction.values,
        defaultEnumValue: MediaAction.MEDIA_ACTION_UNSPECIFIED)
    ..aD(17, _omitFieldNames ? '' : 'volume', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaPlayer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaPlayer copyWith(void Function(MediaPlayer) updates) =>
      super.copyWith((message) => updates(message as MediaPlayer))
          as MediaPlayer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MediaPlayer() / MediaPlayer.new instead')
  static MediaPlayer create() => MediaPlayer._();
  static $pb.GeneratedMessage $_createMessage() => MediaPlayer._();
  @$core.override
  MediaPlayer createEmptyInstance() => MediaPlayer._();
  @$core.pragma('dart2js:noInline')
  static MediaPlayer getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MediaPlayer>(
          MediaPlayer.$_createMessage);
  static MediaPlayer? _defaultInstance;

  /// Stable while the player exists on the sender.
  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => $_clearField(1);

  /// The app behind the player, such as "com.spotify.music" on Android or
  /// "com.spotify.client" on macOS.
  @$pb.TagNumber(2)
  $core.String get appId => $_getSZ(1);
  @$pb.TagNumber(2)
  set appId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAppId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAppId() => $_clearField(2);

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
  $core.String get artist => $_getSZ(4);
  @$pb.TagNumber(5)
  set artist($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasArtist() => $_has(4);
  @$pb.TagNumber(5)
  void clearArtist() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get album => $_getSZ(5);
  @$pb.TagNumber(6)
  set album($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAlbum() => $_has(5);
  @$pb.TagNumber(6)
  void clearAlbum() => $_clearField(6);

  /// Identifies the artwork, so the image is sent only once per session.
  @$pb.TagNumber(7)
  $core.String get artworkId => $_getSZ(6);
  @$pb.TagNumber(7)
  set artworkId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasArtworkId() => $_has(6);
  @$pb.TagNumber(7)
  void clearArtworkId() => $_clearField(7);

  /// A small JPEG or PNG (at most 64 KiB). Empty when the receiver already got
  /// the image for artwork_id in this session.
  @$pb.TagNumber(8)
  $core.List<$core.int> get artwork => $_getN(7);
  @$pb.TagNumber(8)
  set artwork($core.List<$core.int> value) => $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasArtwork() => $_has(7);
  @$pb.TagNumber(8)
  void clearArtwork() => $_clearField(8);

  /// 0 when unknown, such as a live stream.
  @$pb.TagNumber(9)
  $fixnum.Int64 get durationMs => $_getI64(8);
  @$pb.TagNumber(9)
  set durationMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasDurationMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearDurationMs() => $_clearField(9);

  /// The position at position_at_ms.
  @$pb.TagNumber(10)
  $fixnum.Int64 get positionMs => $_getI64(9);
  @$pb.TagNumber(10)
  set positionMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPositionMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearPositionMs() => $_clearField(10);

  /// The sender's clock when position_ms was true.
  @$pb.TagNumber(11)
  $fixnum.Int64 get positionAtMs => $_getI64(10);
  @$pb.TagNumber(11)
  set positionAtMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasPositionAtMs() => $_has(10);
  @$pb.TagNumber(11)
  void clearPositionAtMs() => $_clearField(11);

  @$pb.TagNumber(12)
  MediaPlaybackStatus get status => $_getN(11);
  @$pb.TagNumber(12)
  set status(MediaPlaybackStatus value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasStatus() => $_has(11);
  @$pb.TagNumber(12)
  void clearStatus() => $_clearField(12);

  /// Playback speed while playing; 0 means 1.
  @$pb.TagNumber(13)
  $core.double get playbackRate => $_getN(12);
  @$pb.TagNumber(13)
  set playbackRate($core.double value) => $_setFloat(12, value);
  @$pb.TagNumber(13)
  $core.bool hasPlaybackRate() => $_has(12);
  @$pb.TagNumber(13)
  void clearPlaybackRate() => $_clearField(13);

  /// A link to the item, such as a YouTube URL or a spotify: URI, when the
  /// player tells it.
  @$pb.TagNumber(14)
  $core.String get contentUri => $_getSZ(13);
  @$pb.TagNumber(14)
  set contentUri($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasContentUri() => $_has(13);
  @$pb.TagNumber(14)
  void clearContentUri() => $_clearField(14);

  /// The sender's clock when this player last started playing or changed item,
  /// to follow the last active player.
  @$pb.TagNumber(15)
  $fixnum.Int64 get lastActiveAtMs => $_getI64(14);
  @$pb.TagNumber(15)
  set lastActiveAtMs($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasLastActiveAtMs() => $_has(14);
  @$pb.TagNumber(15)
  void clearLastActiveAtMs() => $_clearField(15);

  @$pb.TagNumber(16)
  $pb.PbList<MediaAction> get actions => $_getList(15);

  /// Player volume 0 to 1, or -1 when unknown.
  @$pb.TagNumber(17)
  $core.double get volume => $_getN(16);
  @$pb.TagNumber(17)
  set volume($core.double value) => $_setFloat(16, value);
  @$pb.TagNumber(17)
  $core.bool hasVolume() => $_has(16);
  @$pb.TagNumber(17)
  void clearVolume() => $_clearField(17);
}

/// Asks a device to control one of its players (feature "media"). The reply
/// is a MediaCommandReply.
class MediaCommand extends $pb.GeneratedMessage {
  factory MediaCommand({
    $core.String? playerId,
    MediaAction? action,
    $fixnum.Int64? positionMs,
    $core.double? volume,
  }) {
    final result = MediaCommand._();
    if (playerId != null) result.playerId = playerId;
    if (action != null) result.action = action;
    if (positionMs != null) result.positionMs = positionMs;
    if (volume != null) result.volume = volume;
    return result;
  }

  MediaCommand._();

  factory MediaCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaCommand()..mergeFromBuffer(data, registry);
  factory MediaCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaCommand()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MediaCommand',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.media.v1'),
      createEmptyInstance: MediaCommand.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..aE<MediaAction>(2, _omitFieldNames ? '' : 'action',
        enumValues: MediaAction.values)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'positionMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(4, _omitFieldNames ? '' : 'volume', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaCommand copyWith(void Function(MediaCommand) updates) =>
      super.copyWith((message) => updates(message as MediaCommand))
          as MediaCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MediaCommand() / MediaCommand.new instead')
  static MediaCommand create() => MediaCommand._();
  static $pb.GeneratedMessage $_createMessage() => MediaCommand._();
  @$core.override
  MediaCommand createEmptyInstance() => MediaCommand._();
  @$core.pragma('dart2js:noInline')
  static MediaCommand getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MediaCommand>(
          MediaCommand.$_createMessage);
  static MediaCommand? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => $_clearField(1);

  @$pb.TagNumber(2)
  MediaAction get action => $_getN(1);
  @$pb.TagNumber(2)
  set action(MediaAction value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAction() => $_has(1);
  @$pb.TagNumber(2)
  void clearAction() => $_clearField(2);

  /// For MEDIA_ACTION_SEEK.
  @$pb.TagNumber(3)
  $fixnum.Int64 get positionMs => $_getI64(2);
  @$pb.TagNumber(3)
  set positionMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPositionMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearPositionMs() => $_clearField(3);

  /// For MEDIA_ACTION_SET_VOLUME, 0 to 1.
  @$pb.TagNumber(4)
  $core.double get volume => $_getN(3);
  @$pb.TagNumber(4)
  set volume($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVolume() => $_has(3);
  @$pb.TagNumber(4)
  void clearVolume() => $_clearField(4);
}

class MediaCommandReply extends $pb.GeneratedMessage {
  factory MediaCommandReply({
    MediaCommandResult? result,
  }) {
    final result$ = MediaCommandReply._();
    if (result != null) result$.result = result;
    return result$;
  }

  MediaCommandReply._();

  factory MediaCommandReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaCommandReply()..mergeFromBuffer(data, registry);
  factory MediaCommandReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaCommandReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MediaCommandReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.media.v1'),
      createEmptyInstance: MediaCommandReply.$_createMessage)
    ..aE<MediaCommandResult>(1, _omitFieldNames ? '' : 'result',
        enumValues: MediaCommandResult.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaCommandReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaCommandReply copyWith(void Function(MediaCommandReply) updates) =>
      super.copyWith((message) => updates(message as MediaCommandReply))
          as MediaCommandReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MediaCommandReply() / MediaCommandReply.new instead')
  static MediaCommandReply create() => MediaCommandReply._();
  static $pb.GeneratedMessage $_createMessage() => MediaCommandReply._();
  @$core.override
  MediaCommandReply createEmptyInstance() => MediaCommandReply._();
  @$core.pragma('dart2js:noInline')
  static MediaCommandReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MediaCommandReply>(
          MediaCommandReply.$_createMessage);
  static MediaCommandReply? _defaultInstance;

  @$pb.TagNumber(1)
  MediaCommandResult get result => $_getN(0);
  @$pb.TagNumber(1)
  set result(MediaCommandResult value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => $_clearField(1);
}

/// Asks a device to hand one of its players over (feature "media"): it pauses
/// the player when pause_source is set and replies with a MediaContinueReply
/// holding the item and the position it stopped at.
class MediaContinueRequest extends $pb.GeneratedMessage {
  factory MediaContinueRequest({
    $core.String? playerId,
    $core.bool? pauseSource,
  }) {
    final result = MediaContinueRequest._();
    if (playerId != null) result.playerId = playerId;
    if (pauseSource != null) result.pauseSource = pauseSource;
    return result;
  }

  MediaContinueRequest._();

  factory MediaContinueRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaContinueRequest()..mergeFromBuffer(data, registry);
  factory MediaContinueRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaContinueRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MediaContinueRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.media.v1'),
      createEmptyInstance: MediaContinueRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..aOB(2, _omitFieldNames ? '' : 'pauseSource')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaContinueRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaContinueRequest copyWith(void Function(MediaContinueRequest) updates) =>
      super.copyWith((message) => updates(message as MediaContinueRequest))
          as MediaContinueRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use MediaContinueRequest() / MediaContinueRequest.new instead')
  static MediaContinueRequest create() => MediaContinueRequest._();
  static $pb.GeneratedMessage $_createMessage() => MediaContinueRequest._();
  @$core.override
  MediaContinueRequest createEmptyInstance() => MediaContinueRequest._();
  @$core.pragma('dart2js:noInline')
  static MediaContinueRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MediaContinueRequest>(
          MediaContinueRequest.$_createMessage);
  static MediaContinueRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get pauseSource => $_getBF(1);
  @$pb.TagNumber(2)
  set pauseSource($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPauseSource() => $_has(1);
  @$pb.TagNumber(2)
  void clearPauseSource() => $_clearField(2);
}

class MediaContinueReply extends $pb.GeneratedMessage {
  factory MediaContinueReply({
    MediaCommandResult? result,
    MediaPlayer? player,
    $core.bool? paused,
  }) {
    final result$ = MediaContinueReply._();
    if (result != null) result$.result = result;
    if (player != null) result$.player = player;
    if (paused != null) result$.paused = paused;
    return result$;
  }

  MediaContinueReply._();

  factory MediaContinueReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaContinueReply()..mergeFromBuffer(data, registry);
  factory MediaContinueReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaContinueReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MediaContinueReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.media.v1'),
      createEmptyInstance: MediaContinueReply.$_createMessage)
    ..aE<MediaCommandResult>(1, _omitFieldNames ? '' : 'result',
        enumValues: MediaCommandResult.values)
    ..aOM<MediaPlayer>(2, _omitFieldNames ? '' : 'player',
        subBuilder: MediaPlayer.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'paused')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaContinueReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaContinueReply copyWith(void Function(MediaContinueReply) updates) =>
      super.copyWith((message) => updates(message as MediaContinueReply))
          as MediaContinueReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MediaContinueReply() / MediaContinueReply.new instead')
  static MediaContinueReply create() => MediaContinueReply._();
  static $pb.GeneratedMessage $_createMessage() => MediaContinueReply._();
  @$core.override
  MediaContinueReply createEmptyInstance() => MediaContinueReply._();
  @$core.pragma('dart2js:noInline')
  static MediaContinueReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MediaContinueReply>(
          MediaContinueReply.$_createMessage);
  static MediaContinueReply? _defaultInstance;

  @$pb.TagNumber(1)
  MediaCommandResult get result => $_getN(0);
  @$pb.TagNumber(1)
  set result(MediaCommandResult value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => $_clearField(1);

  /// The player as it was when it paused, with a fresh position.
  @$pb.TagNumber(2)
  MediaPlayer get player => $_getN(1);
  @$pb.TagNumber(2)
  set player(MediaPlayer value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPlayer() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlayer() => $_clearField(2);
  @$pb.TagNumber(2)
  MediaPlayer ensurePlayer() => $_ensure(1);

  /// Whether the source paused, so the receiver can resume it if opening the
  /// item here fails.
  @$pb.TagNumber(3)
  $core.bool get paused => $_getBF(2);
  @$pb.TagNumber(3)
  set paused($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPaused() => $_has(2);
  @$pb.TagNumber(3)
  void clearPaused() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
