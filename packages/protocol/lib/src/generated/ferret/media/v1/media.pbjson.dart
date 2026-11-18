// This is a generated file - do not edit.
//
// Generated from ferret/media/v1/media.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use mediaPlaybackStatusDescriptor instead')
const MediaPlaybackStatus$json = {
  '1': 'MediaPlaybackStatus',
  '2': [
    {'1': 'MEDIA_PLAYBACK_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'MEDIA_PLAYBACK_STATUS_STOPPED', '2': 1},
    {'1': 'MEDIA_PLAYBACK_STATUS_PAUSED', '2': 2},
    {'1': 'MEDIA_PLAYBACK_STATUS_PLAYING', '2': 3},
    {'1': 'MEDIA_PLAYBACK_STATUS_BUFFERING', '2': 4},
  ],
};

/// Descriptor for `MediaPlaybackStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mediaPlaybackStatusDescriptor = $convert.base64Decode(
    'ChNNZWRpYVBsYXliYWNrU3RhdHVzEiUKIU1FRElBX1BMQVlCQUNLX1NUQVRVU19VTlNQRUNJRk'
    'lFRBAAEiEKHU1FRElBX1BMQVlCQUNLX1NUQVRVU19TVE9QUEVEEAESIAocTUVESUFfUExBWUJB'
    'Q0tfU1RBVFVTX1BBVVNFRBACEiEKHU1FRElBX1BMQVlCQUNLX1NUQVRVU19QTEFZSU5HEAMSIw'
    'ofTUVESUFfUExBWUJBQ0tfU1RBVFVTX0JVRkZFUklORxAE');

@$core.Deprecated('Use mediaActionDescriptor instead')
const MediaAction$json = {
  '1': 'MediaAction',
  '2': [
    {'1': 'MEDIA_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'MEDIA_ACTION_PLAY', '2': 1},
    {'1': 'MEDIA_ACTION_PAUSE', '2': 2},
    {'1': 'MEDIA_ACTION_TOGGLE', '2': 3},
    {'1': 'MEDIA_ACTION_NEXT', '2': 4},
    {'1': 'MEDIA_ACTION_PREVIOUS', '2': 5},
    {'1': 'MEDIA_ACTION_SEEK', '2': 6},
    {'1': 'MEDIA_ACTION_SET_VOLUME', '2': 7},
  ],
};

/// Descriptor for `MediaAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mediaActionDescriptor = $convert.base64Decode(
    'CgtNZWRpYUFjdGlvbhIcChhNRURJQV9BQ1RJT05fVU5TUEVDSUZJRUQQABIVChFNRURJQV9BQ1'
    'RJT05fUExBWRABEhYKEk1FRElBX0FDVElPTl9QQVVTRRACEhcKE01FRElBX0FDVElPTl9UT0dH'
    'TEUQAxIVChFNRURJQV9BQ1RJT05fTkVYVBAEEhkKFU1FRElBX0FDVElPTl9QUkVWSU9VUxAFEh'
    'UKEU1FRElBX0FDVElPTl9TRUVLEAYSGwoXTUVESUFfQUNUSU9OX1NFVF9WT0xVTUUQBw==');

@$core.Deprecated('Use mediaCommandResultDescriptor instead')
const MediaCommandResult$json = {
  '1': 'MediaCommandResult',
  '2': [
    {'1': 'MEDIA_COMMAND_RESULT_UNSPECIFIED', '2': 0},
    {'1': 'MEDIA_COMMAND_RESULT_OK', '2': 1},
    {'1': 'MEDIA_COMMAND_RESULT_UNKNOWN_PLAYER', '2': 2},
    {'1': 'MEDIA_COMMAND_RESULT_NOT_SHARED', '2': 3},
    {'1': 'MEDIA_COMMAND_RESULT_UNSUPPORTED', '2': 4},
    {'1': 'MEDIA_COMMAND_RESULT_FAILED', '2': 5},
  ],
};

/// Descriptor for `MediaCommandResult`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mediaCommandResultDescriptor = $convert.base64Decode(
    'ChJNZWRpYUNvbW1hbmRSZXN1bHQSJAogTUVESUFfQ09NTUFORF9SRVNVTFRfVU5TUEVDSUZJRU'
    'QQABIbChdNRURJQV9DT01NQU5EX1JFU1VMVF9PSxABEicKI01FRElBX0NPTU1BTkRfUkVTVUxU'
    'X1VOS05PV05fUExBWUVSEAISIwofTUVESUFfQ09NTUFORF9SRVNVTFRfTk9UX1NIQVJFRBADEi'
    'QKIE1FRElBX0NPTU1BTkRfUkVTVUxUX1VOU1VQUE9SVEVEEAQSHwobTUVESUFfQ09NTUFORF9S'
    'RVNVTFRfRkFJTEVEEAU=');

@$core.Deprecated('Use mediaStateDescriptor instead')
const MediaState$json = {
  '1': 'MediaState',
  '2': [
    {
      '1': 'players',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ferret.media.v1.MediaPlayer',
      '10': 'players'
    },
    {'1': 'sent_at_ms', '3': 2, '4': 1, '5': 4, '10': 'sentAtMs'},
  ],
};

/// Descriptor for `MediaState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaStateDescriptor = $convert.base64Decode(
    'CgpNZWRpYVN0YXRlEjYKB3BsYXllcnMYASADKAsyHC5mZXJyZXQubWVkaWEudjEuTWVkaWFQbG'
    'F5ZXJSB3BsYXllcnMSHAoKc2VudF9hdF9tcxgCIAEoBFIIc2VudEF0TXM=');

@$core.Deprecated('Use mediaStateRequestDescriptor instead')
const MediaStateRequest$json = {
  '1': 'MediaStateRequest',
};

/// Descriptor for `MediaStateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaStateRequestDescriptor =
    $convert.base64Decode('ChFNZWRpYVN0YXRlUmVxdWVzdA==');

@$core.Deprecated('Use mediaPlayerDescriptor instead')
const MediaPlayer$json = {
  '1': 'MediaPlayer',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'app_id', '3': 2, '4': 1, '5': 9, '10': 'appId'},
    {'1': 'app_name', '3': 3, '4': 1, '5': 9, '10': 'appName'},
    {'1': 'title', '3': 4, '4': 1, '5': 9, '10': 'title'},
    {'1': 'artist', '3': 5, '4': 1, '5': 9, '10': 'artist'},
    {'1': 'album', '3': 6, '4': 1, '5': 9, '10': 'album'},
    {'1': 'artwork_id', '3': 7, '4': 1, '5': 9, '10': 'artworkId'},
    {'1': 'artwork', '3': 8, '4': 1, '5': 12, '10': 'artwork'},
    {'1': 'duration_ms', '3': 9, '4': 1, '5': 4, '10': 'durationMs'},
    {'1': 'position_ms', '3': 10, '4': 1, '5': 4, '10': 'positionMs'},
    {'1': 'position_at_ms', '3': 11, '4': 1, '5': 4, '10': 'positionAtMs'},
    {
      '1': 'status',
      '3': 12,
      '4': 1,
      '5': 14,
      '6': '.ferret.media.v1.MediaPlaybackStatus',
      '10': 'status'
    },
    {'1': 'playback_rate', '3': 13, '4': 1, '5': 2, '10': 'playbackRate'},
    {'1': 'content_uri', '3': 14, '4': 1, '5': 9, '10': 'contentUri'},
    {'1': 'last_active_at_ms', '3': 15, '4': 1, '5': 4, '10': 'lastActiveAtMs'},
    {
      '1': 'actions',
      '3': 16,
      '4': 3,
      '5': 14,
      '6': '.ferret.media.v1.MediaAction',
      '10': 'actions'
    },
    {'1': 'volume', '3': 17, '4': 1, '5': 2, '10': 'volume'},
  ],
};

/// Descriptor for `MediaPlayer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaPlayerDescriptor = $convert.base64Decode(
    'CgtNZWRpYVBsYXllchIbCglwbGF5ZXJfaWQYASABKAlSCHBsYXllcklkEhUKBmFwcF9pZBgCIA'
    'EoCVIFYXBwSWQSGQoIYXBwX25hbWUYAyABKAlSB2FwcE5hbWUSFAoFdGl0bGUYBCABKAlSBXRp'
    'dGxlEhYKBmFydGlzdBgFIAEoCVIGYXJ0aXN0EhQKBWFsYnVtGAYgASgJUgVhbGJ1bRIdCgphcn'
    'R3b3JrX2lkGAcgASgJUglhcnR3b3JrSWQSGAoHYXJ0d29yaxgIIAEoDFIHYXJ0d29yaxIfCgtk'
    'dXJhdGlvbl9tcxgJIAEoBFIKZHVyYXRpb25NcxIfCgtwb3NpdGlvbl9tcxgKIAEoBFIKcG9zaX'
    'Rpb25NcxIkCg5wb3NpdGlvbl9hdF9tcxgLIAEoBFIMcG9zaXRpb25BdE1zEjwKBnN0YXR1cxgM'
    'IAEoDjIkLmZlcnJldC5tZWRpYS52MS5NZWRpYVBsYXliYWNrU3RhdHVzUgZzdGF0dXMSIwoNcG'
    'xheWJhY2tfcmF0ZRgNIAEoAlIMcGxheWJhY2tSYXRlEh8KC2NvbnRlbnRfdXJpGA4gASgJUgpj'
    'b250ZW50VXJpEikKEWxhc3RfYWN0aXZlX2F0X21zGA8gASgEUg5sYXN0QWN0aXZlQXRNcxI2Cg'
    'dhY3Rpb25zGBAgAygOMhwuZmVycmV0Lm1lZGlhLnYxLk1lZGlhQWN0aW9uUgdhY3Rpb25zEhYK'
    'BnZvbHVtZRgRIAEoAlIGdm9sdW1l');

@$core.Deprecated('Use mediaCommandDescriptor instead')
const MediaCommand$json = {
  '1': 'MediaCommand',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {
      '1': 'action',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.media.v1.MediaAction',
      '10': 'action'
    },
    {'1': 'position_ms', '3': 3, '4': 1, '5': 4, '10': 'positionMs'},
    {'1': 'volume', '3': 4, '4': 1, '5': 2, '10': 'volume'},
  ],
};

/// Descriptor for `MediaCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaCommandDescriptor = $convert.base64Decode(
    'CgxNZWRpYUNvbW1hbmQSGwoJcGxheWVyX2lkGAEgASgJUghwbGF5ZXJJZBI0CgZhY3Rpb24YAi'
    'ABKA4yHC5mZXJyZXQubWVkaWEudjEuTWVkaWFBY3Rpb25SBmFjdGlvbhIfCgtwb3NpdGlvbl9t'
    'cxgDIAEoBFIKcG9zaXRpb25NcxIWCgZ2b2x1bWUYBCABKAJSBnZvbHVtZQ==');

@$core.Deprecated('Use mediaCommandReplyDescriptor instead')
const MediaCommandReply$json = {
  '1': 'MediaCommandReply',
  '2': [
    {
      '1': 'result',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.media.v1.MediaCommandResult',
      '10': 'result'
    },
  ],
};

/// Descriptor for `MediaCommandReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaCommandReplyDescriptor = $convert.base64Decode(
    'ChFNZWRpYUNvbW1hbmRSZXBseRI7CgZyZXN1bHQYASABKA4yIy5mZXJyZXQubWVkaWEudjEuTW'
    'VkaWFDb21tYW5kUmVzdWx0UgZyZXN1bHQ=');

@$core.Deprecated('Use mediaContinueRequestDescriptor instead')
const MediaContinueRequest$json = {
  '1': 'MediaContinueRequest',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'pause_source', '3': 2, '4': 1, '5': 8, '10': 'pauseSource'},
  ],
};

/// Descriptor for `MediaContinueRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaContinueRequestDescriptor = $convert.base64Decode(
    'ChRNZWRpYUNvbnRpbnVlUmVxdWVzdBIbCglwbGF5ZXJfaWQYASABKAlSCHBsYXllcklkEiEKDH'
    'BhdXNlX3NvdXJjZRgCIAEoCFILcGF1c2VTb3VyY2U=');

@$core.Deprecated('Use mediaContinueReplyDescriptor instead')
const MediaContinueReply$json = {
  '1': 'MediaContinueReply',
  '2': [
    {
      '1': 'result',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.media.v1.MediaCommandResult',
      '10': 'result'
    },
    {
      '1': 'player',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ferret.media.v1.MediaPlayer',
      '10': 'player'
    },
    {'1': 'paused', '3': 3, '4': 1, '5': 8, '10': 'paused'},
  ],
};

/// Descriptor for `MediaContinueReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaContinueReplyDescriptor = $convert.base64Decode(
    'ChJNZWRpYUNvbnRpbnVlUmVwbHkSOwoGcmVzdWx0GAEgASgOMiMuZmVycmV0Lm1lZGlhLnYxLk'
    '1lZGlhQ29tbWFuZFJlc3VsdFIGcmVzdWx0EjQKBnBsYXllchgCIAEoCzIcLmZlcnJldC5tZWRp'
    'YS52MS5NZWRpYVBsYXllclIGcGxheWVyEhYKBnBhdXNlZBgDIAEoCFIGcGF1c2Vk');
