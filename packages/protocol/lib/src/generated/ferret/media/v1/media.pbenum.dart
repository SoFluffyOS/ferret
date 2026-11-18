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

import 'package:protobuf/protobuf.dart' as $pb;

class MediaPlaybackStatus extends $pb.ProtobufEnum {
  static const MediaPlaybackStatus MEDIA_PLAYBACK_STATUS_UNSPECIFIED =
      MediaPlaybackStatus._(
          0, _omitEnumNames ? '' : 'MEDIA_PLAYBACK_STATUS_UNSPECIFIED');
  static const MediaPlaybackStatus MEDIA_PLAYBACK_STATUS_STOPPED =
      MediaPlaybackStatus._(
          1, _omitEnumNames ? '' : 'MEDIA_PLAYBACK_STATUS_STOPPED');
  static const MediaPlaybackStatus MEDIA_PLAYBACK_STATUS_PAUSED =
      MediaPlaybackStatus._(
          2, _omitEnumNames ? '' : 'MEDIA_PLAYBACK_STATUS_PAUSED');
  static const MediaPlaybackStatus MEDIA_PLAYBACK_STATUS_PLAYING =
      MediaPlaybackStatus._(
          3, _omitEnumNames ? '' : 'MEDIA_PLAYBACK_STATUS_PLAYING');
  static const MediaPlaybackStatus MEDIA_PLAYBACK_STATUS_BUFFERING =
      MediaPlaybackStatus._(
          4, _omitEnumNames ? '' : 'MEDIA_PLAYBACK_STATUS_BUFFERING');

  static const $core.List<MediaPlaybackStatus> values = <MediaPlaybackStatus>[
    MEDIA_PLAYBACK_STATUS_UNSPECIFIED,
    MEDIA_PLAYBACK_STATUS_STOPPED,
    MEDIA_PLAYBACK_STATUS_PAUSED,
    MEDIA_PLAYBACK_STATUS_PLAYING,
    MEDIA_PLAYBACK_STATUS_BUFFERING,
  ];

  static final $core.List<MediaPlaybackStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static MediaPlaybackStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MediaPlaybackStatus._(super.value, super.name);
}

class MediaAction extends $pb.ProtobufEnum {
  static const MediaAction MEDIA_ACTION_UNSPECIFIED =
      MediaAction._(0, _omitEnumNames ? '' : 'MEDIA_ACTION_UNSPECIFIED');
  static const MediaAction MEDIA_ACTION_PLAY =
      MediaAction._(1, _omitEnumNames ? '' : 'MEDIA_ACTION_PLAY');
  static const MediaAction MEDIA_ACTION_PAUSE =
      MediaAction._(2, _omitEnumNames ? '' : 'MEDIA_ACTION_PAUSE');
  static const MediaAction MEDIA_ACTION_TOGGLE =
      MediaAction._(3, _omitEnumNames ? '' : 'MEDIA_ACTION_TOGGLE');
  static const MediaAction MEDIA_ACTION_NEXT =
      MediaAction._(4, _omitEnumNames ? '' : 'MEDIA_ACTION_NEXT');
  static const MediaAction MEDIA_ACTION_PREVIOUS =
      MediaAction._(5, _omitEnumNames ? '' : 'MEDIA_ACTION_PREVIOUS');
  static const MediaAction MEDIA_ACTION_SEEK =
      MediaAction._(6, _omitEnumNames ? '' : 'MEDIA_ACTION_SEEK');
  static const MediaAction MEDIA_ACTION_SET_VOLUME =
      MediaAction._(7, _omitEnumNames ? '' : 'MEDIA_ACTION_SET_VOLUME');

  static const $core.List<MediaAction> values = <MediaAction>[
    MEDIA_ACTION_UNSPECIFIED,
    MEDIA_ACTION_PLAY,
    MEDIA_ACTION_PAUSE,
    MEDIA_ACTION_TOGGLE,
    MEDIA_ACTION_NEXT,
    MEDIA_ACTION_PREVIOUS,
    MEDIA_ACTION_SEEK,
    MEDIA_ACTION_SET_VOLUME,
  ];

  static final $core.List<MediaAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static MediaAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MediaAction._(super.value, super.name);
}

class MediaCommandResult extends $pb.ProtobufEnum {
  static const MediaCommandResult MEDIA_COMMAND_RESULT_UNSPECIFIED =
      MediaCommandResult._(
          0, _omitEnumNames ? '' : 'MEDIA_COMMAND_RESULT_UNSPECIFIED');
  static const MediaCommandResult MEDIA_COMMAND_RESULT_OK =
      MediaCommandResult._(1, _omitEnumNames ? '' : 'MEDIA_COMMAND_RESULT_OK');

  /// No player with that id, such as one that just closed.
  static const MediaCommandResult MEDIA_COMMAND_RESULT_UNKNOWN_PLAYER =
      MediaCommandResult._(
          2, _omitEnumNames ? '' : 'MEDIA_COMMAND_RESULT_UNKNOWN_PLAYER');

  /// The user turned off sharing media on that device.
  static const MediaCommandResult MEDIA_COMMAND_RESULT_NOT_SHARED =
      MediaCommandResult._(
          3, _omitEnumNames ? '' : 'MEDIA_COMMAND_RESULT_NOT_SHARED');

  /// The player can't do that action.
  static const MediaCommandResult MEDIA_COMMAND_RESULT_UNSUPPORTED =
      MediaCommandResult._(
          4, _omitEnumNames ? '' : 'MEDIA_COMMAND_RESULT_UNSUPPORTED');
  static const MediaCommandResult MEDIA_COMMAND_RESULT_FAILED =
      MediaCommandResult._(
          5, _omitEnumNames ? '' : 'MEDIA_COMMAND_RESULT_FAILED');

  static const $core.List<MediaCommandResult> values = <MediaCommandResult>[
    MEDIA_COMMAND_RESULT_UNSPECIFIED,
    MEDIA_COMMAND_RESULT_OK,
    MEDIA_COMMAND_RESULT_UNKNOWN_PLAYER,
    MEDIA_COMMAND_RESULT_NOT_SHARED,
    MEDIA_COMMAND_RESULT_UNSUPPORTED,
    MEDIA_COMMAND_RESULT_FAILED,
  ];

  static final $core.List<MediaCommandResult?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static MediaCommandResult? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MediaCommandResult._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
